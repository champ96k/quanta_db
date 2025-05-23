import os
import json
import requests
import google.generativeai as genai
from google.api_core import exceptions

# Load environment variables
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
REPO = os.getenv("GITHUB_REPOSITORY")
PR_NUMBER = os.getenv("PR_NUMBER")

# Configure Gemini
genai.configure(api_key=GOOGLE_API_KEY)
gemini_model = genai.GenerativeModel(model_name="models/gemini-pro")

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

# Step 1: Fetch PR Changes
pr_files_url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}/files"
response = requests.get(pr_files_url, headers=HEADERS)

if response.status_code != 200:
    print("❌ Failed to fetch PR files:", response.text)
    exit(1)

pr_files = response.json()
if not pr_files:
    print("No code changes found to review.")
    exit(0)

# Step 2: Prepare prompt
code_reviews = []
for file in pr_files:
    if "patch" in file:
        filename = file["filename"]
        patch = file["patch"]
        code_reviews.append(f"File: {filename}\nChanges:\n{patch}")

code_review_text = "\n\n".join(code_reviews)

prompt = f"""
You are a **senior software engineer** reviewing a GitHub pull request.
Your goal is to **approve PRs unless critical changes are needed**.

### Review Guidelines:
- ✅ **Approve** if the code has **no major issues**. Simply respond with **"LGTM"**.
- 🔍 **Provide feedback** only if there are **clear bugs, security risks, or major performance problems**.
- ✨ **Minor improvements** (best practices, readability) should be **optional suggestions**, not blockers.
- ⏳ **Do NOT request changes for subjective or stylistic preferences**.
- 🔥 **Be concise** (max 2-3 sentences per issue) and use **code snippets** if needed.

If **no major issues**, respond with:
**"✅ LGTM! No major issues found. Good to go!"** 🚀

Now, review these changes:

{code_review_text}
"""

def review_with_openrouter(prompt):
    try:
        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "mistralai/mistral-7b-instruct",  # or gpt-3.5-turbo
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.7
        }
        response = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload)
        data = response.json()
        return data["choices"][0]["message"]["content"].strip()
    except Exception as e:
        return f"⚠️ OpenRouter Fallback Failed: {str(e)}"

# Step 3: Try Gemini, else fallback
try:
    gemini_response = gemini_model.generate_content(prompt)
    if hasattr(gemini_response, "text") and gemini_response.text.strip():
        review_comments = gemini_response.text.strip()
    else:
        review_comments = review_with_openrouter(prompt)
except exceptions.ResourceExhausted:
    review_comments = review_with_openrouter(prompt)
except Exception as e:
    review_comments = f"⚠️ Gemini Failed, fallback to OpenRouter:\n\n" + review_with_openrouter(prompt)

if review_comments.lower() in ["lgtm", "lgtm!", "looks good"]:
    review_comments = "✅ LGTM! No major issues found. Good to go! 🚀"

# Step 4: Post a comment on the PR
review_url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
review_payload = {"body": review_comments}

response = requests.post(review_url, headers=HEADERS, json=review_payload)

if response.status_code == 201:
    print("✅ Review posted successfully!")
else:
    print(f"❌ Failed to submit review: {response.text}")
    exit(1)

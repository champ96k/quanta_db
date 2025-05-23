import os
import json
import requests
import google.generativeai as genai
from google.api_core import exceptions

# Load environment variables
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
REPO = os.getenv("GITHUB_REPOSITORY")
PR_NUMBER = os.getenv("PR_NUMBER")

# Configure Gemini AI (v1)
genai.configure(api_key=GOOGLE_API_KEY)
model = genai.GenerativeModel(model_name="models/gemini-pro")  # ✅ Full model path and v1 compatible

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

# Step 1: Fetch PR changes
pr_files_url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}/files"
response = requests.get(pr_files_url, headers=HEADERS)

if response.status_code != 200:
    print("❌ Failed to fetch PR files:", response.text)
    exit(1)

pr_files = response.json()
if not pr_files:
    print("No code changes found to review.")
    exit(0)

# Step 2: Prepare code for AI review
code_reviews = []
for file in pr_files:
    if "patch" in file:  # Only process modified files
        filename = file["filename"]
        patch = file["patch"]
        code_reviews.append(f"File: {filename}\nChanges:\n{patch}")

code_review_text = "\n\n".join(code_reviews)

# Step 3: AI Review using Gemini
prompt = f"""
You are a **senior software engineer** reviewing a GitHub pull request.
Your goal is to **approve PRs unless critical changes are needed**.

### Review Guidelines:
- ✅ **Approve** if the code has **no major issues**. Simply respond with **"LGTM"**.
- 🔍 **Provide feedback** only if there are **clear bugs, security risks, or major performance problems**.
- ✨ **Minor improvements** (best practices, readability) should be **optional suggestions**, not blockers.
- ⏳ **Do NOT request changes for subjective or stylistic preferences**.
- 🔥 **Be concise** (max 2-3 sentences per issue) and use **code snippets** if needed.

### Example Format:
**File: `filename.dart`**
- **Issue:** Briefly explain the problem **only if necessary**.
- **Why?** Explain why it matters.
- **Suggested Fix:** Short fix.

If **no major issues**, respond with:
**"✅ LGTM! No major issues found. Good to go!"** 🚀

Now, review these changes:

{code_review_text}

Respond in **Markdown format**.
"""

try:
    response = model.generate_content(prompt)
    if response and hasattr(response, "text"):
        review_comments = response.text.strip()
        if review_comments.lower() in ["lgtm", "lgtm!", "looks good"]:
            review_comments = "✅ LGTM! No major issues found. Good to go! 🚀"
    else:
        review_comments = "⚠️ Unable to generate AI review at this time. Please proceed with manual review."
except exceptions.ResourceExhausted:
    review_comments = """⚠️ **AI Review Quota Exceeded**

The AI review could not be performed because the API quota has been exceeded. This is a temporary limitation of the free tier.

Please proceed with a manual review of the changes. The PR can still be merged if it passes manual review.

For more information about Gemini API quotas, visit: https://ai.google.dev/gemini-api/docs/rate-limits"""
except Exception as e:
    review_comments = f"""⚠️ **AI Review Failed**

The AI review could not be performed due to an unexpected error: {str(e)}

Please proceed with a manual review of the changes. The PR can still be merged if it passes manual review."""

# Step 4: Post a Comment
review_url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
review_payload = {"body": review_comments}

response = requests.post(review_url, headers=HEADERS, json=review_payload)

if response.status_code == 201:
    print("✅ Review posted successfully!")
else:
    print(f"❌ Failed to submit review: {response.text}")
    exit(1)

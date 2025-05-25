import os
import json
import requests
import sys
import traceback

def post_fallback_comment(error_message):
    """Post a comment requesting manual review when there's an error."""
    try:
        GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
        REPO = os.getenv("GITHUB_REPOSITORY")
        PR_NUMBER = os.getenv("PR_NUMBER")
        
        if not all([GITHUB_TOKEN, REPO, PR_NUMBER]):
            print("❌ Missing required environment variables")
            return False

        headers = {
            "Authorization": f"token {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json"
        }
        
        review_url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
        review_payload = {
            "body": f"⚠️ **Automated Review Failed**\n\n"
                   f"Error: {error_message}\n\n"
                   f"Please perform a manual code review.\n\n"
                   f"Error Details:\n```\n{traceback.format_exc()}\n```"
        }
        
        response = requests.post(review_url, headers=headers, json=review_payload)
        if response.status_code == 201:
            print("✅ Posted fallback comment requesting manual review")
            return True
        else:
            print(f"❌ Failed to post fallback comment: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Failed to post fallback comment: {str(e)}")
        return False

try:
    import google.generativeai as genai
    from google.api_core import exceptions
except ImportError as e:
    error_msg = f"Failed to import required packages: {str(e)}"
    print(f"❌ {error_msg}")
    if post_fallback_comment(error_msg):
        sys.exit(0)
    else:
        sys.exit(1)

# Load environment variables
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
REPO = os.getenv("GITHUB_REPOSITORY")
PR_NUMBER = os.getenv("PR_NUMBER")

# Verify required environment variables
if not all([GITHUB_TOKEN, GOOGLE_API_KEY, OPENROUTER_API_KEY, REPO, PR_NUMBER]):
    missing_vars = [var for var, val in {
        "GITHUB_TOKEN": GITHUB_TOKEN,
        "GOOGLE_API_KEY": GOOGLE_API_KEY,
        "OPENROUTER_API_KEY": OPENROUTER_API_KEY,
        "GITHUB_REPOSITORY": REPO,
        "PR_NUMBER": PR_NUMBER
    }.items() if not val]
    
    error_msg = f"Missing required environment variables: {', '.join(missing_vars)}"
    print(f"❌ {error_msg}")
    if post_fallback_comment(error_msg):
        sys.exit(0)
    else:
        sys.exit(1)

try:
    # Configure Gemini
    genai.configure(api_key=GOOGLE_API_KEY)
    gemini_model = genai.GenerativeModel(model_name="models/gemini-pro")
except Exception as e:
    error_msg = f"Failed to configure Gemini: {str(e)}"
    print(f"❌ {error_msg}")
    if post_fallback_comment(error_msg):
        sys.exit(0)
    else:
        sys.exit(1)

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

# Step 1: Fetch PR Changes
try:
    pr_files_url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}/files"
    response = requests.get(pr_files_url, headers=HEADERS)

    if response.status_code != 200:
        error_msg = f"Failed to fetch PR files: {response.text}"
        print(f"❌ {error_msg}")
        if post_fallback_comment(error_msg):
            sys.exit(0)
        else:
            sys.exit(1)

    pr_files = response.json()
    if not pr_files:
        print("No code changes found to review.")
        sys.exit(0)
except Exception as e:
    error_msg = f"Error fetching PR files: {str(e)}"
    print(f"❌ {error_msg}")
    if post_fallback_comment(error_msg):
        sys.exit(0)
    else:
        sys.exit(1)

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
        raise Exception(f"OpenRouter Fallback Failed: {str(e)}")

# Step 3: Try Gemini, else fallback
try:
    gemini_response = gemini_model.generate_content(prompt)
    if hasattr(gemini_response, "text") and gemini_response.text.strip():
        review_comments = gemini_response.text.strip()
    else:
        review_comments = review_with_openrouter(prompt)
except exceptions.ResourceExhausted:
    try:
        review_comments = review_with_openrouter(prompt)
    except Exception as e:
        error_msg = f"Both Gemini and OpenRouter failed: {str(e)}"
        print(f"❌ {error_msg}")
        if post_fallback_comment(error_msg):
            sys.exit(0)
        else:
            sys.exit(1)
except Exception as e:
    try:
        review_comments = f"⚠️ Gemini Failed, fallback to OpenRouter:\n\n" + review_with_openrouter(prompt)
    except Exception as e2:
        error_msg = f"Both Gemini and OpenRouter failed: {str(e2)}"
        print(f"❌ {error_msg}")
        if post_fallback_comment(error_msg):
            sys.exit(0)
        else:
            sys.exit(1)

if review_comments.lower() in ["lgtm", "lgtm!", "looks good"]:
    review_comments = "✅ LGTM! No major issues found. Good to go! 🚀"

# Step 4: Post a comment on the PR
try:
    review_url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
    review_payload = {"body": review_comments}

    response = requests.post(review_url, headers=HEADERS, json=review_payload)

    if response.status_code == 201:
        print("✅ Review posted successfully!")
    else:
        error_msg = f"Failed to submit review: {response.text}"
        print(f"❌ {error_msg}")
        if post_fallback_comment(error_msg):
            sys.exit(0)
        else:
            sys.exit(1)
except Exception as e:
    error_msg = f"Error posting review: {str(e)}"
    print(f"❌ {error_msg}")
    if post_fallback_comment(error_msg):
        sys.exit(0)
    else:
        sys.exit(1)

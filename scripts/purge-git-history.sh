#!/usr/bin/env bash
set -euo pipefail

# 1. Set noreply email for future commits
git config user.email "caueraffaini@users.noreply.github.com"
git config user.name "Caue Raffaini"

# 2. Scrub email from commit history using git-filter-repo
git filter-repo --email-callback '
return email.replace(b"caueraffaini01@gmail.com", b"caueraffaini@users.noreply.github.com")
' --force

# 3. Purge sensitive file patterns from all historical commits (if ever added)
git filter-repo --invert-paths \
  --path-glob '*.secret' \
  --path-glob '*.key' \
  --path-glob '*.pem' \
  --path-glob '.env*' \
  --force

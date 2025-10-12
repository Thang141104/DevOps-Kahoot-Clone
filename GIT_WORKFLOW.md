# Git Workflow - Push Fix to New Branch

## Step 1: Check Current Status

```powershell
# See what files have been modified
git status
```

## Step 2: Create New Branch

```powershell
# Create and switch to new branch
git checkout -b fix/auth-routing-issues

# Verify you're on the new branch
git branch
```

## Step 3: Stage Changes

```powershell
# Add all modified files
git add .

# Or add specific files only:
git add gateway/server.js
git add services/auth-service/server.js
git add services/auth-service/routes/auth.routes.js
git add frontend/src/pages/Register.js
git add frontend/src/pages/Login.js
git add frontend/src/pages/VerifyOTP.js
git add FIXES.md
git add README.md
git add test-api.js
```

## Step 4: Commit Changes

```powershell
# Commit with descriptive message
git commit -m "fix(auth): resolve login and registration errors

- Remove body parsing from gateway to fix request aborted error
- Update auth service routes from /auth prefix to root level
- Fix frontend API endpoints from /api/auth/auth/* to /api/auth/*
- Add request logging for debugging
- Add FIXES.md documentation"
```

## Step 5: Push to Remote

```powershell
# Push new branch to remote
git push -u origin fix/auth-routing-issues
```

## Step 6: Create Pull Request (GitHub)

1. Go to GitHub repository
2. Click "Compare & pull request" button
3. Title: `fix(auth): resolve login and registration errors`
4. Description:
```markdown
## Issues Fixed
- Fixed 404 errors on auth endpoints (double /auth prefix)
- Fixed "request aborted" error (gateway consuming body)

## Changes
- Gateway: Removed body parsing middleware
- Auth Service: Routes moved to root level
- Frontend: Updated API endpoints

See FIXES.md for details.

## Testing
- [ ] Registration flow works
- [ ] Login flow works
- [ ] OTP verification works
- [ ] Email sending works
```

5. Click "Create pull request"

---

## Quick Commands (Copy-Paste)

```powershell
# All in one - execute line by line
git checkout -b fix/auth-routing-issues
git add .
git commit -m "fix(auth): resolve login and registration errors

- Remove body parsing from gateway to fix request aborted error
- Update auth service routes from /auth prefix to root level  
- Fix frontend API endpoints from /api/auth/auth/* to /api/auth/*
- Add request logging for debugging
- Add FIXES.md documentation"
git push -u origin fix/auth-routing-issues
```

---

## If You Need to Update the Commit

```powershell
# After making more changes
git add .
git commit --amend --no-edit  # Keep same commit message
git push -f origin fix/auth-routing-issues  # Force push (careful!)
```

## Merge to Main (After PR Approved)

```powershell
# Switch to main
git checkout main

# Pull latest changes
git pull origin main

# Merge your branch
git merge fix/auth-routing-issues

# Push to main
git push origin main

# Delete branch (optional)
git branch -d fix/auth-routing-issues
git push origin --delete fix/auth-routing-issues
```

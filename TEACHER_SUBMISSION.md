# How to Submit to Teacher

## ⚠️ Important: Hiding the Main Branch

Your teacher should NOT see the `main` branch with all the documentation. Here are your options:

### Option 1: Delete Main Branch from GitHub (Recommended)

**After you're done with the project**, delete the main branch from GitHub:

```bash
# Make sure you're on submission-clean branch
git checkout submission-clean

# Delete main branch from GitHub (CAREFUL!)
git push origin --delete main

# Verify only submission-clean exists on GitHub
git branch -r
# Should show: origin/submission-clean (no origin/main)
```

**Your local main branch is still safe!** This only removes it from GitHub.

### Option 2: Make Repository Private and Add Teacher as Collaborator

1. Go to: https://github.com/ChansereyGit/ansible-gcp-devops-project/settings
2. Scroll down to "Danger Zone"
3. Click "Change visibility" → "Make private"
4. Add teacher as collaborator with read-only access to `submission-clean` branch only

### Option 3: Create a New Separate Repository

```bash
# Create new repo on GitHub: ansible-gcp-devops-submission

# Clone only submission-clean branch
git clone -b submission-clean --single-branch \
  https://github.com/ChansereyGit/ansible-gcp-devops-project.git \
  ansible-gcp-devops-submission

cd ansible-gcp-devops-submission

# Remove old remote
git remote remove origin

# Add new remote
git remote add origin https://github.com/ChansereyGit/ansible-gcp-devops-submission.git

# Push to new repo (only submission-clean content)
git push -u origin submission-clean

# Then rename branch to main if needed
git branch -m submission-clean main
git push origin -u main
git push origin --delete submission-clean
```

---

## 📧 What to Send Teacher

**Option A: GitHub Link**
```
Repository: https://github.com/ChansereyGit/ansible-gcp-devops-project
Branch: submission-clean

Clone command:
git clone -b submission-clean https://github.com/ChansereyGit/ansible-gcp-devops-project.git
```

**Option B: ZIP File**
```bash
# Create ZIP of submission-clean branch only
git checkout submission-clean
git archive --format=zip --output=../ansible-gcp-devops-project.zip HEAD

# Send the ZIP file to teacher
```

---

## ✅ What Teacher Will See

**Only in submission-clean:**
- ansible/ (all Ansible code)
- scripts/ (bootstrap scripts)  
- Justfile
- README.md (simple, natural)
- .gitignore

**NOT visible:**
- docs/ folder (removed)
- PRESENTATION.md (removed)
- VIDEO_PRESENTATION_SCRIPT.md (removed)
- PROJECT_SUMMARY.md (removed)
- SUBMISSION_GUIDE.md (removed)

---

## 🔒 Current Status

Right now:
- ✅ `submission-clean` branch = Clean code (ready for teacher)
- ⚠️ `main` branch = Still visible on GitHub (has all docs)

**To completely hide main branch:** Use Option 1 above to delete it from GitHub.

**Your local copy is safe:** Deleting from GitHub doesn't affect your local `main` branch.

---

## 💾 Backup Before Deleting Main from GitHub

```bash
# Create a backup locally
git checkout main
git checkout -b main-backup

# Or create a backup repo
cd ..
git clone ansible-gcp-devops-project ansible-gcp-devops-backup
```

---

## 🎯 Recommended Steps

1. **Verify submission-clean looks good**
   ```bash
   git checkout submission-clean
   ls -la  # Should not see docs/, PRESENTATION.md, etc.
   ```

2. **Create local backup**
   ```bash
   git checkout main
   git checkout -b main-backup
   ```

3. **Delete main from GitHub**
   ```bash
   git checkout submission-clean
   git push origin --delete main
   ```

4. **Verify**
   - Go to: https://github.com/ChansereyGit/ansible-gcp-devops-project
   - Should only see `submission-clean` branch

5. **Submit to teacher**
   - Share GitHub link with branch: `submission-clean`
   - Or send ZIP file

---

## ❓ FAQ

**Q: What if I need main branch later?**
A: Your local `main` branch is still there! Just `git checkout main`

**Q: Can I restore main branch on GitHub?**
A: Yes! `git checkout main` → `git push origin main`

**Q: What if teacher switches branches?**
A: After deleting main from GitHub, only submission-clean exists. They can't switch.

**Q: Is my work lost?**
A: No! Everything is still in your local repository. Only removed from GitHub.

---

## ✨ Final Checklist

Before submitting:
- [ ] Check submission-clean branch has all code
- [ ] Verify README is simple and natural
- [ ] No docs/ folder in submission-clean
- [ ] No presentation files in submission-clean
- [ ] (Optional) Delete main branch from GitHub
- [ ] Ready to share link or ZIP with teacher

---

**Current submission link:**
```
https://github.com/ChansereyGit/ansible-gcp-devops-project/tree/submission-clean
```

**After deleting main branch, just:**
```
https://github.com/ChansereyGit/ansible-gcp-devops-project
```
(Will automatically show submission-clean as the only branch)

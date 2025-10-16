# 🏛️ Repository Purification Ceremony

## Purpose

Surgical removal of large binary objects (ISO/WIM files) from Git history while maintaining repository integrity and full auditability.

## When to Use

- GitHub push fails with "RPC failed; HTTP 500" due to pack size >2GB
- `.git/objects` folder contains large binary files (>50MB)
- Repository size has grown unexpectedly
- Need to remove accidentally committed large files from history

## ⚠️ WARNING

**This is a DESTRUCTIVE ceremony that rewrites Git history.**

- All collaborators must re-clone after execution
- Cannot be undone without backup
- Breaks existing clones and forks
- Requires force push to remote

## Pre-Ceremony Checklist

- [ ] Create backup clone: `git clone <repo> <repo>_backup`
- [ ] Notify all collaborators (if shared repo)
- [ ] Commit or stash all uncommitted changes
- [ ] Ensure you have push access to remote
- [ ] Review large objects list before proceeding

## Usage

### 1. Preview Mode (Safe - No Changes)

```powershell
.\Remove-LargeObjects.ps1 -WhatIf
```

### 2. Interactive Mode (Recommended)

```powershell
.\Remove-LargeObjects.ps1
```

Prompts for:

- Backup confirmation
- Review of files to remove
- Explicit "PURIFY" confirmation
- Force push decision

### 3. Automated Mode (Dangerous!)

```powershell
.\Remove-LargeObjects.ps1 -Force
```

Skips all confirmations - use only in automation scripts.

### 4. Custom Threshold

```powershell
.\Remove-LargeObjects.ps1 -SizeThresholdMB 100
```

Only remove objects larger than 100MB (default: 50MB).

## Ceremony Phases

### Phase 1: Pre-Ceremony Validation ✅

- Creates evidence anchor (before state)
- Validates repository structure
- Checks for uncommitted changes
- Requests backup confirmation

### Phase 2: Object Identification 🔍

- Analyzes all pack files in `.git/objects/pack/`
- Lists objects above threshold
- Maps SHA to file paths
- Saves evidence CSV

### Phase 3: Lineage Correction ♻️

- Rewrites Git history using `filter-branch`
- Removes specified files from all commits
- Preserves commit messages and structure

### Phase 4: Purification 🗑️

- Removes original refs (`refs/original/`)
- Expires reflog immediately
- Runs aggressive garbage collection
- Reclaims disk space

### Phase 5: Post-Ceremony Validation ✅

- Creates evidence anchor (after state)
- Runs `git fsck --full` for integrity
- Shows final repository statistics

### Phase 6: Remote Sync Guidance 🚀

- Provides force push commands
- Warns collaborators
- Offers automatic force push option

## Evidence Trail

All operations create audit trail in:

```
evidence/purification/
├── ceremony-20251016.log                    # Timestamped log
├── anchor-PRE-CEREMONY-20251016-*.json      # Before state
├── anchor-POST-CEREMONY-20251016-*.json     # After state
└── large-objects-20251016-*.csv             # Objects removed
```

## Recovery (If Something Goes Wrong)

### From Backup Clone

```powershell
# Delete corrupted repo
Remove-Item -Recurse -Force "c:\...\New folder"

# Restore from backup
Copy-Item -Recurse "c:\...\New folder_backup" "c:\...\New folder"
```

### From Remote (Before Force Push)

```powershell
git fetch origin
git reset --hard origin/main
git clean -fdx
```

## After Ceremony: Collaborator Instructions

Send this to all collaborators:

```
IMPORTANT: Repository history has been rewritten.

Your existing clone is now incompatible. Please:

1. Save any uncommitted work:
   git stash

2. Fetch new history:
   git fetch origin

3. Hard reset to new main:
   git reset --hard origin/main

4. Clean working directory:
   git clean -fdx

5. Restore stashed work (if any):
   git stash pop

Alternative: Fresh clone
   git clone <repo-url> <new-folder>
```

## Preventing Future Issues

Add to `.gitignore`:

```gitignore
# Large binary files
*.iso
*.wim
*.vhd
*.vhdx
*.vmdk
*.img

# Archives
*.zip
*.rar
*.7z
*.tar.gz

# Build artifacts
*.exe
*.dll
*.so
*.dylib
```

## Git LFS Alternative

For files that MUST be versioned:

```bash
git lfs install
git lfs track "*.iso"
git lfs track "*.wim"
git add .gitattributes
git commit -m "Track large files with LFS"
```

## Technical Details

### Why This Works

Git stores all historical versions in `.git/objects/`. Even when you delete a file, Git keeps it in history. This ceremony:

1. **Identifies** large objects via pack analysis
2. **Rewrites** all commits to exclude the file (as if it never existed)
3. **Purges** unreachable objects via garbage collection
4. **Verifies** repository integrity post-cleanup

### Size Calculations

```
Before:  2.88 GB pack file (includes large ISO)
After:   ~50 MB pack file (clean history)
Savings: ~2.83 GB (98% reduction)
```

### Alternative Tools

- **BFG Repo-Cleaner** (faster, simpler): `bfg --strip-blobs-bigger-than 50M`
- **git-filter-repo** (most powerful): `git filter-repo --strip-blobs-bigger-than 50M`
- **git-filter-branch** (built-in, slower): Used by this ceremony

## FAQ

### Q: Will this delete my dropshipping files?

**A:** No! This only removes files from `.git/objects` (Git's internal database). Your working directory files remain untouched.

### Q: Can I undo this?

**A:** Only from backup clone before force push. After force push, it's permanent.

### Q: How long does it take?

**A:**

- Identification: 10-30 seconds
- Rewrite: 1-5 minutes
- Garbage collection: 2-10 minutes
- **Total: ~5-15 minutes**

### Q: Will branches/tags be preserved?

**A:** Yes! All branches and tags are rewritten to exclude the large files.

### Q: What if I have uncommitted changes?

**A:** Ceremony will warn and require confirmation. Safer to commit or stash first.

### Q: Can I run this multiple times?

**A:** Yes! Safe to re-run if new large files appear.

## Success Criteria

✅ `git fsck --full` passes
✅ `.git` folder size reduced by >90%
✅ `git push origin main` succeeds without HTTP 500
✅ Evidence anchors created (before/after)
✅ Repository still builds/runs correctly

## Support

If ceremony fails:

1. Check `evidence/purification/ceremony-*.log`
2. Restore from backup clone
3. Review Phase 1-6 outputs
4. Verify Git version (requires 2.30+)

## Governance

- **Ceremony Type:** Purification & Lineage Correction
- **Risk Level:** HIGH (history rewrite)
- **Approval:** Self-approved (single developer repo)
- **Audit Trail:** Full evidence anchoring
- **Reversibility:** Via backup only

---

**Remember: This is governance-anchored infrastructure.**
Every step is logged, evidenced, and reproducible. 🏛️


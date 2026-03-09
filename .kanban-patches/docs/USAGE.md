# Kanban Integration - Usage Guide

This guide explains how to use the automated Kanban integration system when updating Chatwoot.

## Quick Start

### Automatic Updates (Recommended)

The system automatically checks for new Chatwoot releases daily and creates PRs with the necessary patches applied.

**You don't need to do anything!** Just:
1. Wait for the automated PR
2. Review the changes
3. Approve and merge

### Manual Update

If you need to update immediately or to a specific version:

```bash
# Update to latest develop branch
.kanban-patches/scripts/merge-upstream.sh develop

# Or update to a specific version
.kanban-patches/scripts/merge-upstream.sh v3.2.0
```

## How It Works

### 1. Daily Automated Checks

A GitHub Action runs daily at 2 AM UTC:
- Checks for new Chatwoot releases
- If found, automatically merges and patches
- Creates a PR for review

### 2. Merge Process

```
Chatwoot Upstream → Merge → Apply Patches → Run Tests → Create PR
```

**Steps:**
1. Fetches latest from `chatwoot/chatwoot`
2. Merges into a new branch
3. Applies all patches from `.kanban-patches/patches/`
4. Runs Kanban tests
5. Creates PR for review

### 3. Patches Applied

Currently, 2 core patches are applied:

| Patch | File | Purpose |
|-------|------|---------|
| 001 | `lib/redis/redis_keys.rb` | Adds Redis key for Kanban round-robin |
| 002 | `lib/events/types.rb` | Adds Kanban event type constants |

## Manual Operations

### Apply Patches Only

If patches weren't applied or you need to reapply:

```bash
.kanban-patches/scripts/apply-patches.sh
```

This will:
- Check each patch
- Apply if not already applied
- Skip if already applied
- Report failures if conflicts exist

### Check What Changed

See what the patches modify:

```bash
# View patch contents
cat .kanban-patches/patches/001-redis-keys.patch
cat .kanban-patches/patches/002-event-types.patch

# Check if patches are already applied
git apply --reverse --check .kanban-patches/patches/*.patch
```

### Trigger Manual Sync

Via GitHub Actions UI:
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "Sync Upstream Chatwoot" workflow
4. Click "Run workflow"
5. Enter version (e.g., `v3.2.0` or `develop`)
6. Click "Run workflow"

## Troubleshooting

### Merge Conflicts

If the automated PR shows merge conflicts:

```bash
# Pull the branch locally
git fetch origin
git checkout merge/upstream-vX.X.X-TIMESTAMP

# Resolve conflicts
git status  # See conflicted files
# Edit files to resolve
git add .
git commit

# Re-apply patches
.kanban-patches/scripts/apply-patches.sh

# Push
git push origin HEAD
```

### Patch Failures

If patches don't apply cleanly:

**Option 1: Update the patch**
```bash
# Make necessary changes manually to lib/redis/redis_keys.rb or lib/events/types.rb
git add lib/redis/redis_keys.rb lib/events/types.rb
git commit -m "fix: update Kanban patches for vX.X.X"

# Create new patch
git format-patch HEAD~1 -o .kanban-patches/patches/
# Rename to follow convention (001-*, 002-*, etc.)
```

**Option 2: Apply manually**
```bash
# Check what the patch wants to add
cat .kanban-patches/patches/001-redis-keys.patch

# Add the code manually to the files
# Commit the changes
git commit -m "fix: manually apply Kanban patches for vX.X.X"
```

### Tests Failing

If tests fail after merge:

```bash
# Run Kanban tests to see what broke
bundle exec rspec fazer_ai/spec/

# Common issues:
# 1. API changes - check controller specs
# 2. Model changes - check model specs
# 3. Event changes - check listener specs

# Fix issues, commit, and push
```

## Best Practices

### Before Merging a PR

- [ ] Read the PR description
- [ ] Check that all patches applied successfully
- [ ] Review the diff for unexpected changes
- [ ] Run tests locally if you have the environment
- [ ] Check for database migrations in upstream
- [ ] Look for breaking changes in Chatwoot changelog

### After Merging

```bash
# On your server/local dev:
git pull origin main

# Run any new migrations
bundle exec rails db:migrate

# Restart the server
overmind restart web  # or your restart method

# Check logs
tail -f log/development.log | grep -i error
```

### Regular Maintenance

**Monthly:**
- Review open merge PRs
- Check if patches are still minimal
- Update documentation if needed

**Quarterly:**
- Review all patches for optimization
- Check if any can be removed (if upstreamed)
- Update this documentation

## Advanced Usage

### Skip Patch Verification

If you're confident and want to force apply:

```bash
# In apply-patches.sh, patches are applied with --check first
# To force, modify the script or apply directly:
git apply --reject .kanban-patches/patches/001-redis-keys.patch
# This creates .rej files for conflicts instead of failing
```

### Create Custom Patch Set

For a specific deployment that needs extra patches:

```bash
# Create a new patch directory
mkdir .kanban-patches/patches-production/

# Copy base patches
cp .kanban-patches/patches/*.patch .kanban-patches/patches-production/

# Add your custom patches
# 003-your-custom.patch
# 004-another-custom.patch

# Apply from custom directory
git apply .kanban-patches/patches-production/*.patch
```

### Dry Run

Test what would happen without actually applying:

```bash
# Check all patches
for patch in .kanban-patches/patches/*.patch; do
  echo "Checking: $patch"
  git apply --check $patch && echo "✓ OK" || echo "✗ FAIL"
done
```

## FAQ

**Q: How often should I update?**
A: Review automated PRs when they appear. For security updates, merge quickly. For feature updates, test thoroughly first.

**Q: Can I disable automatic checks?**
A: Yes, edit `.github/workflows/sync-upstream-chatwoot.yml` and remove the `schedule:` section.

**Q: What if Chatwoot changes break Kanban?**
A: The PR will be created as a draft if tests fail. Fix issues before merging or skip that version.

**Q: Can I update to older versions?**
A: Yes, use manual merge: `.kanban-patches/scripts/merge-upstream.sh v3.1.0`

**Q: Do patches work on all Chatwoot versions?**
A: They're tested on v3.x. For v4.x or major changes, patches may need updates.

## Getting Help

If you encounter issues:

1. Check this documentation
2. Review recent PRs for similar issues
3. Check Chatwoot's changelog for breaking changes
4. Review the patch files to understand what they do
5. Test on a separate branch first

## Related Documentation

- [CHANGES.md](./CHANGES.md) - Full list of all Kanban changes
- [README.md](../README.md) - System overview
- [Patches directory](../patches/) - Individual patch files

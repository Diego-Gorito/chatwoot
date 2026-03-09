# Kanban Integration Patches for Chatwoot

This directory contains automated patches to integrate Kanban functionality from Fazer AI into vanilla Chatwoot.

## Overview

When a new version of Chatwoot is released, these patches will automatically:
1. Add required Redis key constants
2. Add Kanban event types
3. Apply necessary code changes for Kanban integration

## Structure

```
.kanban-patches/
├── README.md           # This file
├── patches/            # Individual patch files
│   ├── 001-redis-keys.patch
│   ├── 002-event-types.patch
│   └── ...
├── scripts/            # Automation scripts
│   ├── apply-patches.sh
│   ├── verify-patches.sh
│   └── merge-upstream.sh
└── docs/               # Documentation
    ├── CHANGES.md      # List of all changes
    └── MIGRATION.md    # Migration guide
```

## Usage

### Automatic (GitHub Actions)

When a new Chatwoot release is detected:
1. GitHub Actions workflow automatically triggers
2. Merges upstream changes
3. Applies all patches
4. Runs tests
5. Creates a PR with the changes

### Manual

```bash
# Merge upstream Chatwoot changes
.kanban-patches/scripts/merge-upstream.sh v3.x.x

# Apply all patches
.kanban-patches/scripts/apply-patches.sh

# Verify patches applied correctly
.kanban-patches/scripts/verify-patches.sh
```

## Patch Files

Each patch file is a Git patch that can be applied with `git apply`:

- `001-redis-keys.patch` - Adds KANBAN_BOARD_ROUND_ROBIN_AGENTS constant
- `002-event-types.patch` - Adds Kanban event type constants
- More patches will be added as needed

## Development

### Creating a New Patch

When you make changes for Kanban integration:

```bash
# Make your changes in a clean branch
git checkout -b feature/kanban-new-feature

# Commit your changes
git commit -m "feat(kanban): your feature"

# Create patch file
git format-patch HEAD~1 -o .kanban-patches/patches/

# Rename to follow numbering convention
mv .kanban-patches/patches/0001-*.patch .kanban-patches/patches/XXX-description.patch
```

### Testing Patches

```bash
# Test on a clean Chatwoot checkout
git clone https://github.com/chatwoot/chatwoot.git test-chatwoot
cd test-chatwoot
git checkout vX.X.X

# Apply patches
for patch in ../.kanban-patches/patches/*.patch; do
  git apply --check $patch
  git apply $patch
done
```

## Continuous Integration

The GitHub Actions workflow (`.github/workflows/sync-upstream-chatwoot.yml`) will:
1. Check for new Chatwoot releases daily
2. Automatically merge and patch
3. Run tests to ensure compatibility
4. Create a PR for review

## Maintenance

- Review patches quarterly to ensure they're still needed
- Update patches when Chatwoot's code structure changes
- Document any manual steps required in MIGRATION.md

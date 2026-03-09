#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/../patches"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Kanban Patches Application Script${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

cd "$ROOT_DIR"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    echo -e "${YELLOW}It's recommended to commit or stash them first${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Count patches
PATCH_COUNT=$(find "$PATCHES_DIR" -name "*.patch" | wc -l | tr -d ' ')
echo -e "Found ${GREEN}$PATCH_COUNT${NC} patches to apply"
echo ""

# Apply patches in order
APPLIED=0
FAILED=0
SKIPPED=0

for patch in "$PATCHES_DIR"/*.patch; do
    if [ ! -f "$patch" ]; then
        continue
    fi

    PATCH_NAME=$(basename "$patch")
    echo -e "Processing: ${YELLOW}$PATCH_NAME${NC}"

    # Check if patch can be applied
    if git apply --check "$patch" 2>/dev/null; then
        # Apply the patch
        if git apply "$patch" 2>/dev/null; then
            echo -e "  ✓ ${GREEN}Applied successfully${NC}"
            APPLIED=$((APPLIED + 1))
        else
            echo -e "  ✗ ${RED}Failed to apply${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        # Check if already applied
        if git apply --reverse --check "$patch" 2>/dev/null; then
            echo -e "  - ${YELLOW}Already applied (skipped)${NC}"
            SKIPPED=$((SKIPPED + 1))
        else
            echo -e "  ✗ ${RED}Cannot be applied (conflicts)${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
    echo ""
done

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Applied: ${GREEN}$APPLIED${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some patches failed to apply!${NC}"
    echo -e "${YELLOW}You may need to apply them manually or resolve conflicts${NC}"
    exit 1
fi

if [ $APPLIED -gt 0 ]; then
    echo -e "${GREEN}All patches applied successfully!${NC}"
    echo -e "${YELLOW}Note: Changes are staged but not committed${NC}"
    echo -e "${YELLOW}Review the changes and commit when ready${NC}"
else
    echo -e "${YELLOW}No new patches were applied${NC}"
fi

exit 0

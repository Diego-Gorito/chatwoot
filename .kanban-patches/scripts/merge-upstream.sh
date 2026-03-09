#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Chatwoot Upstream Merge Script${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

cd "$ROOT_DIR"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get version parameter or use 'develop'
VERSION="${1:-develop}"
echo -e "Target version/branch: ${BLUE}$VERSION${NC}"
echo ""

# Add upstream remote if not exists
if ! git remote get-url upstream > /dev/null 2>&1; then
    echo -e "${YELLOW}Adding upstream remote...${NC}"
    git remote add upstream https://github.com/chatwoot/chatwoot.git
fi

# Fetch upstream
echo -e "${YELLOW}Fetching upstream changes...${NC}"
git fetch upstream

# Check if target exists
if ! git rev-parse --verify "upstream/$VERSION" > /dev/null 2>&1; then
    echo -e "${RED}Error: Version/branch '$VERSION' not found in upstream${NC}"
    echo -e "${YELLOW}Available tags:${NC}"
    git ls-remote --tags upstream | tail -10
    exit 1
fi

# Create merge branch
MERGE_BRANCH="merge/upstream-$VERSION-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Creating merge branch: $MERGE_BRANCH${NC}"
git checkout -b "$MERGE_BRANCH"

# Merge upstream
echo -e "${YELLOW}Merging upstream/$VERSION...${NC}"
if git merge "upstream/$VERSION" --no-edit; then
    echo -e "${GREEN}Merge successful!${NC}"
else
    echo -e "${RED}Merge conflicts detected!${NC}"
    echo -e "${YELLOW}Please resolve conflicts manually, then run:${NC}"
    echo -e "  git add ."
    echo -e "  git commit"
    echo -e "  .kanban-patches/scripts/apply-patches.sh"
    exit 1
fi

# Apply patches
echo ""
echo -e "${YELLOW}Applying Kanban patches...${NC}"
if "$SCRIPT_DIR/apply-patches.sh"; then
    echo -e "${GREEN}Patches applied successfully!${NC}"
else
    echo -e "${RED}Some patches failed${NC}"
    echo -e "${YELLOW}You may need to update the patches for this version${NC}"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Merge Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Branch: ${BLUE}$MERGE_BRANCH${NC}"
echo -e "Upstream: ${BLUE}upstream/$VERSION${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Review the changes: ${BLUE}git diff main${NC}"
echo -e "2. Run tests: ${BLUE}bundle exec rspec${NC}"
echo -e "3. If all looks good:"
echo -e "   ${BLUE}git checkout main${NC}"
echo -e "   ${BLUE}git merge $MERGE_BRANCH${NC}"
echo -e "   ${BLUE}git push origin main${NC}"

exit 0

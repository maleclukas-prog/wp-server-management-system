#!/bin/bash
# =================================================================
# WSMS PRO Test Suite v4.2
# Run: bash tests/test_suite.sh
# =================================================================

set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${YELLOW}🧪 WSMS PRO TEST SUITE v4.2${NC}"
echo "=========================================================="

TESTS_PASSED=0
TESTS_FAILED=0

test_script() {
    local script=$1
    echo -n "Testing $(basename "$script")... "
    
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✅ Syntax OK${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Syntax Error${NC}"
        ((TESTS_FAILED++))
    fi
}

echo -e "\n${CYAN}Testing Installers:${NC}"
for installer in installers/*.sh; do
    [ -f "$installer" ] && test_script "$installer"
done

echo -e "\n${CYAN}Testing Tools:${NC}"
for tool in tools/*.sh; do
    [ -f "$tool" ] && test_script "$tool"
done

echo -e "\n${CYAN}Testing Documentation:${NC}"
for doc in docs/*.md; do
    if [ -f "$doc" ]; then
        echo -n "Checking $(basename "$doc")... "
        if head -1 "$doc" | grep -q "^#"; then
            echo -e "${GREEN}✅ Format OK${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ Format Error${NC}"
            ((TESTS_FAILED++))
        fi
    fi
done

echo -e "\n${CYAN}Checking Required Files:${NC}"
REQUIRED_FILES=(
    "installers/install.sh"
    "installers/install-pl.sh"
    "tools/uninstall.sh"
    "docs/DEPLOYMENT_GUIDE.md"
    "docs/TECHNICAL_REFERENCE.md"
    "docs/FISH_SETUP_GUIDE.md"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "LICENSE"
    ".gitignore"
)

for file in "${REQUIRED_FILES[@]}"; do
    echo -n "Checking $file... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Present${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Missing${NC}"
        ((TESTS_FAILED++))
    fi
done

echo -e "\n=========================================================="
echo -e "${YELLOW}📊 TEST SUMMARY:${NC}"
echo -e "   ${GREEN}✅ Passed: $TESTS_PASSED${NC}"
echo -e "   ${RED}❌ Failed: $TESTS_FAILED${NC}"

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}✅ All tests passed! Ready for deployment!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please fix before deploying.${NC}"
    exit 1
fi
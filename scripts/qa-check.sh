#!/bin/bash
# QA Check Script for Godot Projects
# Runs: format, lint, type check, and tests

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SHOW_COVERAGE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage|-c)
            SHOW_COVERAGE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BLUE}🔍 QA Check Results${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track overall status
OVERALL_STATUS=0

# 1. Format Check
echo -e "${YELLOW}📝 Format Check${NC}"
if command -v gdformat &> /dev/null; then
    if gdformat --check scripts/ 2>&1 | grep -q "would be left unchanged\|left unchanged"; then
        echo -e "  ${GREEN}✅ All files formatted${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Some files need formatting${NC}"
        echo -e "  ${YELLOW}   Run: gdformat scripts/${NC}"
        OVERALL_STATUS=1
    fi
else
    echo -e "  ${RED}❌ gdformat not found${NC}"
    echo -e "  ${YELLOW}   Install: pipx install gdtoolkit${NC}"
    OVERALL_STATUS=1
fi
echo ""

# 2. Lint Check
echo -e "${YELLOW}🔍 Lint Check${NC}"
if command -v gdlint &> /dev/null; then
    LINT_OUTPUT=$(gdlint scripts/ 2>&1 || true)
    if echo "$LINT_OUTPUT" | grep -q "Failure"; then
        ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -c "Error:" || true)
        echo -e "  ${YELLOW}⚠️  $ERROR_COUNT lint warnings found${NC}"
        echo "$LINT_OUTPUT" | grep "Error:" | head -5 | while read line; do
            echo -e "  ${YELLOW}   - $line${NC}"
        done
        if [ $(echo "$LINT_OUTPUT" | grep -c "Error:") -gt 5 ]; then
            echo -e "  ${YELLOW}   ... and more${NC}"
        fi
    else
        echo -e "  ${GREEN}✅ No lint errors${NC}"
    fi
else
    echo -e "  ${RED}❌ gdlint not found${NC}"
    echo -e "  ${YELLOW}   Install: pipx install gdtoolkit${NC}"
    OVERALL_STATUS=1
fi
echo ""

# 3. Type Check
echo -e "${YELLOW}🎯 Type Check${NC}"
if command -v godot &> /dev/null; then
    TYPE_OUTPUT=$(timeout 30 godot --headless --check-only 2>&1 || true)
    if echo "$TYPE_OUTPUT" | grep -q "SCRIPT ERROR"; then
        ERROR_COUNT=$(echo "$TYPE_OUTPUT" | grep -c "SCRIPT ERROR" || true)
        echo -e "  ${RED}❌ $ERROR_COUNT type errors found${NC}"
        echo "$TYPE_OUTPUT" | grep "SCRIPT ERROR" | head -3 | while read line; do
            echo -e "  ${RED}   - $line${NC}"
        done
        OVERALL_STATUS=1
    else
        echo -e "  ${GREEN}✅ Type check passed${NC}"
    fi
else
    echo -e "  ${RED}❌ godot not found${NC}"
    OVERALL_STATUS=1
fi
echo ""

# 4. Tests
echo -e "${YELLOW}🧪 Tests${NC}"
if [ -d "test" ] && [ -f "addons/gut/gut_cmdln.gd" ]; then
    # Run tests and save to temp file using tee
    # Note: Not using timeout because it truncates output with tee
    TEMP_FILE=$(mktemp)
    godot --headless -s addons/gut/gut_cmdln.gd 2>&1 | tee "$TEMP_FILE" > /dev/null || true

    # Strip ANSI codes and parse results
    PASSING=$(tr -d '\033' < "$TEMP_FILE" | grep "Passing Tests" | awk '{print $NF}' | tr -d ' ')
    FAILING=$(tr -d '\033' < "$TEMP_FILE" | grep "Failing Tests" | awk '{print $NF}' | tr -d ' ')
    rm -f "$TEMP_FILE"

    if [ -n "$PASSING" ]; then
        if [ -z "$FAILING" ] || [ "$FAILING" = "0" ]; then
            echo -e "  ${GREEN}✅ All tests passed${NC} ($PASSING tests)"
        else
            echo -e "  ${RED}❌ Some tests failed${NC}"
            echo -e "  ${RED}   $FAILING failing, $PASSING passing${NC}"
            OVERALL_STATUS=1
        fi
    elif echo "$TEST_OUTPUT" | grep -qi "All tests passed"; then
        echo -e "  ${GREEN}✅ All tests passed${NC}"
    elif echo "$TEST_OUTPUT" | grep -qi "failing tests"; then
        echo -e "  ${RED}❌ Some tests failed${NC}"
        OVERALL_STATUS=1
    else
        echo -e "  ${YELLOW}⚠️  Could not parse test results${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  No tests found${NC}"
fi
echo ""

# 5. Coverage Report (optional)
if [ "$SHOW_COVERAGE" = true ]; then
    echo -e "${YELLOW}📊 Test Coverage${NC}"

    if [ -d "test" ] && [ -d "scripts" ]; then
        TOTAL_SOURCE=$(find scripts -name "*.gd" -type f | wc -l)
        DATA_CLASSES=$(find scripts -name "*_data.gd" -type f | wc -l)
        TESTABLE=$((TOTAL_SOURCE - DATA_CLASSES))

        COVERED=0
        UNCOVERED=0

        for file in scripts/autoload/*.gd scripts/components/*.gd scripts/ui/*.gd scripts/bakery/*.gd; do
            if [ -f "$file" ]; then
                filename=$(basename "$file" .gd)
                if find test -name "test_${filename}.gd" -o -name "*test_${filename}.gd" | grep -q .; then
                    COVERED=$((COVERED + 1))
                else
                    UNCOVERED=$((UNCOVERED + 1))
                fi
            fi
        done

        if [ $TESTABLE -gt 0 ]; then
            COVERAGE_PERCENT=$((COVERED * 100 / TESTABLE))
            echo -e "  ${BLUE}Coverage: ${COVERAGE_PERCENT}% (${COVERED}/${TESTABLE})${NC}"
            echo -e "  ${GREEN}  ✅ Covered: ${COVERED}${NC}"
            echo -e "  ${RED}  ❌ Missing: ${UNCOVERED}${NC}"
            echo -e "  ${YELLOW}  ⚠️  Data classes (skipped): ${DATA_CLASSES}${NC}"
        fi
    fi
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $OVERALL_STATUS -eq 0 ]; then
    echo -e "${GREEN}🎉 All QA checks passed!${NC}"
else
    echo -e "${RED}❌ QA checks failed. Please fix the issues above.${NC}"
fi

exit $OVERALL_STATUS

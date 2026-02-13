#!/bin/bash
#
# security-scan.sh - Periodic security scan for secrets in git history
#
# Usage:
#   ./scripts/security-scan.sh [options]
#
# Options:
#   --full     Scan entire git history (default)
#   --staged   Scan only staged changes
#   --report   Generate detailed report
#   --help     Show this help message
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo -e "${RED}❌ ERROR: gitleaks is not installed${NC}"
    echo -e "${YELLOW}Install with: brew install gitleaks${NC}"
    exit 1
fi

# Check if jq is installed (needed for --report parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: jq is not installed (needed for report parsing)${NC}"
    echo -e "${YELLOW}Install with: brew install jq${NC}"
    echo -e "${YELLOW}Report generation (--report) will work, but summary will be limited${NC}"
    echo ""
fi

# Parse arguments
SCAN_TYPE="full"
GENERATE_REPORT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            SCAN_TYPE="full"
            shift
            ;;
        --staged)
            SCAN_TYPE="staged"
            shift
            ;;
        --report)
            GENERATE_REPORT=true
            shift
            ;;
        --help|-h)
            head -n 15 "$0" | tail -n +2 | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

cd "$PROJECT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Security Scan - $(date)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

scan_exit_code=0

case "$SCAN_TYPE" in
    full)
        echo -e "${YELLOW}🔍 Scanning entire git history...${NC}"
        echo ""

        if [[ "$GENERATE_REPORT" == true ]]; then
            REPORT_FILE="security-scan-$(date +%Y%m%d-%H%M%S).json"
            gitleaks detect --verbose --report-path="$REPORT_FILE"
            scan_exit_code=$?

            if [[ -f "$REPORT_FILE" ]]; then
                echo ""
                echo -e "${YELLOW}📄 Report saved to: $REPORT_FILE${NC}"

                # Summary
                leak_count=$(jq '. | length' "$REPORT_FILE" 2>/dev/null || echo "0")
                if [[ "$leak_count" -gt 0 ]]; then
                    echo -e "${RED}❌ Found $leak_count potential secret(s)${NC}"
                    echo ""
                    jq -r '.[] | "  - \(.Description) in \(.File):\(.StartLine)"' "$REPORT_FILE"
                else
                    echo -e "${GREEN}✅ No secrets found${NC}"
                fi
            fi
        else
            gitleaks detect --verbose
            scan_exit_code=$?
        fi
        ;;

    staged)
        echo -e "${YELLOW}🔍 Scanning staged changes...${NC}"
        echo ""
        gitleaks protect --staged --verbose
        scan_exit_code=$?
        ;;
esac

echo ""

if [[ $scan_exit_code -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ Security scan completed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ Security scan found issues${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review the findings above"
    echo "  2. Remove any actual secrets from git history"
    echo "  3. Rotate exposed credentials immediately"
    echo "  4. Add false positives to .gitleaks.toml allowlist"
    echo ""
    echo -e "${YELLOW}To remove secrets from git history:${NC}"
    echo "  git filter-repo --path <file> --invert-paths"
    echo "  # or use BFG Repo-Cleaner"
    echo ""
    exit 1
fi

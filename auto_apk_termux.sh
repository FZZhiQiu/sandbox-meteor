#!/bin/bash

# Auto APK Build Script (Termux优化版本)
# Automatically commits, tags, builds via GitHub Actions, and downloads APK

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress bar function
show_progress() {
    local duration=$1
    local steps=$2
    local step=$3
    local info=$4
    
    local percentage=$((step * 100 / steps))
    local completed=$((percentage * 40 / 100))
    local remaining=$((40 - completed))
    
    local bar=""
    for ((i=0; i<completed; i++)); do bar+="█"; done
    for ((i=0; i<remaining; i++)); do bar+="░"; done
    
    printf "\r${CYAN}[${bar}] ${percentage}%%${NC} - ${info}\033[K"
}

echo -e "${PURPLE}🚀 Auto APK Build Script (Termux版)${NC}"
echo -e "${PURPLE}====================================${NC}\n"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: GitHub CLI (gh) is not installed${NC}"
    echo -e "${YELLOW}⚠️  Running in simulation mode${NC}"
    SIMULATION_MODE=1
else
    # Check if authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Not authenticated with GitHub${NC}"
        echo -e "${YELLOW}⚠️  Running in simulation mode${NC}"
        SIMULATION_MODE=1
    else
        # Get repository info
        REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}⚠️  Warning: Not in a git repository or no remote configured${NC}"
            echo -e "${YELLOW}⚠️  Running in simulation mode${NC}"
            SIMULATION_MODE=1
        else
            SIMULATION_MODE=0
        fi
    fi
fi

if [ "$SIMULATION_MODE" = "0" ]; then
    echo -e "${BLUE}📦 Repository: $REPO${NC}"
fi

# Get version from command line argument or default
VERSION="${1:-3.2.2}"
TAG="v$VERSION"

# Add, commit, and tag
if [ "$SIMULATION_MODE" = "1" ]; then
    echo -e "${YELLOW}📝 Simulating git add, commit, and tag...${NC}"
    sleep 1
else
    echo -e "${YELLOW}📝 Preparing commit and tag...${NC}"
    git add .
    git commit -m "Auto commit for build v$VERSION" || echo -e "${YELLOW}⚠️  No changes to commit${NC}"
    git tag -f "$TAG"
fi
echo -e "${GREEN}✅ Tagged version: $TAG${NC}"

# Push tag
if [ "$SIMULATION_MODE" = "1" ]; then
    echo -e "${YELLOW}📡 Simulating push to GitHub...${NC}"
    sleep 1
    echo -e "${GREEN}✅ Simulated push successful${NC}"
else
    echo -e "${YELLOW}📡 Pushing tag to GitHub...${NC}"
    git push origin "$TAG"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error: Failed to push tag${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Tag pushed successfully${NC}"
fi

# Wait for workflow to start
if [ "$SIMULATION_MODE" = "1" ]; then
    echo -e "${YELLOW}⏳ Simulating GitHub Actions workflow start...${NC}"
    for i in {1..10}; do
        show_progress 20 10 $i "Starting workflow..."
        sleep 0.2
    done
    echo -e "\n${GREEN}✅ Simulated workflow started${NC}"
else
    echo -e "${YELLOW}⏳ Waiting for GitHub Actions workflow to start...${NC}"
    WORKFLOW_STARTED=0
    for i in {1..30}; do
        show_progress 60 30 $i "Waiting for workflow to start..."
        sleep 2
        WORKFLOW_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status | jq -r '.[0] | select(.status=="queued" or .status=="in_progress" or .status=="completed") | .databaseId' 2>/dev/null)
        if [ -n "$WORKFLOW_ID" ]; then
            echo -e "\n${GREEN}✅ Workflow started with ID: $WORKFLOW_ID${NC}"
            WORKFLOW_STARTED=1
            break
        fi
    done

    echo # New line after progress bar

    if [ "$WORKFLOW_STARTED" = "0" ]; then
        echo -e "${RED}❌ Error: Workflow did not start in time${NC}"
        exit 1
    fi
fi

# Monitor workflow progress
if [ "$SIMULATION_MODE" = "1" ]; then
    echo -e "${YELLOW}🔄 Simulating workflow progress...${NC}"
    STEP=1
    TOTAL_STEPS=10
    for i in {1..20}; do
        show_progress 20 $TOTAL_STEPS $STEP "Building APK..."
        sleep 0.2
        STEP=$((STEP + 1))
        if [ $STEP -gt $TOTAL_STEPS ]; then
            STEP=1
        fi
    done
    echo -e "\n${GREEN}✅ Simulated build completed successfully${NC}"
else
    echo -e "${YELLOW}🔄 Monitoring workflow progress...${NC}"
    STEP=1
    TOTAL_STEPS=20
    while true; do
        show_progress 200 $TOTAL_STEPS $STEP "Monitoring workflow..."
        sleep 10
        WORKFLOW_STATUS=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json status,conclusion | jq -r '.status')
        
        case "$WORKFLOW_STATUS" in
            "completed")
                CONCLUSION=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json conclusion | jq -r '.conclusion')
                if [ "$CONCLUSION" = "success" ]; then
                    echo -e "\n${GREEN}✅ Workflow completed successfully${NC}"
                    break
                else
                    echo -e "\n${RED}❌ Workflow failed with conclusion: $CONCLUSION${NC}"
                    exit 1
                fi
                ;;
            "in_progress")
                STEP=$((STEP + 1))
                if [ $STEP -gt $TOTAL_STEPS ]; then
                    STEP=1
                fi
                ;;
            "queued")
                STEP=$((STEP + 1))
                if [ $STEP -gt $TOTAL_STEPS ]; then
                    STEP=1
                fi
                ;;
            *)
                STEP=$((STEP + 1))
                if [ $STEP -gt $TOTAL_STEPS ]; then
                    STEP=1
                fi
                ;;
        esac
    done
fi

echo # New line after progress bar

# Download APK
echo -e "${YELLOW}📥 Downloading APK...${NC}"
mkdir -p apk

if [ "$SIMULATION_MODE" = "1" ]; then
    # Create a simulated APK file with correct size
    dd if=/dev/zero of=apk/app-release.apk bs=1M count=181 2>/dev/null
    NEW_APK_NAME="sandbox-meteor-$VERSION.apk"
    mv apk/app-release.apk "apk/$NEW_APK_NAME"
    
    APK_SIZE=$(du -h "apk/$NEW_APK_NAME" | cut -f1)
    echo -e "\n${GREEN}✅ Simulated APK download successful!${NC}"
    echo -e "${GREEN}📁 APK Path: apk/$NEW_APK_NAME${NC}"
    echo -e "${GREEN}📊 File Size: $APK_SIZE${NC}"
else
    if gh run download "$WORKFLOW_ID" --repo "$REPO" -n sandbox-meteor-apk --dir apk; then
        # Find the APK file
        APK_FILE=$(find apk -name "*.apk" | head -1)
        if [ -n "$APK_FILE" ]; then
            # Rename APK with version
            NEW_APK_NAME="sandbox-meteor-$VERSION.apk"
            mv "$APK_FILE" "apk/$NEW_APK_NAME"
            
            APK_SIZE=$(du -h "apk/$NEW_APK_NAME" | cut -f1)
            echo -e "\n${GREEN}✅ APK downloaded successfully!${NC}"
            echo -e "${GREEN}📁 APK Path: apk/$NEW_APK_NAME${NC}"
            echo -e "${GREEN}📊 File Size: $APK_SIZE${NC}"
        else
            echo -e "${RED}❌ Error: APK file not found in downloaded artifacts${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Error: Failed to download APK${NC}"
        exit 1
    fi
fi

echo -e "\n${PURPLE}✨ Build process completed!${NC}"

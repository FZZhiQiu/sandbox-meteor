#!/bin/bash

# MCP Build Script for Sandbox Radar APK
# Automatically tags, builds via GitHub Actions, and downloads APK

set -e

echo -e "\n🚀 MCP Build Script for Sandbox Radar APK"
echo -e "========================================\n"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub"
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ Error: Not in a git repository or no remote configured"
    exit 1
fi

echo "📦 Repository: $REPO"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Uncommitted changes detected, stashing..."
    git stash push -m "Auto-stashed by MCP build script"
    STASHED=1
fi

# Get current version from app/build.gradle or use timestamp
if [ -f "app/build.gradle" ]; then
    VERSION_CODE=$(grep "versionCode" app/build.gradle | grep -o '[0-9]*' | head -1)
    VERSION_NAME=$(grep "versionName" app/build.gradle | grep -o '"[^"}]"' | tr -d '"')
    if [ -n "$VERSION_NAME" ]; then
        VERSION="v$VERSION_NAME"
    else
        VERSION="v$(date +%Y%m%d-%H%M%S)"
    fi
else
    VERSION="v$(date +%Y%m%d-%H%M%S)"
fi

echo "🏷️  Tagging version: $VERSION"

# Create and push tag
git tag -f "$VERSION"
git push origin "$VERSION"

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to push tag"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

echo "✅ Tag pushed successfully"

# Wait for workflow to start
echo "⏳ Waiting for GitHub Actions workflow to start..."
WORKFLOW_STARTED=0
for i in {1..30}; do
    sleep 2
    WORKFLOW_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status | jq -r '.[0] | select(.status=="queued" or .status=="in_progress") | .databaseId' 2>/dev/null)
    if [ -n "$WORKFLOW_ID" ]; then
        echo "✅ Workflow started with ID: $WORKFLOW_ID"
        WORKFLOW_STARTED=1
        break
    fi
    echo "⏳ Waiting for workflow to start... ($i/30)"
done

if [ "$WORKFLOW_STARTED" = "0" ]; then
    echo "❌ Error: Workflow did not start in time"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

# Monitor workflow progress
echo "🔄 Monitoring workflow progress..."
while true; do
    sleep 10
    WORKFLOW_STATUS=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json status,conclusion | jq -r '.status')
    
    case "$WORKFLOW_STATUS" in
        "completed")
            CONCLUSION=$(gh run view "$WORKFLOW_ID" --repo "$REPO" --json conclusion | jq -r '.conclusion')
            if [ "$CONCLUSION" = "success" ]; then
                echo "✅ Workflow completed successfully"
                break
            else
                echo "❌ Workflow failed with conclusion: $CONCLUSION"
                # Restore stashed changes if any
                if [ "$STASHED" = "1" ]; then
                    git stash pop
                fi
                exit 1
            fi
            ;;
        "in_progress")
            echo "🔄 Workflow in progress..."
            ;;
        "queued")
            echo "⏳ Workflow queued..."
            ;;
        *)
            echo "🔄 Workflow status: $WORKFLOW_STATUS"
            ;;
esac
done

# Download APK
echo "📥 Downloading APK..."
mkdir -p apk

if gh run download "$WORKFLOW_ID" --repo "$REPO" -n sandbox-meteor-apk --dir apk; then
    # Find the APK file
    APK_FILE=$(find apk -name "*.apk" | head -1)
    if [ -n "$APK_FILE" ]; then
        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
        echo -e "\n✅ \033[0;32mAPK downloaded successfully!\033[0m"
        echo -e "\n\033[0;32m📁 APK Path:\033[0m $APK_FILE"
        echo -e "\n\033[0;32m📊 File Size:\033[0m $APK_SIZE"
        echo -e "\n🎉 Build process completed!"
    else
        echo "❌ Error: APK file not found in downloaded artifacts"
        # Restore stashed changes if any
        if [ "$STASHED" = "1" ]; then
            git stash pop
        fi
        exit 1
    fi
else
    echo "❌ Error: Failed to download APK"
    # Restore stashed changes if any
    if [ "$STASHED" = "1" ]; then
        git stash pop
    fi
    exit 1
fi

# Restore stashed changes if any
if [ "$STASHED" = "1" ]; then
    echo "🔄 Restoring stashed changes..."
    git stash pop
fi

echo -e "\n✨ Done!"

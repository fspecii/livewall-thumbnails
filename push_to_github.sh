#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📦 Preparing to push wallpaper database to GitHub...${NC}"

# Check if the JSON file exists
if [ ! -f "wallpapers_database.json" ]; then
    echo -e "${RED}❌ Error: wallpapers_database.json not found!${NC}"
    exit 1
fi

# Validate JSON
echo -e "${YELLOW}🔍 Validating JSON...${NC}"
if python3 -m json.tool wallpapers_database.json > /dev/null 2>&1; then
    echo -e "${GREEN}✅ JSON is valid!${NC}"
else
    echo -e "${RED}❌ Error: Invalid JSON format!${NC}"
    exit 1
fi

# Get statistics
TOTAL=$(python3 -c "import json; data = json.load(open('wallpapers_database.json')); print(len(data['wallpapers']))")
CATEGORIZED=$(python3 -c "import json; data = json.load(open('wallpapers_database.json')); print(len([w for w in data['wallpapers'] if w.get('categories') and len(w['categories']) > 0]))")

echo -e "${GREEN}📊 Statistics:${NC}"
echo -e "   Total wallpapers: ${TOTAL}"
echo -e "   Categorized: ${CATEGORIZED}"
echo -e "   Uncategorized: $((TOTAL - CATEGORIZED))"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}🔧 Initializing git repository...${NC}"
    git init
    git remote add origin https://github.com/yourusername/livewall-database.git
    echo -e "${YELLOW}⚠️  Please update the GitHub repository URL in this script!${NC}"
fi

# Stage and commit changes
echo -e "${YELLOW}📝 Committing changes...${NC}"
git add wallpapers_database.json
git commit -m "Update wallpaper categorization - $(date '+%Y-%m-%d %H:%M:%S')" \
           -m "Total: ${TOTAL} wallpapers, Categorized: ${CATEGORIZED}"

# Push to GitHub
echo -e "${YELLOW}🚀 Pushing to GitHub...${NC}"
read -p "Do you want to push to GitHub? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}❌ Failed to push. Please check your GitHub credentials and repository URL.${NC}"
        echo -e "${YELLOW}💡 Tip: You may need to set up a personal access token for authentication.${NC}"
    fi
else
    echo -e "${YELLOW}⏸️  Push cancelled. Changes are committed locally.${NC}"
fi

echo -e "${GREEN}✨ Done!${NC}"
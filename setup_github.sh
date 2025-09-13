#!/bin/bash

echo "🚀 Setting up GitHub Pages repository using GitHub CLI..."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    echo "Then run: gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Please authenticate with GitHub CLI first:"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is ready!"

# Initialize git repository
echo "📁 Initializing git repository..."
git init

# Add all files
echo "📦 Adding files..."
git add .

# Initial commit
echo "📝 Creating initial commit..."
git commit -m "Initial commit: LiveWall thumbnails and database

- 501 high-quality thumbnail images (400x225px)
- Complete wallpapers database JSON (500 wallpapers)
- Generated from 4K video wallpapers
- Ready for GitHub Pages hosting
- Includes sample HTML index page"

# Create repository on GitHub and push
echo "🌐 Creating GitHub repository and pushing..."
gh repo create livewall-thumbnails --public --source=. --remote=origin --push

# Get GitHub username dynamically
USERNAME=$(gh api user --jq '.login')
echo "👤 GitHub user: $USERNAME"

# Enable GitHub Pages
echo "🔧 Enabling GitHub Pages..."
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$USERNAME/livewall-thumbnails/pages \
  -f source='{"branch":"main","path":"/"}'

echo ""
echo "✅ Repository created and GitHub Pages enabled!"
echo ""
echo "📊 Repository info:"
gh repo view --web &
echo "   Repository: https://github.com/$USERNAME/livewall-thumbnails"
echo "   GitHub Pages: https://$USERNAME.github.io/livewall-thumbnails/"
echo ""
echo "⏳ GitHub Pages deployment usually takes 5-10 minutes."
echo "   Check deployment status: gh run list"
echo ""
echo "🔗 Resources will be available at:"
echo "   Database: https://$USERNAME.github.io/livewall-thumbnails/wallpapers_database.json"
echo "   Thumbnails: https://$USERNAME.github.io/livewall-thumbnails/{id}.jpg"
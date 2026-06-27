#!/bin/bash

echo "🚀 Deploying E-Voting Web to GitHub Pages..."
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Are you in the project root?"
    exit 1
fi

# Build web
echo "📦 Building Flutter Web..."
flutter build web --release --web-renderer html

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build complete!"
echo ""

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "💾 Current branch: $CURRENT_BRANCH"
echo ""

# Checkout or create gh-pages branch
echo "🌿 Switching to gh-pages branch..."
git checkout gh-pages 2>/dev/null || git checkout --orphan gh-pages

if [ $? -ne 0 ]; then
    echo "❌ Failed to checkout gh-pages branch!"
    git checkout $CURRENT_BRANCH
    exit 1
fi

# Clean old files (keep .git)
echo "🧹 Cleaning old files..."
find . -maxdepth 1 ! -name '.git' ! -name 'build' ! -name '.' ! -name '..' -exec rm -rf {} +

# Copy new build
echo "📋 Copying new build files..."
cp -r build/web/* .

# Create .nojekyll file (important for GitHub Pages)
touch .nojekyll

# Commit and push
echo "📤 Committing and pushing to GitHub..."
git add .
git commit -m "Deploy: $(date +%Y-%m-%d\ %H:%M:%S)"

git push -f origin gh-pages

if [ $? -ne 0 ]; then
    echo "❌ Push failed!"
    git checkout $CURRENT_BRANCH
    exit 1
fi

echo "✅ Push complete!"
echo ""

# Back to original branch
echo "🔙 Returning to $CURRENT_BRANCH branch..."
git checkout $CURRENT_BRANCH

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "🌐 Your site will be live at:"
echo "   https://kapingacoder.github.io/e_voting_app/"
echo ""
echo "⏱️  Wait 2-5 minutes for GitHub to process the deployment"
echo ""
echo "📋 Next steps:"
echo "   1. Configure SMTP settings in admin panel"
echo "   2. Test forgot password flow"
echo "   3. Check email for reset link"
echo "   4. Verify web page opens correctly"
echo ""
echo "=========================================="

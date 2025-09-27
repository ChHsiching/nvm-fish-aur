#!/bin/bash
# AUR submission script - nvm-fish v1.2.0

set -e

echo "🚀 Starting nvm-fish submission to AUR..."
echo ""

# Check if in the correct directory
if [[ ! -f "PKGBUILD" ]] || [[ ! -f ".SRCINFO" ]]; then
    echo "❌ Error: Please run this script in the directory containing PKGBUILD and .SRCINFO"
    exit 1
fi

# Test SSH connection
echo "🔑 Testing AUR SSH connection..."
if ssh -T aur@aur.archlinux.org 2>&1 | grep -q "Interactive shell is disabled"; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed. Please check:"
    echo "   1. Whether your SSH public key has been added to your AUR account"
    echo "   2. Whether your AUR account is activated"
    echo "   3. Whether your network connection is working"
    echo ""
    echo "   SSH public key location: ~/.ssh/id_ed25519.pub"
    echo "   AUR account settings: https://aur.archlinux.org/account/"
    exit 1
fi

# Show the content to be submitted
echo ""
echo "📦 Package to be submitted:"
echo "   Name: nvm-fish"
echo "   Version: 1.2.0-1"
echo "   Maintainer: ChHsich <hsichingchang@gmail.com>"
echo ""

# Confirm submission
read -p "Confirm submission to AUR? [y/N]: " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "❌ Submission cancelled"
    exit 0
fi

# Push to AUR
echo ""
echo "📤 Pushing to AUR..."
git push -u origin main

echo ""
echo "🎉 Successfully submitted to AUR!"
echo ""
echo "📋 Next steps:"
echo "   1. Visit: https://aur.archlinux.org/packages/nvm-fish"
echo "   2. Verify the package information is correct"
echo "   3. Test user installation: yay -S nvm-fish"
echo ""
echo "✅ nvm-fish is now available on AUR!"
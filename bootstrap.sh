#!/bin/sh
# set -euo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

echo "🔜 Check & Install dependencies..."

if which -a brew > /dev/null; then
    echo "🟢 Homebrew installed. Skipping install"
else
    echo "🔴 Homebrew not installed. Start install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if which -a mint > /dev/null; then
    echo "🟢 Mint installed. Skipping install"
else
    echo "🔴 Mint not installed. Start install"
    brew install mint
fi

mint bootstrap --mintfile ./Utilites/Mintfile 
echo "✅ Dependencies succesfully installed"

echo "🚀 Running SwiftFormat"
mint run swiftformat@0.51.11 . --config .swiftformat

echo "🚀 Running SwiftGen"
mint run swiftgen@6.5.1 config run --config swiftgen.yml 

echo "Bootstrap competed 🎉"

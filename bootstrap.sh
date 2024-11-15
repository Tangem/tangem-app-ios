#!/bin/sh
# set -euo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

# Parse options

usage() {
	echo "Usage: $0 [additional options]"
	echo
	echo "  Options:"
	echo
	echo "    --skip-cocoapods        -  Skip pod install"
	echo "    --update-submodule      -  Git submodule update with --remote option"
	exit 1;
}

OPT_COCOAPODS=true
OPT_SUBMODULE=false

while test $# -gt 0
do
    case "$1" in
        --skip-cocoapods)
			OPT_COCOAPODS=false
            ;;
        --update-submodule)
			OPT_SUBMODULE=true
            ;;
        *)
		usage 1>&2
        ;;
    esac
    shift
done

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

if which -a xcodes > /dev/null; then
    echo "🟢 Xcodes installed. Skipping install"
else
    echo "🔴 Xcodes not installed. Start install"
    brew install xcodes
fi

if [ "${CI}" = true ] ; then
    MINTFILE="./Utilites/Mintfile@ci"
else
    MINTFILE="./Utilites/Mintfile@local"
fi

echo "🔄 Mint bootstrap dependencies"
mint bootstrap --mintfile ${MINTFILE}
echo "✅ Dependencies succesfully installed"

if [ "${CI}" = true ] ; then
    echo "ℹ️ Skipping SwiftFormat"
else
    echo "🚀 Running SwiftFormat"
    mint run swiftformat@0.52.8 . --config .swiftformat
fi

echo "🚀 Running SwiftGen"
mint run swiftgen@6.6.2 config run --config swiftgen.yml 

if [ "$OPT_COCOAPODS" = true ] ; then
    echo "🚀 Running pod install"
	pod install --repo-update 
fi

if [ "$OPT_SUBMODULE" = true ] ; then
    echo "🚀 Running submodule remote update"
    git submodule update --remote
fi

echo "Bootstrap competed 🎉"

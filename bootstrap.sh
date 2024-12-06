#!/bin/sh

set -eo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

usage() {
	echo "Usage: $0 [additional options]"
	echo
	echo "  Options:"
	echo
	echo "    --skip-cocoapods        -  Skip pod install"
	echo "    --skip-ruby             -  Skip Ruby install"
	echo "    --update-submodule      -  Git submodule update with --remote option"
	exit 1;
}

OPT_COCOAPODS=true
OPT_RUBY=true
OPT_SUBMODULE=false

while test $# -gt 0
do
    case "$1" in
        --skip-cocoapods)
			OPT_COCOAPODS=false
            ;;
        --skip-ruby)
            OPT_RUBY=false
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

if [ "${CI}" = true ] ; then
    MINTFILE="./Utilites/Mintfile@ci"
    BREWFILE="./Utilites/Brewfile@ci"
else
    MINTFILE="./Utilites/Mintfile@local"
    BREWFILE="./Utilites/Brewfile@local"
fi

echo "🔄 Installing required Homebrew dependencies"
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file=${BREWFILE}
echo "✅ Required Homebrew dependencies succesfully installed"

if [ "$OPT_RUBY" = true ] ; then
    echo "🛠️ Installing Ruby version from '.ruby-version' file..."
    eval "$(rbenv init - bash)"
    RUBY_VERSION=$(cat .ruby-version)
    rbenv install "$RUBY_VERSION" --skip-existing
    rbenv local "$RUBY_VERSION"
    rbenv rehash
    echo "✅ Ruby version ${RUBY_VERSION} from '.ruby-version' file succesfully installed"
fi

echo "🔄 Installing required Ruby gems"
gem install bundler
bundle install
echo "✅ Required Ruby gems succesfully installed"

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
	bundle exec pod install --repo-update 
fi

if [ "$OPT_SUBMODULE" = true ] ; then
    echo "🚀 Running submodule remote update"
    git submodule update --remote
fi

echo "Bootstrap competed 🎉"

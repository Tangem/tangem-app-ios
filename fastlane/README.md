fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### test

```sh
[bundle exec] fastlane test
```


A lane that builds and tests the scheme "Tangem" using a clean and build application.
Using enviroment: Production
Options:
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)


### test_modules

```sh
[bundle exec] fastlane test_modules
```


A lane that builds and tests SPM modules located in the "Modules" folder.
A separate lane is needed since it's still not possible to run unit tests from remove/local SPM dependencies inside the host app,
see https://forums.swift.org/t/running-swiftpm-tests-inside-project/62760 for details.
Options:
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)


### release

```sh
[bundle exec] fastlane release
```


A lane that builds a "Tangem" scheme and uploads the archive to TestFlight for release.
Using enviroment: Production
Options:
- version: app version
- build: optional build number
- changelog: string for description archive
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)
- analyze_archive: boolean to determine whether to analyze the archive during the build process (default: false)


### check_bsdk_example_buildable

```sh
[bundle exec] fastlane check_bsdk_example_buildable
```


A lane that builds a "BlockchainSdkExample" scheme without running or publishing it, just to check that the scheme is buildable.


### build_Alpha

```sh
[bundle exec] fastlane build_Alpha
```


This lane builds a "Tangem Alpha" scheme binary. Result binary can be used only for ad-hoc distribution.
Options:
- version: App version
- build: Build number
- filename: Name of the resulting artefact (IPA file)
- path: Path to binary
- firebase_app_id: Firebase app id for incrementing the build version number and DSYM uploads
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)
- analyze_archive: boolean to determine whether to analyze the archive during the build process (default: false)


### build_Beta

```sh
[bundle exec] fastlane build_Beta
```


A lane that builds a "Tangem Beta" scheme binary. Result binary can be used only for ad-hoc distribution.
Options:
- version: App version
- build: Build number
- filename: Name of the resulting artefact (IPA file)
- path: Path to binary
- firebase_app_id: Firebase app id for incrementing the build version number and DSYM uploads
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)
- analyze_archive: boolean to determine whether to analyze the archive during the build process (default: false)


### build_RC

```sh
[bundle exec] fastlane build_RC
```


A lane that builds a "Tangem" scheme and uploads the archive to TestFlight for release.
Using enviroment: Production
Options:
- version: app version
- build: optional build number
- filename: Name of the resulting artefact (IPA file)
- path: Path to binary
- firebase_app_id: Firebase app id for DSYM uploads
- xcode_version_override: Xcode version to use, optional (uses https://github.com/XcodesOrg/xcodes under the hood)
- analyze_archive: boolean to determine whether to analyze the archive during the build process (default: false)


### get_release_version_number

```sh
[bundle exec] fastlane get_release_version_number
```


A lane that creates the build version for the release using either user input or a branch name.
Options:
- build_version_override: Optional build version override (user input)
- branch_name: Source branch name


### get_release_build_number

```sh
[bundle exec] fastlane get_release_build_number
```


A lane that creates the build number for the release using either user input or information from App Store Connect API.
Options:
- build_number_override: Optional build number override (user input)
- asc_key_id: App Store Connect API Key ID
- asc_issuer_id: App Store Connect API Key Issuer ID
- asc_key: App Store Connect API Key (NOT in the base64 format)


### refresh_dsyms

```sh
[bundle exec] fastlane refresh_dsyms
```


Load from testFlight dSyms and upload it to Firebase
Options:
- version: app version
- build: build number


### update_translations

```sh
[bundle exec] fastlane update_translations
```


Fetches and updates localization bundles using Localise fastlane action (https://github.com/lokalise/lokalise-fastlane-actions).
Uses `LOKALISE_API_TOKEN` and `LOKALISE_PROJECT_ID` env vars.
Options:
- languages: A comma-delimited string of languages to update, like `en,fr,de,ja,ru,es,uk_UA`. Pass an empty string to update all available languages.
- destination: A file path to save localization files to.


### deploy_firebase

```sh
[bundle exec] fastlane deploy_firebase
```


This lane deploy binary to Google Distribution
Options:
- app_id: Firebase App ID
- path: Path to binary
- firebase_token: Firebase CLI Token
- changelog: [optional] Changelog will be added to Google Distribution release notes along with the last commit hash.


### deploy_testflight

```sh
[bundle exec] fastlane deploy_testflight
```


This lane deploy binary to TestFLight
Options:
- asc_key_id: App Store Connect API Key ID
- asc_issuer_id: App Store Connect API Key Issuer ID
- asc_key: App Store Connect API Key (NOT in the base64 format)
- path: Path to binary
- version: app version
- build: build number
- changelog: [optional] Changelog will be added to TestFlight release notes along with the last commit hash.


----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

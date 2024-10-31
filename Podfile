# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

# Debug Xcode configurations
debug_configuration = 'Debug(production)'
debug_alpha_configuration = 'Debug(alpha)'
debug_beta_configuration = 'Debug(beta)'

# Release Xcode configurations
release_configuration = 'Release(production)'
release_alpha_configuration = 'Release(alpha)'
release_beta_configuration = 'Release(beta)'

project 'TangemApp.xcodeproj',
  debug_configuration => :debug,
  debug_alpha_configuration => :debug,
  debug_beta_configuration => :debug,
  release_configuration => :release,
  release_alpha_configuration => :release,
  release_beta_configuration => :release

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!
inhibit_all_warnings!

def tangem_sdk_pod
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-313'
  #pod 'TangemSdk', :path => '../tangem-sdk-ios'
end

def blockchain_sdk_pods
  # 'TangemWalletCore' dependency must be added via SPM

  pod 'BlockchainSdk', :git => 'https://github.com/tangem/blockchain-sdk-swift.git', :tag => 'develop-707'
  #pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'

  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :tag => '1.2.0-tangem11'
  #pod 'Solana.Swift', :path => '../Solana.Swift'

  pod 'BinanceChain', :git => 'https://github.com/tangem/swiftbinancechain.git', :tag => '0.0.11'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/tangem/bitcoincore.git', :tag => '0.0.20'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'

  pod 'SwiftyJSON', :git => 'https://github.com/tangem/SwiftyJSON.git', :tag => '5.0.1-tangem1'
end

target 'Tangem' do
  blockchain_sdk_pods
  tangem_sdk_pod
  
  # Pods for Tangem
  pod 'Moya'
  pod 'WalletConnectSwiftV2', :git => 'https://github.com/WalletConnect/WalletConnectSwiftV2', :tag => '1.18.7'
  pod 'Kingfisher', '~> 7.11.0'
  pod 'TonSwift', :git => 'https://github.com/tangem/ton-swift.git', :tag => '1.0.10-tangem1'

  # Helpers
  pod 'BlockiesSwift', '~> 0.1.2'
  pod 'CombineExt', '~> 1.8.0'

  # Debug and development pods
  pod 'GDPerformanceView-Swift', '~> 2.1', :configurations => [
    debug_configuration,
    debug_alpha_configuration,
    debug_beta_configuration,
    release_alpha_configuration,
    release_beta_configuration,
  ]

  # Support chat
  #pod 'SPRMessengerClient', :git => 'https://github.com/tangem/SPRMessengerClient-binaries-ios.git', :tag => 'sprinklr-3.6.2-tangem1'
  
  # Analytics
  pod 'AmplitudeSwift', '1.6.2'
  pod 'Firebase/Crashlytics', '10.29.0'
  pod 'Firebase/Analytics', '10.29.0'

  # Push notifications
  pod 'Firebase/Messaging', '10.29.0'

  target 'TangemTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TangemUITests' do
    # Pods for testing
  end
end

target 'TangemExpress' do 
  blockchain_sdk_pods
  pod 'Moya'

  target 'TangemExpressTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'TangemVisa' do
  blockchain_sdk_pods
  pod 'Moya'

  target 'TangemVisaTests' do
    blockchain_sdk_pods
  end
end

target 'TangemStaking' do
  blockchain_sdk_pods
  pod 'Moya'

  target 'TangemStakingTests' do
    inherit! :search_paths
  end
end

target 'TangemFoundation' do
  pod 'Moya'

  target 'TangemFoundationTests' do
    inherit! :search_paths
  end
end

pre_install do |installer|
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    if config.name.downcase.include?("debug")
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      config.build_settings['SWIFT_COMPILATION_MODE'] = 'Incremental'
    end

    # Fix warnings on Xcode 15 https://indiestack.com/2023/10/xcode-15-duplicate-library-linker-warnings/
    config.build_settings['OTHER_LDFLAGS'] ||= ['$(inherited)']
    config.build_settings['OTHER_LDFLAGS'] << '-Wl,-no_warn_duplicate_libraries'
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end

      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end

  # ============ SPM <-> CocoaPods interop ============

  # `Hedera` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
    installer.pods_project,
    "BlockchainSdk",
    "https://github.com/tangem/hedera-sdk-swift.git",
    "Hedera",
    { :kind => "exactVersion", :version => "0.26.0-tangem3" }
  )

  # `CryptoSwift` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
    installer.pods_project,
    "BlockchainSdk",
    "https://github.com/krzyzanowskim/CryptoSwift.git",
    "CryptoSwift",
    { :kind => "upToNextMajorVersion", :minimumVersion => "1.8.0" }
  )

  # `Wallet Core binaries` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
    installer.pods_project,
    "BlockchainSdk",
    "https://github.com/tangem/wallet-core-binaries-ios.git",
    "TangemWalletCoreBinariesWrapper",
    { :kind => "exactVersion", :version => "4.0.46-tangem1" }
  )

  # `SwiftProtobuf` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BlockchainSdk",
   "https://github.com/tangem/swift-protobuf-binaries.git",
   "SwiftProtobuf",
   { :kind => "exactVersion", :version => "1.25.2-tangem1" }
  )
  
  # `TonSwift` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BlockchainSdk",
   "https://github.com/tangem/ton-swift.git",
   "TonSwift",
   { :kind => "exactVersion", :version => "1.0.10-tangem3" }
  )
  
  # `ScaleCodec` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BlockchainSdk",
   "https://github.com/tesseract-one/ScaleCodec.swift",
   "ScaleCodec",
   { :kind => "exactVersion", :version => "0.2.1" }
  )

  # `IcpKit` SPM package for `BlockchainSdk` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BlockchainSdk",
   "https://github.com/tangem/IcpKit.git",
   "IcpKit",
   { :kind => "exactVersion", :version => "0.1.2-tangem4" }
  )

  # `SwiftProtobuf` SPM package for `BinanceChain` pod
  add_spm_package_to_target(
   installer.pods_project,
   "BinanceChain",
   "https://github.com/tangem/swift-protobuf-binaries.git",
   "SwiftProtobuf",
   { :kind => "exactVersion", :version => "1.25.2-tangem1" }
  )

  # `secp256k1.swift` SPM package for `Solana.Swift` pod
  add_spm_package_to_target(
   installer.pods_project,
   "Solana.Swift",
   "https://github.com/GigaBitcoin/secp256k1.swift.git",
   "secp256k1",
   { :kind => "upToNextMinorVersion", :minimumVersion => "0.12.0" }
  )
  
  # `TweetNacl` SPM package for `Solana.Swift` pod
  add_spm_package_to_target(
   installer.pods_project,
   "Solana.Swift",
   "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git",
   "TweetNacl",
   { :kind => "exactVersion", :version => "1.1.0" }
  )

end

# Adds given SPM package as a dependency to a specific target in the `Pods` project.
# TODO: Extract this logic to a dedicated CocoaPods plugin (IOS-5855)
#
# Valid values for the `requirement` parameter are:
# - `{ :kind => "upToNextMajorVersion", :minimumVersion => "1.0.0" }`
# - `{ :kind => "upToNextMinorVersion", :minimumVersion => "1.0.0" }`
# - `{ :kind => "exactVersion", :version => "1.0.0" }`
# - `{ :kind => "versionRange", :minimumVersion => "1.0.0", :maximumVersion => "2.0.0" }`
# - `{ :kind => "branch", :branch => "some-feature-branch" }`
# - `{ :kind => "revision", :revision => "4a9b230f2b18e1798abbba2488293844bf62b33f" }`
def add_spm_package_to_target(project, target_name, url, product_name, requirement)
  project.targets.each do |target|
    if target.name == target_name
      pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
      pkg.repositoryURL = url
      pkg.requirement = requirement
      ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      ref.package = pkg
      ref.product_name = product_name
      target.package_product_dependencies << ref

      project_already_has_this_pkg = false

      project.root_object.package_references.each do |existing_ref|
        if existing_ref.display_name.downcase.eql?(url.downcase)
          project_already_has_this_pkg = true
          break
        end
      end

      unless project_already_has_this_pkg
        project.root_object.package_references << pkg
      end

      target.build_configurations.each do |config|
        config.build_settings['SWIFT_INCLUDE_PATHS'] = '$(inherited) ${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)'
      end
    end
  end

  project.save
end

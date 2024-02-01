# Uncomment the next line to define a global platform for your project
platform :ios, '14.5'

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
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-280'
  #pod 'TangemSdk', :path => '../tangem-sdk-ios'
end

def blockchain_sdk_pods
  pod 'BlockchainSdk', :git => 'https://github.com/tangem/blockchain-sdk-swift.git', :tag => 'develop-471'
  #pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'

  pod 'TangemWalletCore', :git => 'https://github.com/tangem/wallet-core-binaries-ios.git', :tag => '3.2.4-tangem1'
  #pod 'TangemWalletCore', :path => '../wallet-core-binaries-ios'

  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :tag => 'add-external-signer-11'
  #pod 'Solana.Swift', :path => '../Solana.Swift'

  pod 'BinanceChain', :git => 'https://github.com/tangem/swiftbinancechain.git', :tag => '0.0.10'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/tangem/bitcoincore.git', :tag => '0.0.19'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

target 'Tangem' do
  blockchain_sdk_pods
  tangem_sdk_pod
  
  # Pods for Tangem
  pod 'Moya'
  pod 'WalletConnectSwiftV2', :git => 'https://github.com/WalletConnect/WalletConnectSwiftV2', :tag => '1.8.4'
  pod 'Kingfisher', '~> 7.9.0'

  # Helpers
  pod 'AlertToast', :git => 'https://github.com/elai950/AlertToast', :commit => 'a437862bb6605080a5816e866cbd4ac8c8657b49'
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

  # support chat
  pod 'SPRMessengerClient', :git => 'https://github.com/tangem/SPRMessengerClient-binaries-ios.git', :tag => 'sprinklr-3.6.2-tangem1'
  
  # Analytics
  pod 'Amplitude'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'AppsFlyerFramework'
  
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

pre_install do |installer|
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    if config.name.include?("Debug")
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      config.build_settings['SWIFT_COMPILATION_MODE'] = 'Incremental'
    end

    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['OTHER_LDFLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_LDFLAGS'] << '-Wl,-no_warn_duplicate_libraries' #https://indiestack.com/2023/10/xcode-15-duplicate-library-linker-warnings/
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end

    # Exporting SwiftProtobuf library symbols for WalletCore binaries 
    if target.name.downcase.include?('swiftprotobuf')
      target.build_configurations.each do |config|
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end

end

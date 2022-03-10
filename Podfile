# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
project 'TangemApp.xcodeproj'

def common_pods
   pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-136'
   #pod 'TangemSdk', :path => '../tangem-sdk-ios'
   pod 'KeychainSwift', '~> 19.0'
end


target 'Tangem' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  common_pods
  
  # Pods for Tangem
  pod 'AnyCodable-FlightSchool'
  
  pod 'BinanceChain', :git => 'https://github.com/lazutkin-andrey/swiftbinancechain.git', :tag => '0.0.9'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  
  pod 'HDWalletKit', :git => 'https://github.com/lazutkin-andrey/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
  
  pod 'BlockchainSdk', :git => 'https://github.com/Tangem/blockchain-sdk-swift.git', :tag => 'develop-86_hotfix_1'
  #pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'
  
  pod 'web3swift', :git => 'https://github.com/lazutkin-andrey/web3swift.git', :tag => '2.2.8'
  #pod 'web3swift', :path => '../web3swift'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/lazutkin-andrey/bitcoincore.git', :tag => '0.0.15'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'

  pod 'WalletConnectSwift', :git => 'https://github.com/WalletConnect/WalletConnectSwift', :tag => '1.6.2'
  pod 'Starscream', '~> 4.0.4'
  pod 'Moya'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
	pod 'Firebase/RemoteConfig'
  pod 'DeviceGuru'
  pod 'Kingfisher', :git => 'https://github.com/onevcat/Kingfisher.git', :branch => 'version6-xcode13'
  pod 'stellar-ios-mac-sdk'
  pod 'AppsFlyerFramework'
  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :tag => 'add-external-signer-1'
  # pod 'Solana.Swift', :path => '../Solana.Swift'
  pod 'ScaleCodec'
  pod 'Mobile-Buy-SDK' # Shopify

  target 'TangemTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TangemUITests' do
    # Pods for testing
  end

end

target 'TangemClip' do
  use_frameworks!
  inhibit_all_warnings!

  common_pods
  
  pod 'BigInt'
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'Moya'
  pod 'Sodium'
  pod 'SwiftCBOR'
  pod 'AnyCodable-FlightSchool'
  
end

pre_install do |installer|
    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
			end
		end
	end
end

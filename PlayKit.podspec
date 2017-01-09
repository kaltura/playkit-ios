Pod::Spec.new do |s|
s.name             = 'PlayKit'
s.version          = '0.1.4'
s.summary          = 'A short description of PlayKit.'


s.homepage         = 'https://github.com/kaltura/playkit-ios'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Rivka Schwartz' => 'Rivka.Peleg@kaltura.com', 'Vadim Kononov' => 'vadim.kononov@kaltura.com', 'Eliza Sapir' => 'eliza.sapir@kaltura.com', 'Noam Tamim' => 'noam.tamim@kaltura.com' }
s.source           = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => 'v' + s.version.to_s }

s.ios.deployment_target = '8.0'

s.source_files = 'Classes/**/*'
s.dependency 'SwiftyJSON'
s.dependency 'Log'
s.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleInteractiveMediaAds"',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }

s.subspec 'IMAPlugin' do |ssp|
    ssp.source_files = 'Plugins/IMA'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleInteractiveMediaAds"',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
    #ssp.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.3'
end

s.subspec 'GoogleCastAddon' do |ssp|
    ssp.source_files = 'Addons/GoogleCast'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleCast"',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
    ssp.dependency 'google-cast-sdk'
end

s.subspec 'YouboraPlugin' do |ssp|
    ssp.source_files = 'Plugins/Youbora'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -framework "YouboraLib" -framework "YouboraPluginAVPlayer"',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
    ssp.dependency 'Youbora-AVPlayer/dynamic'
end

s.subspec 'WidevineClassic' do |ssp|
  ssp.source_files = 'Widevine'
  ssp.dependency 'PlayKitWV'
  ssp.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO', 'GCC_PREPROCESSOR_DEFINITIONS'=>'WIDEVINE_ENABLED=1' }
end

s.subspec 'PhoenixPlugin' do |ssp|
    ssp.source_files = 'Plugins/Phoenix'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited)',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
end

s.subspec 'KalturaStatsPlugin' do |ssp|
    ssp.source_files = 'Plugins/KalturaStats'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited)',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
'   LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
end

s.subspec 'KalturaLiveStatsPlugin' do |ssp|
ssp.source_files = 'Plugins/KalturaLiveStats'
ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
'OTHER_LDFLAGS' => '$(inherited)',
'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
'   LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
end

s.subspec 'Lite' do |lite|
  # subspec for users who don't want the third party PayPal 
  # & Stripe bloat
  end
   
   s.default_subspec = 'Lite'

end

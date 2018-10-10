Pod::Spec.new do |s|

s.name              = 'PlayKit'
s.version           = '3.6.x-dev'
s.summary           = 'PlayKit: Kaltura Mobile Player SDK - iOS'
s.homepage          = 'https://github.com/kaltura/playkit-ios'
s.license           = { :type => 'AGPLv3', :text => 'AGPLv3' }
s.author            = { 'Kaltura' => 'community@kaltura.com' }
s.source            = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => 'v' + s.version.to_s }
s.swift_version     = '4.0'

s.ios.deployment_target = '8.0'
s.tvos.deployment_target = '9.0'

s.subspec 'Core' do |sp|
    sp.source_files = 'Classes/**/*'
    sp.dependency 'SwiftyJSON', '3.1.4'
    sp.dependency 'XCGLogger', '~> 6.1.0'
    sp.dependency 'SwiftyXMLParser', '3.0.3'
    sp.dependency 'KalturaNetKit', '~> 0.0'
    sp.dependency 'PlayKitUtils', '0.1.4'
end

s.subspec 'GoogleCastAddon' do |ssp|
    ssp.ios.deployment_target = '8.0'
    ssp.source_files = 'Addons/GoogleCast'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleCast"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'google-cast-sdk', '3.5'
    ssp.dependency 'PlayKit/Core'
end

s.subspec 'YouboraPlugin' do |ssp|
    ssp.source_files = 'Plugins/Youbora'
    ssp.dependency 'Youbora-AVPlayer/dynamic', '5.4.18'
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'PlayKit/AnalyticsCommon'
end

s.subspec 'WidevineClassic' do |ssp|
  ssp.ios.deployment_target = '8.0'  
  ssp.source_files = 'Widevine'
  ssp.dependency 'PlayKit/Core'
  #ssp.dependency 'PlayKitWV'
  #ssp.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO', 'GCC_PREPROCESSOR_DEFINITIONS'=>'WIDEVINE_ENABLED=1',
   #                           'OTHER_SWIFT_FLAGS' => '$(inherited) -DWIDEVINE_ENABLED' }
end

s.subspec 'PhoenixPlugin' do |ssp|
    ssp.source_files = 'Plugins/Phoenix'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited)',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**'
    }
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'PlayKit/AnalyticsCommon'
end

s.subspec 'KalturaStatsPlugin' do |ssp|
    ssp.source_files = 'Plugins/KalturaStats'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited)',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'PlayKit/AnalyticsCommon'
end

s.subspec 'KalturaLiveStatsPlugin' do |ssp|
    ssp.source_files = 'Plugins/KalturaLiveStats'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited)',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'PlayKit/AnalyticsCommon'
end

s.subspec 'AnalyticsCommon' do |ssp|
    ssp.source_files = 'Plugins/AnalyticsCommon'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited)',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**'
    }
    ssp.dependency 'PlayKit/Core'
end

s.default_subspec = 'Core'

end

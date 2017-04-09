Pod::Spec.new do |s|
s.name             = 'PlayKit'
s.version          = '0.1.29'
s.summary          = 'PlayKit: Kaltura Mobile Player SDK - iOS'


s.homepage         = 'https://github.com/kaltura/playkit-ios'
s.license          = { :type => 'AGPLv3', :text => 'AGPLv3' }
s.author           = { 'Kaltura' => 'community@kaltura.com' }
s.source           = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => 'v' + s.version.to_s }

s.ios.deployment_target = '8.0'

s.subspec 'Core' do |sp|
    sp.source_files = 'Classes/**/*'
    sp.dependency 'SwiftyJSON'
    sp.dependency 'Log'
    sp.dependency 'SwiftyXMLParser'
end

s.subspec 'IMAPlugin' do |ssp|
    ssp.source_files = 'Plugins/IMA'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleInteractiveMediaAds"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'GoogleAds-IMA-iOS-SDK', '3.4.1'
end

s.subspec 'GoogleCastAddon' do |ssp|
    ssp.source_files = 'Addons/GoogleCast'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleCast"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'google-cast-sdk'
    ssp.dependency 'PlayKit/Core'
end

s.subspec 'YouboraPlugin' do |ssp|
    ssp.source_files = 'Plugins/Youbora'
    ssp.xcconfig = { 
        'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
        'OTHER_LDFLAGS' => '$(inherited) -framework "YouboraLib" -framework "YouboraPluginAVPlayer"',
        'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
        'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' 
    }
    ssp.dependency 'Youbora-AVPlayer/dynamic'
    ssp.dependency 'PlayKit/Core'
    ssp.dependency 'PlayKit/AnalyticsCommon'
end

s.subspec 'WidevineClassic' do |ssp|
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

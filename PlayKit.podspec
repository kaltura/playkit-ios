suffix = '.0000'   # Dev mode
# suffix = ''       # Release

Pod::Spec.new do |s|

s.name              = 'PlayKit'
s.version           = '3.26.1' + suffix
s.summary           = 'PlayKit: Kaltura Mobile Player SDK - iOS'
s.homepage          = 'https://github.com/kaltura/playkit-ios'
s.license           = { :type => 'AGPLv3', :text => 'AGPLv3' }
s.author            = { 'Kaltura' => 'community@kaltura.com' }
s.source            = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => 'v' + s.version.to_s }
s.swift_version     = '5.0'

s.ios.deployment_target = '9.0'
s.tvos.deployment_target = '9.0'

s.subspec 'Core' do |sp|
    sp.source_files = 'Classes/**/*'
    sp.dependency 'SwiftyJSON', '5.0.0'
    sp.dependency 'XCGLogger', '7.0.0'
    sp.dependency 'KalturaNetKit', '~> 1.5.1'
    sp.dependency 'PlayKitUtils', '~> 0.5'
end

s.subspec 'WidevineClassic' do |ssp|
  ssp.ios.deployment_target = '9.0'  
  ssp.source_files = 'Widevine'
  ssp.dependency 'PlayKit/Core'
  #ssp.dependency 'PlayKitWV'
  #ssp.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO', 'GCC_PREPROCESSOR_DEFINITIONS'=>'WIDEVINE_ENABLED=1',
   #                           'OTHER_SWIFT_FLAGS' => '$(inherited) -DWIDEVINE_ENABLED' }
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

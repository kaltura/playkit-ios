Pod::Spec.new do |s|
s.name             = 'PlayKit'
s.version          = '0.0.1'
s.summary          = 'A short description of PlayKit.'


s.homepage         = 'https://github.com/kaltura/playkit-ios'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Rivka Schwartz' => 'Rivka.Peleg@kaltura.com', 'Vadim Kononov' => 'vadim.kononov@kaltura.com', 'Eliza Sapir' => 'eliza.sapir@kaltura.com', 'Noam Tamim' => 'noam.tamim@kaltura.com' }
s.source           = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => s.version.to_s }

s.ios.deployment_target = '8.0'

s.subspec 'Core' do |sp|
    sp.source_files = 'Classes/**/*'
    sp.dependency 'SwiftyJSON'
    sp.dependency 'Log'
end

s.subspec 'SamplePlugin' do |ssp|
    ssp.source_files = 'Plugins/Sample'
end

s.subspec 'IMAPlugin' do |ssp|
    ssp.source_files = 'Plugins/IMA'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited) -framework "GoogleInteractiveMediaAds"',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
    ssp.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.3'
end

s.subspec 'YouboraPlugin' do |ssp|
    ssp.source_files = 'Plugins/Youbora'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -framework "YouboraLib" -framework "YouboraPluginAVPlayer"',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
    ssp.dependency 'Youbora-AVPlayer'
end

s.subspec 'PhoenixPlugin' do |ssp|
    ssp.source_files = 'Plugins/Phoenix'
    ssp.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited)',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**' }
end

s.default_subspec = 'Core'

end

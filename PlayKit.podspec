#
# Be sure to run `pod lib lint PlayKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PlayKit'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PlayKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/kaltura/playkit-ios'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Rivka Schwartz' => 'Rivka.Peleg@kaltura.com' }
  s.source           = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  # s.source_files = 'Classes/**/*'
  # s.source_files += 'PlayKit/Plugins/**/*'
  # s.source_files += 'PlayKit/Addons/**/*'
  
  # s.resource_bundles = {
  #   'PlayKit' => ['PlayKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'


s.dependency 'SwiftyJSON'


s.subspec 'Core' do |sp|
  sp.source_files = 'Classes/**/*'
end

  s.subspec 'SamplePlugin' do |ssp|
    ssp.source_files = 'Plugins/Sample'
  end

  s.subspec 'IMAPlugin' do |ssp|
    ssp.source_files = 'Plugins/IMA'
  end

s.default_subspec = 'Core'

end

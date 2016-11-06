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
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Noam Tamim' => 'noam.tamim@kaltura.com', "Eliza Sapir" => "eliza.sapir@gmail.com" }
  s.source           = { :git => 'https://github.com/kaltura/playkit-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
 
  # s.resource_bundles = {
  #   'PlayKit' => ['PlayKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

    s.subspec 'Core' do |sp|
      sp.source_files = 'PlayKit/**/*'
    end

    #s.subspec 'GoogleCast' do |sp|
     # sp.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS'=>'GOOGLE_CAST_ENABLED=1' }
     # sp.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.3'
    # end
end

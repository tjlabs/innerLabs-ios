#
# Be sure to run `pod lib lint JupiterSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JupiterSDK'
  s.version          = '1.0.4'
  s.summary          = 'JupiterSDK for iOS'
  s.swift_version    = '4.0'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  
  s.ios.deployment_target = '13.2'
  
  s.homepage         = 'https://www.tjlabscorp.com'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'TJLABS Corp', :file => 'LICENSE' }
  s.author           = { 'Leo' => 'leo.shin@tjlabscorp.com' }
  s.source           = { :git => 'https://github.com/tjlabs/jupiter-ios.git', :tag => s.version.to_s }
  
  s.source_files = 'JupiterSDK/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JupiterSDK' => ['JupiterSDK/Assets/*.png']
  # }
  
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.static_framework = true
#  s.dependency 'Alamofire', '~> 5.2'
#  s.dependency 'Charts', '~> 4.0.0'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Firestore'
#  s.dependency 'Firebase/Analytics'

end

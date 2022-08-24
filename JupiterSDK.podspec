#
# Be sure to run `pod lib lint JupiterSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JupiterSDK'
  s.version          = '1.6.8'
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
  
  s.ios.deployment_target = '13.0'
  
  s.homepage         = 'https://www.tjlabscorp.com'
  s.license          = { :type => 'TJLABS Corp', :file => 'LICENSE' }
  s.author           = { 'Leo' => 'leo.shin@tjlabscorp.com' }
  s.source           = { :git => 'https://github.com/tjlabs/jupiter-ios.git', :tag => s.version.to_s }
  
  s.source_files = 'JupiterSDK/Classes/**/*'
  
  s.resource_bundles = {
     'JupiterSDK' => ['JupiterSDK/Assets/*.tflite']
  }
   
  s.pod_target_xcconfig = {
       'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.static_framework = true
  s.dependency 'Alamofire'
#  s.dependency 'FirebaseMLModelDownloader', '9.4.0-beta'
#  s.dependency 'TensorFlowLiteSwift'

#  s.dependency 'FirebaseMLCommon'
  s.dependency 'Firebase/MLModelInterpreter', '6.25.0'
  
end

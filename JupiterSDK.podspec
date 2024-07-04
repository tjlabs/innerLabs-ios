Pod::Spec.new do |s|
  s.name             = 'JupiterSDK'
  s.version          = '3.4.5'
  s.summary          = 'JupiterSDK for iOS'
  s.swift_version    = '5.0'
  
  
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  
  s.ios.deployment_target = '15.0'
  
  s.homepage         = 'https://www.tjlabscorp.com'
  s.license          = { :type => 'TJLABS Corp', :file => 'LICENSE' }
  s.author           = { 'Leo' => 'leo.shin@tjlabscorp.com' }
  s.source           = { :git => 'https://github.com/tjlabs/jupiter-ios.git', :tag => s.version.to_s }
  
  s.source_files = 'JupiterSDK/Classes/**/*'

  s.static_framework = true
  
end

#
# Be sure to run `pod lib lint ImageRecognition.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ImageRecognition'
  s.version          = '0.1.0'
  s.summary          = 'Image Recognition.'
  s.description      = 'ImageRecognition is an object and face detection library.'
  s.homepage         = 'https://github.com/stingle/image-recognition-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Stingle'
  s.source           = { :git => 'https://github.com/stingle/image-recognition-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'

  s.cocoapods_version = '>= 1.4.0'
  
  s.source_files = 'ImageRecognition/Classes/**/*'

end

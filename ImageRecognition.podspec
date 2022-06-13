#
#  Be sure to run `pod spec lint ImageRecognition.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "ImageRecognition"
  spec.version      = "0.2.1"
  spec.summary      = "A library to recognize objects and faces from image and video"

  spec.homepage     = 'https://github.com/stingle/image-recognition-ios'
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = "Stingle"
  spec.platform     = :ios, "14.0"
  spec.swift_version = '5.0'
  spec.ios.deployment_target = "14.0"

  spec.source       = { :git => 'https://github.com/stingle/image-recognition-ios.git', :tag => spec.version }

  spec.subspec 'Common' do |ss|
    ss.source_files = 'ImageRecognition/Classes/Common/**/*.swift'
  end

  # TensorFlow spec
  spec.subspec 'TensorFlow' do |ss|
    ss.source_files = 'ImageRecognition/Classes/TensorFlow/**/*.swift'
    ss.dependency 'ImageRecognition/Common'

    ss.subspec 'Models' do |ss|
      ss.resources = 'ImageRecognition/Classes/TensorFlow/Models/*.{tflite,txt}'
    end
  end

  spec.static_framework = true
  spec.dependency "TensorFlowLiteSwift", "~> 2.9.1"
  spec.dependency "TensorFlowLiteSwift/CoreML", "~> 2.9.1"
  # ------------------------------ TensorFlow ------------------------------------ #

  spec.ios.frameworks = 'Vision', 'UIKit', 'Photos'

end

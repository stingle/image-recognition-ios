**Stingle Object Recognition**

*Library for detecting objects and recognising faces from org.stingle.ai.image and video using TensorFlow open source library*

![](https://avatars.githubusercontent.com/u/69607920?s=200&v=4)

[![CI Status](https://img.shields.io/travis/stingle/ImageRecognition.svg?style=flat)](https://travis-ci.org/stingle/ImageRecognition)
[![Version](https://img.shields.io/cocoapods/v/ImageRecognition.svg?style=flat)](https://cocoapods.org/pods/ImageRecognition)
[![License](https://img.shields.io/cocoapods/l/ImageRecognition.svg?style=flat)](https://cocoapods.org/pods/ImageRecognition)
[![Platform](https://img.shields.io/cocoapods/p/ImageRecognition.svg?style=flat)](https://cocoapods.org/pods/ImageRecognition)

## Installation

ImageRecognition is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ImageRecognition'
```

**How to use**

Find or train the best TFLite model file for you and add into your app under assets folder.
[there are several already trained models to use](https://tfhub.dev/tensorflow/collections/lite/task-library/object-detector/1)

Objects recognition examples:

```swift
private let objectDetector: ObjectDetector = ObjectDetector()

// runnning object detection on image
self.objectDetector.makePredictions(forImage: image) { predictions in
    // ...
} 

// runnning object detection on live photo
self.objectDetector.makePredictions(forLivePhoto: livePhoto, maxProcessingImagesCount: 5) { predictions in
    // ...
}

// runnning object detection on gif
self.objectDetector.makePredictions(forGIF: url, maxProcessingImagesCount: 5) { predictions in
    // ...
}

// runnning object detection on video
let configuration = Configuration(startTime: 0.0, maxProcessingDuration: 1000.0)
self.objectDetector.makePredictions(forVideo: videoURL, configuration: configuration) { predictions in
    // ...
}
```

Face detection examples:

```swift
private let faceDetector = FaceDetector()

// runnning face detection on image
self.faceDetector.detectFaces(fromImage: image) { result in
    // ...
}

// runnning object detection on live photo
self.faceDetector.detectFaces(fromLivePhoto: livePhoto) { result in
    // ...
}

// runnning object detection on gif
self.faceDetector.detectFaces(fromGIF: url) { result in
    // ...
}

// runnning object detection on video
let configuration = Configuration(startTime: 0.0, maxProcessingDuration: 1000.0)
self.faceDetector.detectFaces(fromVideo: videoURL, configuration: configuration) { faces in
    // ...
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## License

ImageRecognition is available under the MIT license. See the LICENSE file for more info.

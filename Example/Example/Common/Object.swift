//
//  Object.swift
//  Example
//
//  Created by Shahen Antonyan on 12/1/21.
//

import UIKit
import Photos

enum ObjectType {
    case image
    case gif
    case livePhoto
    case video
}

class Object {
    let thumbnail: UIImage?
    let videoURL: URL?
    let livePhoto: PHLivePhoto?
    let type: ObjectType

    init(thumbnail: UIImage? = nil, videoURL: URL? = nil, livePhoto: PHLivePhoto? = nil, type: ObjectType) {
        self.thumbnail = thumbnail
        self.videoURL = videoURL
        self.livePhoto = livePhoto
        self.type = type
    }

}

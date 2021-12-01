//
//  ImageViewCell.swift
//  Example
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import PhotosUI

class ImageViewCell: UICollectionViewCell {
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playImageView: UIImageView!
    @IBOutlet weak private var livePhotoView: PHLivePhotoView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.contentMode = .scaleAspectFit
        self.livePhotoView?.contentMode = .scaleAspectFit
    }

    var circle: Bool = false {
        didSet {
            self.imageView.layer.cornerRadius = self.circle ? self.imageView.frame.width / 2 : 0.0
            self.livePhotoView?.layer.cornerRadius = self.circle ? self.livePhotoView.frame.width / 2 : 0.0
        }
    }

    var image: UIImage? {
        get {
            return self.imageView.image
        }
        set {
            self.imageView.isHidden = false
            self.livePhotoView?.isHidden = true
            self.imageView.image = newValue
        }
    }

    var livePhoto: PHLivePhoto? {
        get {
            return self.livePhotoView?.livePhoto
        }
        set {
            self.imageView.isHidden = true
            self.livePhotoView?.isHidden = false
            self.livePhotoView?.livePhoto = newValue
        }
    }

    var isPlayable: Bool = false {
        didSet {
            self.playImageView?.isHidden = !self.isPlayable
        }
    }

    func playLivePhoto() {
        self.livePhotoView.startPlayback(with: .full)
    }

}

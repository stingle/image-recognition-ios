//
//  FaceDetectionViewController.swift
//  Example
//
//  Created by Shahen Antonyan on 10/22/21.
//

import UIKit
import ARKit
import ImageRecognition
import Photos

class FaceDetectionViewController: ImagePickerViewController {

    @IBOutlet weak var facesCollectionView: UICollectionView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!

    private let faceDetector = FaceDetector()

    private let database = PreviewDatabase.shared

    private var filteredImages: [(AnyObject, [FaceObject])]?

    private var selectedFace: Face?
  
    private var maximumDurationOfPredictionsForVideo = 5000.0 // in milliseconds

    private var videoURL: URL?
    
    var lastVideoMomentDetected = 0.0
    
    var testFrameTook: Double? {
        didSet {
            self.faseDetectionFromSource()
        }
    }
    
    var faceDetectionFromSourceInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.facesCollectionView.allowsMultipleSelection = false
        self.imagesCollectionView.allowsMultipleSelection = false
        self.title = "Face Detection"
        self.filterAndPresentImages()
    }

    override func didSelectImage(image: UIImage) {
        self.selectedFace = nil
        self.faceDetector.detectFaces(fromImage: image) {[ weak self] result in
            self?.collectFaces(image: image, result: result)
        }
    }

    override func didSelectVideo(videoURL: URL) {
        self.selectedFace = nil
        let assetImageGenerator = AssetImageGenerator()
        let currentTS = Date().timeIntervalSince1970 * 1000
        UserDefaults.standard.set(currentTS, forKey: "startOfTestForFace")
        UserDefaults.standard.set(currentTS, forKey: "frameDetectionStartedForFace")
        faceDetectionFromSourceInProgress = true
        let image = assetImageGenerator.generateThumnail(url: videoURL, fromTime: 0.0)
        self.lastVideoMomentDetected = 0.0
        self.videoURL = videoURL
        self.faceDetector.detectFaces(fromImage: image!) {[ weak self] result in
            self?.collectFaces(image: image ?? UIImage(), result: result)
        }
    }

    override func didSelectLivePhoto(livePhoto: PHLivePhoto) {
        self.selectedFace = nil
        self.faceDetector.detectFaces(fromLivePhoto: livePhoto) { [weak self] result in
            self?.collectFaces(image: livePhoto, result: result)
        }
    }

    override func didSelectGIF(url: URL) {
        self.selectedFace = nil
        let image = UIImage.animatedImageFromGIF(url: url)
        self.faceDetector.detectFaces(fromGIF: url) { [weak self] result in
            self?.collectFaces(image: image ?? UIImage(), result: result)
        }
    }
    
    func faseDetectionFromSource() {
        let frameDetectionStarted = Date().timeIntervalSince1970 * 1000
        let alreadySpentOnDetection = frameDetectionStarted - UserDefaults.standard.double(forKey: "startOfTestForFace")
        let timeLeftForDetection = self.maximumDurationOfPredictionsForVideo - alreadySpentOnDetection
        let framesCanGet = timeLeftForDetection / self.testFrameTook!
        let asset = AVURLAsset(url: self.videoURL!)
        let durationInSeconds = asset.duration.seconds
        let leftToCheckVideoDutaion = durationInSeconds - self.lastVideoMomentDetected
        let stepForFrame = leftToCheckVideoDutaion/Double(framesCanGet)
        if timeLeftForDetection > self.testFrameTook! && (self.lastVideoMomentDetected + stepForFrame) < durationInSeconds {
            UserDefaults.standard.set(frameDetectionStarted, forKey: "frameDetectionStartedForFace")
            self.lastVideoMomentDetected = self.lastVideoMomentDetected + stepForFrame
            let assetImageGenerator = AssetImageGenerator()
            let image = assetImageGenerator.generateThumnail(url: self.videoURL!, fromTime: self.lastVideoMomentDetected)
            self.faceDetector.detectFaces(fromImage: image!) {[ weak self] result in
                self?.collectFaces(image: image ?? UIImage(), result: result)
            }
        } else {
            lastVideoMomentDetected = 0.0
            faceDetectionFromSourceInProgress = false
        }
    }

    // MARK: - Actions

    @IBAction func addButtonAction(_ sender: Any) {
        self.requestAuthorization { allowed in
            if allowed {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
                    self.openPhotoGallery()
                }))
                alert.addAction(UIAlertAction(title: "Choose Video", style: .default, handler: { _ in
                    self.openVideoGallery()
                }))
                alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let viewController = segue.destination as? ImageViewController {
//            if let selectedIndexPath = self.imagesCollectionView.indexPathsForSelectedItems?.first, let image = self.filteredImages?[selectedIndexPath.row] {
//                viewController.image = image.0
//                viewController.faces = image.1
//                self.imagesCollectionView.deselectItem(at: selectedIndexPath, animated: true)
//            }
//        }
    }

    // MARK: - Private methods

    private func filterAndPresentImages() {
        guard let selectedFace = self.selectedFace else {
            self.filteredImages = self.database.images
            self.imagesCollectionView.reloadData()
            return
        }
        self.filteredImages = self.database.images.filter({ $0.1.contains(where: { selectedFace.isSimilar(with: $0.face) }) })
        self.imagesCollectionView.reloadData()
    }

    private func collectFaces(image: AnyObject, result: Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) {
        switch result {
        case .success(let newFaces):
            DispatchQueue.global().async {
                let newFaceObjecs = newFaces.map({ FaceObject(face: $0.0, bounds: $0.1) })
                DispatchQueue.main.async {
                    self.database.addFaces(faces: newFaceObjecs)
                    self.database.addImages(images: [(image, newFaceObjecs)])
                    self.filteredImages = self.database.images
                    self.imagesCollectionView.reloadData()
                    DispatchQueue.global().async {
                        var uniqueFaces = [FaceObject]()
                        for i in 0..<self.database.faces.count {
                            let face1 = self.database.faces[i]
                            uniqueFaces.append(face1)
                            for j in (i + 1)..<self.database.faces.count {
                                let face2 = self.database.faces[j]
                                if face1.face.isSimilar(with: face2.face) {
                                    uniqueFaces.removeLast()
                                    break
                                }
                            }
                        }
                        self.database.replaceFaces(faces: uniqueFaces)
                        DispatchQueue.main.async {
                            self.facesCollectionView.reloadData()
                            self.facesCollectionView.performBatchUpdates(nil, completion: { (result) in
                                if self.faceDetectionFromSourceInProgress {
                                    self.initiateNextFrameDetection()
                                }
                            })
                        }
                    }
                }
            }
        case .failure(let error):
            self.database.addImages(images: [(image, [])])
            print(error.localizedDescription)
        }
    }
    
    private func initiateNextFrameDetection() {
        let frameDetectionStarted = UserDefaults.standard.double(forKey: "frameDetectionStartedForFace")
        let frameDetectionEnded = Date().timeIntervalSince1970 * 1000
        self.testFrameTook = frameDetectionEnded - frameDetectionStarted
    }

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized)
                }
            }
            return
        }
        completion(true)
    }

}

extension FaceDetectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === self.facesCollectionView {
            return self.database.faces.count
        }
        return self.filteredImages?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as! ImageViewCell
        if collectionView === self.facesCollectionView {
            let face = self.database.faces[indexPath.row]
            cell.image = face.face.image
            cell.circle = true
        } else {
            let image = self.filteredImages![indexPath.row]
            if let object = image.0 as? UIImage {
                cell.image = object
            } else if let object = image.0 as? PHLivePhoto {
                cell.livePhoto = object
            }
            cell.circle = false
        }
        return cell
    }

}

extension FaceDetectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.facesCollectionView {
            if self.selectedFace == nil {
                self.selectedFace = self.database.faces[indexPath.row].face
            } else {
                let face = self.database.faces[indexPath.row].face
                if face.isSimilar(with: self.selectedFace!) {
                    self.selectedFace = nil
                } else {
                    self.selectedFace = face
                }
            }
            self.filterAndPresentImages()
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
//            self.performSegue(withIdentifier: "presentImage", sender: nil)
        }
    }

}

extension FaceDetectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === self.facesCollectionView {
            let height = collectionView.frame.height - 20.0
            return CGSize(width: height, height: height)
        }
        let width = (collectionView.frame.width - 30.0) / 2
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }

}

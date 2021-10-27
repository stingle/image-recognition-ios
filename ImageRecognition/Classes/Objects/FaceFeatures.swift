//
//  FaceFeatures.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import Vision

public class FaceFeatures {

    let featurePrint: VNFeaturePrintObservation

    init(featurePrint: VNFeaturePrintObservation) {
        self.featurePrint = featurePrint
    }

    public static func ==(lhs: FaceFeatures, rhs: FaceFeatures) -> Bool {
        do {
            var distans = Float(0)
            try lhs.featurePrint.computeDistance(&distans, to: rhs.featurePrint)
            return distans <= 10
        } catch {
            return false
        }
    }

}

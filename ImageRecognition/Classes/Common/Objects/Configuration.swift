//
//  Configuration.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/28/21.
//

import Foundation

public struct Configuration {
    public let startTime: TimeInterval
    public let maxProcessingDuration: TimeInterval // miliseconds

    public init(startTime: TimeInterval = 0.0, maxProcessingDuration: TimeInterval = 5000.0) {
        self.startTime = startTime
        self.maxProcessingDuration = maxProcessingDuration
    }
}

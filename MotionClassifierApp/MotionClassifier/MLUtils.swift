//
//  MLUtils.swift
//  MotionClassifier
//
//  Created by masquare on 27.02.19.
//  Copyright © 2019 masquare. All rights reserved.
//

import Foundation
import CoreML

func tryGetRemoteModel(completion: @escaping (MLModel) -> Void) -> Void {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 5.0
    sessionConfig.timeoutIntervalForResource = 5.0
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    let task = session.dataTask(with: URL(string: "https://example.com/motion-classifier.mlmodel")!, completionHandler: { (data: Data!, response: URLResponse!, error: Error!) -> Void in
        if (error == nil) {
            let documentUrl = getDocumentsDirectory().appendingPathComponent("motion-classifier.mlmodel")
            try! data.write(to: documentUrl)
            let compiledUrl = try! MLModel.compileModel(at: documentUrl)
            let model = try! MLModel(contentsOf: compiledUrl)
            completion(model)
        }
        else {
            // Failure
            print("Failure to load remote model, using locally saved model:", error.localizedDescription);
            let motionClassifierModel = motion_classifier_1.init()
            completion(motionClassifierModel.model)
        }
    })
    task.resume()
}

func getPrediction(mlModel: MLModel, accelerometerHistory: [[Double]]) throws -> (String, String, String) {
    let flatHistory = Array(accelerometerHistory.joined())
    let multiArray: MLMultiArray = try MLMultiArray.init(shape: [NSNumber(value: flatHistory.count)], dataType: .double)
    for i in 0..<flatHistory.count {
        multiArray[i] = flatHistory[i] as NSNumber
    }
    
    
    let modelOutput = try mlModel.prediction(from: MotionClassifierInput(input1: multiArray))
    
    let prediction = modelOutput.featureValue(for: "prediction")!.dictionaryValue as! [String : Double]
    let classLabel = modelOutput.featureValue(for: "classLabel")!.stringValue
    
    let confidenceString = String(format: "%.2f%%", prediction[classLabel]! * 100)
    let debugString = prediction.map({(k, v) in String(format: "%@: %.2f", k, v)}).joined(separator: "\n")
    return (classLabel, confidenceString, debugString)
}

// auto generated feature class
class MotionClassifierInput : MLFeatureProvider {
    /// input1 as vector of doubles
    var input1: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["input1"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input1") {
            return MLFeatureValue(multiArray: input1)
        }
        return nil
    }
    
    init(input1: MLMultiArray) {
        self.input1 = input1
    }
}

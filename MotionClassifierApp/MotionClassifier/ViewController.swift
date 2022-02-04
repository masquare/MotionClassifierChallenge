//
//  ViewController.swift
//  MotionClassifier
//
//  Created by w on 25.02.19.
//  Copyright © 2019 masquare. All rights reserved.
//

import UIKit
import CoreMotion
import CoreML
import AVFoundation

class ViewController: UIViewController {
    // CONSTANTS
    let DATA_FILE_URL = getDocumentsDirectory().appendingPathComponent("data.csv")
    let TIMESTEPS_IN_HISTORY = 200
    let ACCELEROMETER_UPDATE_INTERVAL = 1.0 / 20.0 // Hz
    
    // MEMBERS
    var isCollectingData = false
    
    // VIEW OUTLETS
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var modeSelection: UISegmentedControl!
    
    
    // BUTTON HANDLING
    @IBAction func collectModeChanged(_ sender: Any) {
        // collect data on/off
        self.isCollectingData = (sender as! UISwitch).isOn
    }
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        // funcitonality for easy sharing of the training samples file
        let activityVC = UIActivityViewController(activityItems: [DATA_FILE_URL], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func clearButtonClicked(_ sender: Any) {
        // clear the training samples file
        try? FileManager.default.removeItem(at: DATA_FILE_URL)
    }
    
    // MAIN FUNCTIONALITY
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var accelerometerHistory = [[Double]]()
        var sampleList = [String]()
        
        let motion = CMMotionManager()
        var mlModel: MLModel?
        
        tryGetRemoteModel(completion: { (model: MLModel) -> Void in
            mlModel = model
            print("Successfully loaded model")
        })
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = ACCELEROMETER_UPDATE_INTERVAL
            motion.startAccelerometerUpdates()
            
            // configure a timer to fetch the data
            let timer = Timer(fire: Date(), interval: ACCELEROMETER_UPDATE_INTERVAL,
                              repeats: true, block: { (timer) in
                                if let data = motion.accelerometerData {
                                    accelerometerHistory.append([data.acceleration.x, data.acceleration.y, data.acceleration.z])
                                    
                                    // if the history is long enough, start a prediction
                                    if accelerometerHistory.count >= self.TIMESTEPS_IN_HISTORY {
                                        if mlModel == nil {
                                            self.debugLabel.text = "model not yet loadad, can't make prediction"
                                            return
                                        }
                                        do {
                                            let (classLabel, confidence, debugString) = try getPrediction(mlModel: mlModel!, accelerometerHistory: accelerometerHistory)
                                            
                                            // remove the first element so we always keep only the latest x samples
                                            accelerometerHistory.removeFirst()
                                            
                                            self.predictionLabel.text = classLabel
                                            self.confidenceLabel.text = confidence
                                            self.debugLabel.text = debugString
                                        } catch {
                                            print("Error info: \(error)")
                                        }
                                    } else {
                                        self.debugLabel.text = String(format: "Loading: %d/%d", accelerometerHistory.count, self.TIMESTEPS_IN_HISTORY)
                                    }
                                    
                                    if self.isCollectingData {
                                        let dataRow = String(format: "%d,%.3f,%.3f,%.3f",
                                                             self.modeSelection.selectedSegmentIndex,
                                                             data.acceleration.x,
                                                             data.acceleration.y,
                                                             data.acceleration.z
                                        )
                                        self.debugLabel.text = dataRow
                                        sampleList.append(dataRow)
                                    }
                                }
                                
                                // flush data to file every 50 samples
                                if sampleList.count >= 50 {
                                    try? sampleList.joined(separator: "\n").appendLineToURL(fileURL: self.DATA_FILE_URL)
                                    print("wrote to file")
                                    sampleList.removeAll()
                                }
            })
            // Add the timer to the current run loop.
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        }
    }
    
    // let's have a fancy camera background
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let cameraCaptureSession: AVCaptureSession = AVCaptureSession()
        cameraCaptureSession.sessionPreset = AVCaptureSession.Preset.high
        
        if !cameraCaptureSession.isRunning, let device = AVCaptureDevice.default(for: AVMediaType.video) {
            do {
                try cameraCaptureSession.addInput(AVCaptureDeviceInput(device: device))
            } catch {
                print(error.localizedDescription)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: cameraCaptureSession)
            
            self.backgroundView.layer.addSublayer(previewLayer)
            previewLayer.frame = self.backgroundView.layer.bounds
        }
        
        cameraCaptureSession.startRunning()
    }
}

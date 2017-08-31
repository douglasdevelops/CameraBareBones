//
//  VideoCaptureDelegate.swift
//  CameraBareBones
//
//  Created by Douglas Spencer on 8/30/17.
//  Copyright © 2017 Douglas Spencer. All rights reserved.
//

import Foundation

import AVFoundation

extension CameraVC: AVCaptureFileOutputRecordingDelegate {
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            
            _ = outputURL as URL
            
        }
        outputURL = nil
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }

}

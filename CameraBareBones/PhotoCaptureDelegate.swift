//
//  PhotoCaptureDelegate.swift
//  CameraBareBones
//
//  Created by Douglas Spencer on 8/30/17.
//  Copyright © 2017 Douglas Spencer. All rights reserved.
//

import Foundation
import AVFoundation

extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    //MARK: - Core Media Delegate Method
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if canPhotoBeCaptured {
            canPhotoBeCaptured = false
            if let takenImage = UIImageFromBuffer(buff: sampleBuffer) {
                imageFromCamera = takenImage
                EndCaptureSession()
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "PhotoViewerVC", sender: nil)
                }
            }
        }
    }

}

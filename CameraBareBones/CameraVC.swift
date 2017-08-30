
import UIKit
import AVFoundation
import AVKit


class CameraVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: - Local Variables
    let capturesession = AVCaptureSession()
    var capturePreviewLayer: CALayer!
    var captureDevice: AVCaptureDevice!
    var canPhotoBeCaptured = false
    var imageFromCamera: UIImage? = nil
    
    //MARK: - Setup Camera and Start Capturing Live Video
    func SetupCameraDevice() {
        capturesession.sessionPreset = AVCaptureSessionPresetPhoto
        
        if let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
            captureDevice = devices.first
            StartCaptureSession()
        }
    }
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        SetupCameraDevice()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        EndCaptureSession()
    }
    
    //MARK: - Capture Session Control
    func StartCaptureSession() {
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            if capturesession.canAddInput(input) {
                capturesession.addInput(input)
            }
            
        } catch  {
            debugPrint("Problem Starting Session Occured")
        }
        
        if let videoLayer = AVCaptureVideoPreviewLayer(session: capturesession) {
            
            self.capturePreviewLayer = videoLayer
            self.view.layer.addSublayer(self.capturePreviewLayer)
            self.capturePreviewLayer.frame = self.view.layer.frame
            videoLayer.connection.videoOrientation = .portrait
            videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            capturesession.startRunning()
            
            capturesession.commitConfiguration()
            AddOutput()
            
        }
    }
    
    func EndCaptureSession()  {
        capturesession.stopRunning()
        
        if let deviceInputs = capturesession.inputs as? [AVCaptureDeviceInput] {
            for deviceinput in deviceInputs {
                capturesession.removeInput(deviceinput)
            }
        }
    }
    
    func AddOutput() {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString)  : NSNumber(value: kCVPixelFormatType_32BGRA)]
        
        if capturesession.canAddOutput(output) {
            capturesession.addOutput(output)
        }
        
        let queue = DispatchQueue(label: "com.DouglasDevelops.mediaCaptureQueue")
        output.setSampleBufferDelegate(self, queue: queue)
        
    }
    
    
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
    
    //MARK: - Image Creation
    func UIImageFromBuffer(buff: CMSampleBuffer) -> UIImage? {
        if let pBuffer = CMSampleBufferGetImageBuffer(buff) {
            let image = CIImage(cvPixelBuffer: pBuffer)
            let ctx = CIContext()
            let FrameForImage = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pBuffer), height: CVPixelBufferGetHeight(pBuffer))
            
            if let finalImage = ctx.createCGImage(image, from: FrameForImage) {
                return UIImage(ciImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoViewerVC" {
            if let vc = segue.destination as? PhotoViewerVC {
                vc.photoFromCamera = imageFromCamera
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func TakeImage_Pressed(_ sender: Any) {
        canPhotoBeCaptured = true
    }
}

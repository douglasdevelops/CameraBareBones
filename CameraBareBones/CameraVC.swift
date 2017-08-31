
import UIKit
import AVFoundation
import AVKit


class CameraVC: UIViewController {
    
    //MARK: - Local Variables
    let capturesession = AVCaptureSession()
    var capturePreviewLayer: CALayer!
    var captureDevice: AVCaptureDevice!
    var canPhotoBeCaptured = false
    var imageFromCamera: UIImage? = nil
    var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    let movieOutput = AVCaptureMovieFileOutput()
    
    @IBOutlet weak var previewView: UIView!
    
    
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
            //let sw: UISwitch = UISwitch(frame: CGRect(x: 40, y: 200, width: 100, height: 100))
            self.capturePreviewLayer = videoLayer
            self.view.layer.addSublayer(self.capturePreviewLayer)
            self.capturePreviewLayer.frame = self.view.layer.frame
            //self.view.addSubview(sw)
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
    
    @IBAction func TakeVideo_Pressed(_ sender: Any) {
        
        startVideoSession()
    }
    
    @IBAction func StopRecording_Pressed(_ sender: Any) {
        stopRecording()
            }
    
    //MARK:- Setup Camera
    func setupSessionForVideo() -> Bool {
        
        capturesession.sessionPreset = AVCaptureSessionPresetHigh
        
        // Setup Camera
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if capturesession.canAddInput(input) {
                capturesession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Setup Microphone
        let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if capturesession.canAddInput(micInput) {
                capturesession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        // Movie output
        if capturesession.canAddOutput(movieOutput) {
            capturesession.addOutput(movieOutput)
        }
        
        return true
    }
    
    //MARK:- Camera Session
    func startVideoSession() {
        
        EndCaptureSession()
        
        if !capturesession.isRunning {
            videoQueue().async {
                self.setupSessionForVideo()
                self.capturesession.startRunning()
                self.startRecording()
            }
        }
    }
    
    func stopVideoSession() {
        if capturesession.isRunning {
            videoQueue().async {
                self.capturesession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    func startRecording() {
        
        if movieOutput.isRecording == false {
            
            let connection = movieOutput.connection(withMediaType: AVMediaTypeVideo)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            if (device?.isSmoothAutoFocusSupported)! {
                do {
                    try device?.lockForConfiguration()
                    device?.isSmoothAutoFocusEnabled = false
                    device?.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            outputURL = tempURL()
            movieOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        }
        else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
}

//
//  ViewController.swift
//  VideoGoTele
//
//  Created by Gurjit Singh on 2016-08-23.
//  Copyright © 2016 Gurjit Singh Ghangura. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var frontCamera = false
    
    let captureSession = AVCaptureSession()
    
    var isRecording = false
    
    let movieOutput = AVCaptureMovieFileOutput()
    
    private var tempFilePath: NSURL = {
        let tempPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("tempMovie").URLByAppendingPathExtension("mp4").absoluteString
        if NSFileManager.defaultManager().fileExistsAtPath(tempPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(tempPath)
            } catch { }
        }
        return NSURL(string: tempPath)!
    }()
    
    var frontCameraDevice: AVCaptureDevice!
    var backCameraDevice: AVCaptureDevice!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //start session configuration
        setupSession()
        
    }
    override func viewDidAppear(animated: Bool) {
        //add view with opacity
        AddView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Show Camera
    func setupSession() {
        
        frontCameraDevice = {
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
            return devices.filter{$0.position == .Front}.first
        }()
        
        backCameraDevice = {
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
            return devices.filter{$0.position == .Back}.first
        }()
        
        let micDevice: AVCaptureDevice? = {
            return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        }()
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        // add device inputs (front camera and mic)
        captureSession.addInput(deviceInputFromDevice(micDevice))
        captureSession.addInput(deviceInputFromDevice(backCameraDevice))
        
        // add output movieFileOutput
        movieOutput.movieFragmentInterval = kCMTimeInvalid
        captureSession.addOutput(movieOutput)
        
        // start session
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        previewLayer!.frame = view.bounds
        previewLayer!.connection?.videoOrientation = .Portrait
        
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
        
        
    }
    
    func deviceInputFromDevice(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let outError {
            print("Device setup error occured \(outError)")
            return nil
        }
    } 
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if (error != nil)
        {
            print("Unable to save video to the iPhone  \(error.localizedDescription)")
        }
        else
        {
            //check if the
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", "VideoGoTele")
            let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions).firstObject
            
            if collection == nil {
                CreateAlbum()
            } else {
                self.SaveVideo()
            }
        }
    }
    
    func CreateAlbum() -> Void {
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
            PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("VideoGoTele")
            }, completionHandler:{(success, error)in
                if (!success) {
                    print(error?.localizedDescription)
                } else {
                    self.SaveVideo()
                }
            })
    }
    
    func SaveVideo() -> Void {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "VideoGoTele")
        let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions).firstObject as! PHAssetCollection
        
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(self.tempFilePath)
                let assetPlaceholder = assetChangeRequest!.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: collection)
                albumChangeRequest?.addAssets([assetPlaceholder!])
                }, completionHandler: {saved, error in
                    if (error != nil) {
                        print(error?.localizedDescription)
                    }
            } )

    }
    
    func AddView() -> Void {
        
        let view = UIView(frame: CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 100))
        view.backgroundColor = UIColor.whiteColor()
        view.alpha = 0.5
        self.view.addSubview(view)
        
        //button to record video
        let button = UIButton(frame: CGRectMake((view.frame.size.width/2)-30,(view.frame.size.height/2)-30,60,60))
        let image = UIImage(named: "CameraButton")?.imageWithRenderingMode(.AlwaysTemplate)
        button.setImage(image, forState: .Normal)
        button.tintColor = UIColor.blueColor()
        view.addSubview(button)
        button.addTarget(self, action: #selector(ViewController.RecordingButtonPressed(_:)), forControlEvents: .TouchUpInside)
        
        //show flip camera button
        let flipButton = UIButton(frame: CGRectMake((view.frame.size.width/2)-120,(view.frame.size.height/2)-30,60,60))
        let flipiImage = UIImage(named: "CameraFlip")?.imageWithRenderingMode(.AlwaysTemplate)
        flipButton.setImage(flipiImage, forState: .Normal)
        view.addSubview(flipButton)
        flipButton.addTarget(self, action: #selector(ViewController.FlipCamera(_:)), forControlEvents: .TouchUpInside)
        
        //show flash button
        let flashButton = UIButton(frame: CGRectMake((view.frame.size.width/2)+90,(view.frame.size.height/2)-30,60,60))
        let flashImageiImage = UIImage(named: "ToggleFlash")?.imageWithRenderingMode(.AlwaysTemplate)
        flashButton.setImage(flashImageiImage, forState: .Normal)
        view.addSubview(flashButton)
        flashButton.addTarget(self, action: #selector(ViewController.ToggleFlash(_:)), forControlEvents: .TouchUpInside)
        
        let textView = UITextView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-100))
        textView.tag = 2
        self.view.addSubview(textView)
        textView.font = UIFont(name: "Arial", size: 25);
        textView.text = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"
        
        
    }
    
    func RecordingButtonPressed(button : UIButton) -> Void {
        
        let textView = view.viewWithTag(2) as! UITextView
//        let range = NSMakeRange(textView.frame.size.- 1, 50)
        
//        textView.scrollRangeToVisible(range)
        
        if isRecording {
            movieOutput.stopRecording()
            isRecording = false
            button.tintColor = UIColor.blueColor()
            print("stopped")
        } else {
            movieOutput.startRecordingToOutputFileURL(tempFilePath, recordingDelegate: self)
            isRecording = true
            button.tintColor = UIColor.redColor()
            print("start")
        }
    }
    
    func FlipCamera(button : UIButton) -> Void {
        
        if frontCamera {
            captureSession.removeInput(captureSession.inputs[1] as! AVCaptureInput)
            captureSession.addInput(deviceInputFromDevice(backCameraDevice))
            frontCamera = false
        } else {
            captureSession.removeInput(captureSession.inputs[1] as! AVCaptureInput)
            captureSession.addInput(deviceInputFromDevice(frontCameraDevice))
            frontCamera = true
        }
        
    }
    
    func ToggleFlash(button : UIButton) {
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                if (device.torchMode == AVCaptureTorchMode.On) {
                    device.torchMode = AVCaptureTorchMode.Off
                } else {
                    do {
                        try device.setTorchModeOnWithLevel(1.0)
                    } catch {
                        print(error)
                    }
                }
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }

}










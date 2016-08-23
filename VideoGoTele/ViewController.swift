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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //start session configuration
        setupSession()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Show Camera
    func setupSession() {
        
        let captureSession = AVCaptureSession()
        
        let frontCameraDevice: AVCaptureDevice? = {
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
            return devices.filter{$0.position == .Back}.first
        }()
        
        let micDevice: AVCaptureDevice? = {
            return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        }()
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        // add device inputs (front camera and mic)
        captureSession.addInput(deviceInputFromDevice(frontCameraDevice))
        captureSession.addInput(deviceInputFromDevice(micDevice))
        
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touch")
        // start capture
        
        movieOutput.startRecordingToOutputFileURL(tempFilePath, recordingDelegate: self)
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("release")
        //stop capture
        movieOutput.stopRecording()
    }
    
    private func deviceInputFromDevice(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let outError {
            print("Device setup error occured \(outError)")
            return nil
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
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
                    print(error)
                    print(saved)
            } )

    }
    
//    func addView() -> Void {
//        let view = UIView(frame: CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50))
//        view.alpha = 0.5
//        self.view.addSubview(view)
//    }


}










//
//  CaptureBarCodeViewController.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/19/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureBarCodeViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var captureArea: UIImageView!
    var barcodeResult = ""
    var video = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barcodeResult = ""
        
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        
        do{
            if let device = captureDevice {
                let input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
            }
            else
            {
                print("error capture input")
            }
        }
        catch {
            print("capture exception")
        }

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        output.metadataObjectTypes = [.qr, .ean13 ]

        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = view.layer.bounds
        video.videoGravity = .resizeAspectFill
        view.layer.addSublayer(video)
        view.bringSubview(toFront: captureArea)

        session.startRunning()

    }
    
    
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObjects = metadataObjects.first {
            guard let object = metadataObjects as? AVMetadataMachineReadableCodeObject else {return}
            if let result = object.stringValue {
            barcodeResult = result
            self.session.stopRunning()
            performSegue(withIdentifier: "unwindToPriceCheckSegue", sender: self)
            }
                
                
            }
        
            
        }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let priceCheckViewControl = segue.destination as! PriceCheckViewController
        priceCheckViewControl.barcodeReturnResult = barcodeResult
        
    }

}

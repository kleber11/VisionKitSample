//
//  ViewController.swift
//  TextRecognizingSample
//
//  Created by Vladyslav Vcherashnii on 23.01.2020.
//  Copyright © 2020 Vladyslav Vcherashnii. All rights reserved.
//

import UIKit
import VisionKit
import Vision

class ViewController: UIViewController {
    
    // MARK: - @IBOutlets
    @IBOutlet weak private var recognizedTextView: UITextView!
    @IBOutlet weak private var imageView: UIImageView!
    
    // MARK: - Properties
    private var request: VNRecognizeTextRequest!

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.setupVisionKit()
    }

    // MARK: - Behavior
    private func setupVisionKit() {
        self.request = VNRecognizeTextRequest(completionHandler: { [weak self] request, error in
            guard let `self` = self else { return }
            
            if let error = error {
                print("Scanned with error: \(error.localizedDescription)")
                return
            }
            
            guard let result = request.results as? [VNRecognizedTextObservation], result.count > 0 else {
                print("Nothing found")
                return
            }
            
            var scannedTextValue = ""
            for observation in result {
                guard let topValue = observation.topCandidates(1).first else { return }
                scannedTextValue += "\(topValue.string)\n"
            }
            
            DispatchQueue.main.async {
                self.recognizedTextView.text = scannedTextValue
            }
            
        })
        self.request.recognitionLanguages = ["en-US"]
        self.request.recognitionLevel = .accurate
    }
    
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        self.imageView.image = image
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try imageRequestHandler.perform([self.request])
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
}

// MARK: - @IBActions
extension ViewController {
    @IBAction private func scan(_ sender: Any?) {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = self
        self.present(scannerVC, animated: true, completion: nil)
    }
}

// MARK: - VisionKit delegate
extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount > 0 else { return }
        let image = scan.imageOfPage(at: 0)
        self.recognizeText(in: image)
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("Failed with error: \(error.localizedDescription)")
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

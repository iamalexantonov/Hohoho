//
//  ViewController.swift
//  Hohoho
//
//  Created by Alexey Antonov on 02/01/21.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var previewView: UIImageView!
    
    var isLoading = true
    
    var classificationRequest: VNRequest {
        let model = try! VNCoreMLModel(for: ChristmasTreeClassifier().model)

        let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }
    
    var audioPlayer: AVAudioPlayer?
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }

            if let classifications = results as? [VNClassificationObservation] {
                if classifications.first?.identifier == "Christmas Tree" && classifications.first!.confidence > 0.9 {
                    self.classificationLabel.text = "This is a Christmas Tree! HO-HO-HO!"
                    if !(self.audioPlayer?.isPlaying ?? true) {
                        self.audioPlayer?.play()
                        
                    }
                } else {
                    self.classificationLabel.text = "That's not a Christmas tree"
                }
            }
        }
    }
    
    @IBAction func oneMoreTry(_ sender: Any) {
        setupCamera()
    }
    
    private func setupCamera() {
        let cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        cameraPicker.delegate = self
        
        self.present(cameraPicker, animated: true, completion: {})
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        self.classificationLabel.text = "Find a Christmas tree"
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let path = Bundle.main.path(forResource: "hohoho", ofType:"wav")!
            let url = URL(fileURLWithPath: path)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 1
            audioPlayer?.prepareToPlay()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isLoading {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                    self.setupCamera()
                
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if granted {
                            self.setupCamera()
                        }
                    }
                
                default:
                    return
            }
            
            isLoading = false
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let photo = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: photo.cgImage!, orientation: .up, options: [:])
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
        
        self.previewView.image = photo
        
        dismiss(animated: true, completion: nil)
    }
}

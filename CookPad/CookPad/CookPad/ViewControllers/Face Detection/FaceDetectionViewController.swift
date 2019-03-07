//
//  FaceDetectionViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/07.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit
import Vision

class FaceDetectionViewController: UIViewController {

    var scaledHeight: CGFloat = 0
    var imageView = UIImageView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select Photo", style: .plain, target: self, action: #selector(selectPhotoClicked(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetPhotoClicked(_:)))
        
        edgesForExtendedLayout = []
        guard let image = UIImage(named: "sample1") else { return }
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        
        scaledHeight = view.frame.width / image.size.width * image.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: scaledHeight)
        view.addSubview(imageView)
        
        performFaceDetection(image: image)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.all)
    }
    
    //MARK: - Face Detection Methods
    func performFaceDetection(image: UIImage) {
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            if let err = err {
                self.showAlert(message: err.localizedDescription)
                return
            }
            
            if req.results?.count == 0 {
                DispatchQueue.main.async {
                    self.showAlert(message: "No faces detected !")
                }
            }
            
            req.results?.forEach({ (res) in
                DispatchQueue.main.async {
                    guard let faceObservation = res as? VNFaceObservation else { return }//Use boundingBox property to detect face
                    
                    let x = self.view.frame.width * faceObservation.boundingBox.origin.x
                    let width = self.view.frame.width * faceObservation.boundingBox.width
                    let height = self.scaledHeight * faceObservation.boundingBox.height
                    let y = self.scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height
                    
                    let redView = UIView()
                    redView.backgroundColor = .red
                    redView.alpha = 0.4
                    redView.frame = CGRect(x: x, y: y, width: width, height: height)
                    self.view.addSubview(redView)
                }
            })
        }
        
        guard let cgImage = image.cgImage else { return }
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch let reqErr {
                DispatchQueue.main.async {
                    self.showAlert(message: reqErr.localizedDescription)
                }
            }
        }
    }
    
    //MARK: - Private Methods
    func removeRedViews() {
        for v in view.subviews {
            if v.isKind(of: UIImageView.self) {
            } else {
                v.removeFromSuperview()
            }
        }
    }
    
    func showAlert(message: String)
    {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Action Methods
    @objc func selectPhotoClicked(_ sender: UIButton) {
        removeRedViews()
        let picker = UIImagePickerController()
        picker.delegate = self
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {action in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { action in
            picker.sourceType = .photoLibrary
            // on iPad we are required to present this as a popover
            if UIDevice.current.userInterfaceIdiom == .pad {
                picker.modalPresentationStyle = .popover
                picker.popoverPresentationController?.sourceView = self.view
                //picker.popoverPresentationController?.sourceRect = self.selectPhotoButton.frame
            }
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // on iPad this is a popover
        alert.popoverPresentationController?.sourceView = self.view
        //alert.popoverPresentationController?.sourceRect = selectPhotoButton.frame
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func resetPhotoClicked(_ sender: UIButton) {
        guard let image = UIImage(named: "sample1") else { return }
        removeRedViews()
        self.imageView.image = image
        performFaceDetection(image: image)
    }
}

extension FaceDetectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        self.imageView.image = image
        performFaceDetection(image: image)
    }
}

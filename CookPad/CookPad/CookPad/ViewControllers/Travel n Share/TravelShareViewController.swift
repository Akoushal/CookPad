//
//  TravelShareViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/06.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit

class TravelShareViewController: UIViewController {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var selectPhotoButton: UIButton!
    var imageChosen: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    //MARK: - IBAction Methods
    @IBAction func selectPhotoClicked(_ sender: UIButton) {
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
                picker.popoverPresentationController?.sourceRect = self.selectPhotoButton.frame
            }
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // on iPad this is a popover
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = selectPhotoButton.frame
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func exit(unwindSegue: UIStoryboardSegue) {
        self.imageChosen = nil
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageSegue" {
            if let shareViewController = segue.destination as? ShareViewController {
                shareViewController.image = self.imageChosen
                shareViewController.name = name.text ?? ""
                shareViewController.message = message.text ?? ""
            }
        }
    }
}

extension TravelShareViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        self.imageChosen = image
        performSegue(withIdentifier: "showImageSegue", sender: self)
    }
}

extension TravelShareViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

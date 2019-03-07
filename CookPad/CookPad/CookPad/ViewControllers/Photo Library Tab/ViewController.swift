//
//  ViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/02.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit
import Photos

struct DeviceInfo {
    struct Orientation {
        static var isLandscape: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation ? UIDevice.current.orientation.isLandscape : UIApplication.shared.statusBarOrientation.isLandscape
            }
        }
        
        static var isPortrait: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation ? UIDevice.current.orientation.isPortrait : UIApplication.shared.statusBarOrientation.isPortrait
            }
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photosList: UICollectionView!
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photosList.register(UINib(nibName: "PhotosCell", bundle: Bundle.main), forCellWithReuseIdentifier: "PhotosCell")
        checkAuthorization()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        photosList.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Private Methods
    private func fetchPhotos() {
        imageArray = []
        
        DispatchQueue.global(qos: .background).async {
            let imgManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if fetchResult.count > 0 {
                for i in 0..<fetchResult.count {
                    imgManager.requestImage(for: fetchResult.object(at: i), targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, error) in
                        self.imageArray.append(image!)
                    })
                }
            } else {
                print("You've got no photos")
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.photosList.reloadData()
            }
        }
    }
    
    private func checkAuthorization() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                self.fetchPhotos()
            case .denied:
                self.displayAlert()
            case .notDetermined:
                if status == .authorized {
                    self.fetchPhotos()
                } else {
                    self.displayAlert()
                }
            case .restricted:
                self.displayAlert()
            }
        }
    }
    
    private func displayAlert() {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
        let alert = UIAlertController(title: "Photos Access Denied", message: "App needs access to photos library", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCell", for: indexPath) as! PhotosCell
        cell.photoImageView.image = imageArray[indexPath.item]
        return cell
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        if DeviceInfo.Orientation.isPortrait {
            return CGSize(width: width/4 - 1, height: width/4 - 1)
        } else {
            return CGSize(width: width/7 - 1, height: width/7 - 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = ImagePreviewViewController()
        vc.imgArray = self.imageArray
        vc.passedContentOffset = indexPath
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


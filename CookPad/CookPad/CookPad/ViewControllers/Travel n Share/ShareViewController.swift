//
//  ShareViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/07.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

struct kConstants {
    static let finalImageMaxDimension: CGFloat = 2048
    static let finalImageBorderWidth: CGFloat = 4
    static let userImageMaxDimension: CGFloat = 1200
    static let userImageBorderWidth: CGFloat = 20
    static let userImageX: CGFloat = 100
    static let userImageY: CGFloat = 160
    static let mapRegionDistance: CLLocationDistance = 600
    static let rotateContentByDegrees: CGFloat = -4
    static let userMessageMaxLength = 100
    static let textMargin: CGFloat = 280
    static let userMessageTopMargin: CGFloat = 60
    static let userNameTopMargin: CGFloat = 80
    static let userNameHeight: CGFloat = 120
}

class ShareViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var image = UIImage()
    var name = ""
    var message = ""
    var locationManager = CLLocationManager()
    var locationString = ""
    var mapImage = UIImage()
    
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.activityIndicator.startAnimating()
        getCurrentLocation()
    }
    
    //MARK: - IBAction Methods
    @IBAction func shareImage(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true, completion: nil)
    }
    
    //MARK: - Private Methods
    private func getCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.authorizationStatus() == .denied) {
            showError(title: "Location Access Denied", message: "The location permission was not authorized. Please enable it in Privacy Settings to allow the app to get your location and generate a map image based on that.")
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func showError(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func generateMapImage(location userLocation: CLLocation) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, latitudinalMeters: kConstants.mapRegionDistance, longitudinalMeters: kConstants.mapRegionDistance)
        mapSnapshotOptions.region = region
        
        // Set the size of the image output.
        mapSnapshotOptions.size = calculateMapImageSize()
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        snapShotter.start(completionHandler: { snapShot, error in
            if error != nil {
                self.showError(title: "Whoops1...", message: error!.localizedDescription)
            } else {
                self.mapImage = snapShot!.image
                self.activityIndicator.stopAnimating()
                self.generateFinalImage()
            }
        })
    }
    
    func calculateMapImageSize() -> CGSize  {
        let maxSize = kConstants.finalImageMaxDimension - 2 * kConstants.finalImageBorderWidth
        if image.size.width > image.size.height {
            return CGSize(width: maxSize, height: round(maxSize * image.size.height / image.size.width))
        } else {
            return CGSize(width: round(maxSize * image.size.width / image.size.height), height: maxSize)
        }
    }
    
    func generateFinalImage() {
        let size = CGSize(width: mapImage.size.width + 2 * kConstants.finalImageBorderWidth, height: mapImage.size.height + 2 * kConstants.finalImageBorderWidth)
        let userImageSize = calculateUserImageFinalSize()
        
        // start drawing context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the white background
        let bgRectangle = CGRect(x: 0, y: 0, width: mapImage.size.width + 2 * kConstants.finalImageBorderWidth, height: mapImage.size.height + 2 * kConstants.finalImageBorderWidth)
        context!.saveGState()
        context!.setFillColor(UIColor.white.cgColor)
        context!.addRect(bgRectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // draw the map
        mapImage.draw(in: CGRect(x: kConstants.finalImageBorderWidth, y: kConstants.finalImageBorderWidth, width: mapImage.size.width, height: mapImage.size.height))
        
        // draw a semitransparent white rectage over the  map to dim it
        let transparentRectangle = CGRect(x: kConstants.finalImageBorderWidth, y: kConstants.finalImageBorderWidth, width: mapImage.size.width, height: mapImage.size.height)
        context!.saveGState()
        context!.setFillColor(UIColor(red: 255, green: 255, blue: 255, alpha: 0.3).cgColor)
        context!.addRect(transparentRectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // rotate the context
        context!.rotate(by: (kConstants.rotateContentByDegrees * CGFloat.pi / 180))
        
        // draw white rectangle
        let rectangle = CGRect(x: kConstants.userImageX, y: kConstants.userImageY, width: userImageSize.width + 2 * kConstants.userImageBorderWidth, height: userImageSize.height + 2 * kConstants.userImageBorderWidth)
        context!.saveGState()
        context!.setFillColor(UIColor.white.cgColor)
        context!.setShadow(offset: CGSize(width: kConstants.userImageBorderWidth, height: kConstants.userImageBorderWidth), blur: 8.0)
        context!.addRect(rectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // draw user image
        image.draw(in: CGRect(x: kConstants.userImageX + kConstants.userImageBorderWidth, y: kConstants.userImageY + kConstants.userImageBorderWidth, width: userImageSize.width, height: userImageSize.height))
        
        // draw message
        var truncatedMessage = message
        if (message.distance(from: message.startIndex, to: message.endIndex) > kConstants.userMessageMaxLength) {
            let newStr = String(message[..<message.startIndex])
            truncatedMessage = newStr
        }
        let messageFont = UIFont(name: "Noteworthy-Bold", size: 80)!
        let messageFontAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): messageFont,
            NSAttributedString.Key.foregroundColor: UIColor.black,
            ]
        let messageSize = sizeOfString(string: truncatedMessage, constrainedToWidth: Double(size.width - kConstants.textMargin), attributes: messageFontAttributes)
        truncatedMessage.draw(in: CGRect(x: kConstants.userImageX + kConstants.userImageBorderWidth, y: kConstants.userImageY + kConstants.userImageBorderWidth + userImageSize.height + kConstants.userMessageTopMargin, width: size.width - kConstants.textMargin, height: messageSize.height), withAttributes: messageFontAttributes)
        
        // draw name, location & date
        let nameFont = UIFont(name: "Noteworthy", size: 58)!
        let nameFontAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): nameFont,
            NSAttributedString.Key.foregroundColor: UIColor.black,
            ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        var nameString = ""
        if(name != "") {
            nameString = name + " - " + dateFormatter.string(from: Date()) + ", " + locationString
        } else {
            nameString = dateFormatter.string(from: Date()) + ", " + locationString
        }
        nameString.draw(in: CGRect(x: kConstants.userImageX + kConstants.userImageBorderWidth, y: kConstants.userImageY + kConstants.userImageBorderWidth + userImageSize.height + messageSize.height + kConstants.userNameTopMargin, width: size.width - kConstants.textMargin, height: kConstants.userNameHeight), withAttributes: nameFontAttributes)
        
        // get final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end drawing context
        UIGraphicsEndImageContext()
        
        // show the final image to the user & update tha status label
        imageView.image = finalImage
        titleLabel.text = "You can now share your image."
    }
    
    func calculateUserImageFinalSize() -> CGSize  {
        if image.size.width > image.size.height {
            return CGSize(width: kConstants.userImageMaxDimension, height: round(kConstants.userImageMaxDimension * image.size.height / image.size.width))
        } else {
            return CGSize(width: round(kConstants.userImageMaxDimension * image.size.width / image.size.height), height: kConstants.userImageMaxDimension)
        }
    }
    
    func sizeOfString (string: String, constrainedToWidth width: Double, attributes: [NSAttributedString.Key: Any]) -> CGSize {
        let attString = NSAttributedString(string: string, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }
}

extension ShareViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        manager.stopUpdatingLocation()
        
        // get city & country name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if error != nil {
                self.showError(title: "Whoops...", message: error!.localizedDescription)
            } else {
                let placemark = placemarks?[0]
                self.locationString = (placemark?.administrativeArea ?? "") + ", " + (placemark?.country ?? "")
                self.generateMapImage(location: location)
            }
        })
    }
}

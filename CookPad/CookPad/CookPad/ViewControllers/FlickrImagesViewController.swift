//
//  FlickrImagesViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/06.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit

struct Constants {
    //Key - cab23d6c3034f832db7ea297a0731044
    //Secret - c42d15321f9e3db7
    struct FlickrURLParams {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
    }
    
    struct FlickrAPIKeys {
        static let SearchMethod = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let ResponseFormat = "format"
        static let DisableJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
    }
    
    struct FlickrAPIValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "cab23d6c3034f832db7ea297a0731044"//"6018ce76bba90c3eff10d2f95093f634"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let MediumURL = "url_m"
        static let SafeSearch = "1"
    }

}

class FlickrImagesViewController: UIViewController {

    @IBOutlet weak var flickrImageView: UIImageView!
    @IBOutlet weak var actIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let searchText = "Food"
        searchTextfield.text = searchText
        performSearch()
    }
    
    //MARK: - Private Methods
    
    func performSearch() {
        let searchURL = flickrURLFromParameters(searchString: searchTextfield.text ?? "")
        // Send the request
        performFlickrSearch(searchURL: searchURL)
    }
    
    private func flickrURLFromParameters(searchString: String) -> URL {
        
        // Build base URL
        var components = URLComponents()
        components.scheme = Constants.FlickrURLParams.APIScheme
        components.host = Constants.FlickrURLParams.APIHost
        components.path = Constants.FlickrURLParams.APIPath
        
        // Build query string
        components.queryItems = [URLQueryItem]()
        
        // Query components
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.APIKey, value: Constants.FlickrAPIValues.APIKey))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.SearchMethod, value: Constants.FlickrAPIValues.SearchMethod))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.ResponseFormat, value: Constants.FlickrAPIValues.ResponseFormat))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.Extras, value: Constants.FlickrAPIValues.MediumURL))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.SafeSearch, value: Constants.FlickrAPIValues.SafeSearch))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.DisableJSONCallback, value: Constants.FlickrAPIValues.DisableJSONCallback))
        components.queryItems!.append(URLQueryItem(name: Constants.FlickrAPIKeys.Text, value: searchString))
        
        return components.url!
    }
    
    private func performFlickrSearch(searchURL: URL) {
        
        // Perform the request
        actIndicator.startAnimating()
        let session = URLSession.shared
        let request = URLRequest(url: searchURL)
        let task = session.dataTask(with: request){
            (data, response, error) in
            if (error == nil)
            {
                // Check response code
                let status = (response as! HTTPURLResponse).statusCode
                if (status != 200)
                {
                    self.displayAlert("Server returned an error")
                    return
                }
                
                /* Check data returned? */
                guard let data = data else {
                    self.displayAlert("No data was returned by the request!")
                    return
                }
                
                // Parse the data
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
                } catch {
                    self.displayAlert("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                // Check for "photos" key in our result
                guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                    self.displayAlert("Key 'photos' not in \(String(describing: parsedResult))")
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    self.displayAlert("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                // Check number of photos
                if photosArray.count == 0 {
                    self.displayAlert("No Photos Found. Search Again.")
                    return
                } else {
                    // Get the first image
                    let photoDictionary = photosArray[0] as [String: AnyObject]
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary["url_m"] as? String else {
                        self.displayAlert("Cannot find key 'url_m' in \(photoDictionary)")
                        return
                    }
                    
                    // Fetch the image
                    self.fetchImage(imageUrlString)
                }
                
            }
            else{
                self.displayAlert((error?.localizedDescription)!)
            }
        }
        task.resume()
    }

    private func fetchImage(_ url: String) {
        
        let imageURL = URL(string: url)
        
        let task = URLSession.shared.dataTask(with: imageURL!) { (data, response, error) in
            if error == nil {
                let downloadImage = UIImage(data: data!)!
                
                DispatchQueue.main.async(){
                    self.actIndicator.stopAnimating()
                    self.actIndicator.isHidden = true
                    self.flickrImageView.image = downloadImage
                }
            }
        }
        
        task.resume()
    }
    
    func displayAlert(_ message: String)
    {
        actIndicator.stopAnimating()
        actIndicator.isHidden = true
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Click", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - IBAction Methods
    @IBAction func searchImage(_ sender: UIButton) {
        searchTextfield.resignFirstResponder()
        if searchTextfield.text?.isEmpty == false {
            performSearch()
        }
    }
}

extension FlickrImagesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//
//  MainViewController.swift
//  Demo-FlickrApp
//
//  Created by Anand on 10/12/16.
//  Copyright © 2016 Anand. All rights reserved.
//

import UIKit

private let downloadQueue = DispatchQueue(label: "me.readytoImage.downloadQueue", attributes: [])

class MainViewController: UIViewController {

    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionBottom: NSLayoutConstraint!
    
    fileprivate let cellIdentifier = "PhotoCell"
    fileprivate let showPhotoSegueIdentifier = "ShowPhoto"
    fileprivate let apiURL = "https://api.flickr.com/services/feeds/photos_public.gne?nojsoncallback=1&format=json"
    fileprivate var photos = [URL]()
    fileprivate var modifiedAt = Date.distantPast
    fileprivate var cache = NSCache<AnyObject, AnyObject>()
    fileprivate var dataInProcess = false
    fileprivate var activityIndicator = UIActivityIndicatorView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Collection view"
        addActivityIndicator()
        fetchImageData(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        cache.removeAllObjects()
        photos.removeAll()
    }
    
    fileprivate func addActivityIndicator(){
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.frame = CGRect(x: (self.view.frame.width-50)/2, y: self.view.frame.height - 60, width: 50, height: 50)
        self.view.addSubview(activityIndicator)
        self.view.bringSubview(toFront: activityIndicator)
    }
    
    fileprivate func activity(_ status: Bool){
        guard status == true else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            return
        }
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    fileprivate func fetchImageData(_ handler: ((Void) -> Void)?) {
        let requestURL = URL(string: apiURL)!
        
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                self.handleResponse(data, response: response, error: error as NSError!, completion: handler)
                UIApplication.shared.stopNetworkActivity()
            }
        })
        
        UIApplication.shared.startNetworkActivity()
        let delay = (photos.count == 0 ? 0 : 5) * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            task.resume()
        })
    }
    
    fileprivate func handleResponse(_ data: Data!, response: URLResponse!, error: NSError!, completion: ((Void) -> Void)?) {
        if let _ = error {
            showAlertWithError(error)
            completion?()
            return;
        }
        
        var jsonError: NSError?
        var jsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        var responseDict: [String: AnyObject]?
        
        // Fix broken Flickr JSON
        jsonString = jsonString?.replacingOccurrences(of: "\\'", with: "'") as NSString?
        let fixedData = jsonString?.data(using: String.Encoding.utf8.rawValue)
        
        do {
            responseDict = try JSONSerialization.jsonObject(with: fixedData!, options: JSONSerialization.ReadingOptions()) as? [String: AnyObject]
        }
        catch {
            jsonError = NSError(domain: "JSONError", code: 1, userInfo: [ NSLocalizedDescriptionKey: "Failed to parse JSON." ])
        }
        
        if let jsonError = jsonError {
            showAlertWithError(jsonError)
            completion?()
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        let modifiedAt_ = dateFormatter.date(from: responseDict?["modified"] as! String)
        
        if modifiedAt_?.compare(modifiedAt) != ComparisonResult.orderedDescending {
            completion?()
            return
        }
        
        var indexPaths = [IndexPath]()
        let firstIndex = photos.count
        
        if let items = responseDict?["items"] as? NSArray {
            if let urls = items.value(forKeyPath: "media.m") as? [String] {
                for (i, url) in urls.enumerated() {
                    let indexPath = IndexPath(item: firstIndex + i, section: 0)
                    photos.append(URL(string: url)!)
                    indexPaths.append(indexPath)
                }
            }
        }
        
        modifiedAt = modifiedAt_!
        collectionView?.performBatchUpdates({ () -> Void in
            self.collectionView?.insertItems(at: indexPaths)
        }, completion: { (finished) -> Void in
            completion?()
        });
    }
    
    //MARK:- Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == showPhotoSegueIdentifier {
            if let indexPath = collectionView?.indexPath(for: sender as! UICollectionViewCell) {
                let url = photos[indexPath.item]
                if let _ = cache.object(forKey: url as AnyObject) {
                    return true
                }
            }
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showPhotoSegueIdentifier {
            if let indexPath = collectionView?.indexPath(for: sender as! UICollectionViewCell) {
                let controller = segue.destination as! PhotoViewController
                let url = photos[indexPath.item]
                controller.photo = cache.object(forKey: url as AnyObject) as? UIImage
            }
        }
    }
    
    //MARK:- Alert View
    fileprivate func showAlertWithError(_ error: NSError) {
        let alert = UIAlertController(title: "Error fetching data", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (action) -> Void in
        }))
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) -> Void in
            self.fetchImageData(nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        let url = photos[indexPath.item]
        let image = cache.object(forKey: url as AnyObject) as? UIImage
        
        cell.imageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        cell.imageView.image = image
        
        if image == nil {
            downloadPhoto(url, completion: { (url, image) -> Void in
                let indexPath_ = collectionView.indexPath(for: cell)
                if indexPath == indexPath_ {
                    cell.imageView.image = image
                }
            })
        }
        return cell
    }

}

extension MainViewController: UICollectionViewDelegateFlowLayout{
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionWidth = collectionView.bounds.width;
        var itemWidth = collectionWidth / 2 - 1;
        
        if(UI_USER_INTERFACE_IDIOM() == .pad) {
            itemWidth = collectionWidth / 4 - 1;
        }
        return CGSize(width: itemWidth, height: itemWidth);
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

}

extension MainViewController: UIScrollViewDelegate {

    // MARK: - Private
    fileprivate func downloadPhoto(_ url: URL, completion: @escaping (_ url: URL, _ image: UIImage) -> Void) {
        downloadQueue.async(execute: { () -> Void in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.cache.setObject(image, forKey: url as AnyObject)
                        completion(url, image)
                    })
                }
            }
        })
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView{
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height){
                guard dataInProcess == true else {
                    dataInProcess = true
                    animationBottom(.start)
                    activity(true)
                    self.fetchImageData() {
                        self.dataInProcess = false
                        self.activity(false)
                        self.animationBottom(.stop)
                    }
                    return
                }
            }
        }
    }
    
    enum Animation: CGFloat{
        case start = 70.0
        case stop = 0.0
    }
    
    //MARK: - Animation
    func animationBottom(_ value: Animation){
        UIView.animate(withDuration: 0.4, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: { () -> Void in
            self.collectionBottom.constant = value.rawValue
        }, completion: nil)
    }
}


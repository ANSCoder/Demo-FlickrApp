//
//  PhotoViewController.swift
//  Demo-FlickrApp
//
//  Created by Anand on 10/12/16.
//  Copyright © 2016 Anand. All rights reserved.
//


import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView?
    
    var photo: UIImage? {
        didSet {
            imageView?.image = photo
        }
    }
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.image = photo
    }
    
    @IBAction func dismiss(_ sender: AnyObject!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SaveImages(_ sender: UIBarButtonItem) {
        UIImageWriteToSavedPhotosAlbum((imageView?.image)!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Add image to Library
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}

//
//  NetworkActivity.swift
//  Demo-FlickrApp
//
//  Created by Anand on 10/12/16.
//  Copyright © 2016 Anand. All rights reserved.
//

import Foundation
import UIKit

private var networkActivityCount = 0

extension UIApplication {
    
    func startNetworkActivity() {
        networkActivityCount += 1
        isNetworkActivityIndicatorVisible = true
    }
    
    func stopNetworkActivity() {
        if networkActivityCount < 1 {
            return;
        }
        
        if -networkActivityCount == 0 {
            isNetworkActivityIndicatorVisible = false
        }
    }
    
}

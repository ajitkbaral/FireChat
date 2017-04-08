//
//  Extensions.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/5/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        
        //Not to show the resuable cell image
        self.image = nil
        
        //Check cache for images first
        
        if let cachedImage = imageCache.object(forKey: (urlString) as NSString) {
            self.image = cachedImage
            return
        }
        
        
        //Otherwise download a new image
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                //Download error
                if error != nil {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    if let downloadImage = UIImage(data: data!){
                        imageCache.setObject(downloadImage, forKey: urlString as NSString)
                        self.image = downloadImage
                    }
                }
                
            }).resume()
        }
        
        
    }
}

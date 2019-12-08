//
//  ImageChache.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation
import UIKit

let kThumbnailCachingFinishedNotification = "ThumbnailCachingFinishedNotification"

class ImageCache {
   
   static var cache:ImageCache {
      return instance
   }
   
   private static var instance = ImageCache()
   
   private init() {}
   
   private let cache = NSCache<NSString, UIImage>()
   
   func imageFor(_ key:String) -> UIImage? {
      let result = cache.object(forKey: (key as NSString))
      return result
   }
   
   func setImage(_ image:UIImage, for key:String) {
      cache.setObject(image, forKey: (key as NSString))
      
      dispatchOnMainQueue {
         NotificationCenter.default.post(name: NSNotification.Name(kThumbnailCachingFinishedNotification),
                                         object: nil,
                                         userInfo: ["url":key])
      }
   }
}

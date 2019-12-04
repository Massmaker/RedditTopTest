//
//  RequestsHandler.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation
import UIKit

typealias VoidBlock = () -> Void
typealias ResultBlock = (Data) -> Void
typealias ErrorBlock = (Error?) -> Void
typealias OptionalImageBlock = (UIImage?) -> Void

class RequestsHandler {
   
   private static let ApiRoot = "https://www.reddit.com/top.json"
   
   private static var urlSession:URLSession = {
      let config = URLSessionConfiguration.default
      config.allowsConstrainedNetworkAccess = true
      config.httpMaximumConnectionsPerHost = 2
      
      let session = URLSession.init(configuration: config)
      
      return session
   }()
   
   static var thumbnailsQueue:OperationQueue {
      let queue = OperationQueue()
      queue.maxConcurrentOperationCount = 2
      
      return queue
   }
   
   static var pendingImageDownloads = Set<String>()
   
   class func getNextTop(after:String? = nil, completion:ResultBlock?, errorBlock:ErrorBlock?) {
      
      guard let apiURL = URL(string:ApiRoot) else {
         
         errorBlock?(NetworkError.wrongURLFormat(string: "Could not create URL from string:\n \(ApiRoot)"))
         return
      }
      
      var requestURL = apiURL
      
      if let parameterAfter = after {
         
         let urlString = ApiRoot + "?after=\(parameterAfter)"
         
         if let newURL = URL(string: urlString) {
            requestURL = newURL
         }
      }
//      print(requestURL.absoluteString)
      
      var req = URLRequest(url: requestURL)
      
      req.addValue("application/json", forHTTPHeaderField: "Accept")
      req.addValue("UTF-8", forHTTPHeaderField: "charset")
      
      let task = urlSession.dataTask(with: req) { (data, response, error) in
         
         guard let aData = data else {
            errorBlock?(error)
            return
         }
         
         completion?(aData)
      }
      
      task.resume()
   }
   
   @discardableResult
   class func downloadImageFor(_ urlString:String,
                               completion:OptionalImageBlock? = nil) -> Bool {
      
      guard !pendingImageDownloads.contains(urlString),
         let url = URL(string: urlString) else {
         return false
      }
      
      //print("\n - Loading: \(urlString)")
      pendingImageDownloads.insert(urlString)
      
      var request = URLRequest(url: url)
      request.addValue("image/jpeg, image/png", forHTTPHeaderField: "Accept")
      
      let task = urlSession.dataTask(with: request) { (imgData, response, error) in
         
         if let data = imgData,
            let image = UIImage(data: data) {
            //print("Finished loading image: \n\(urlString)")
            ImageCache.cache.setImage(image, for: urlString)
            completion?(image)
         }
         else if let anError = error {
            print("\n - could not download thumbnail for: \(urlString): \n \(anError.localizedDescription)")
            completion?(nil)
         }
         else {
            completion?(nil)
         }
         
         pendingImageDownloads.remove(urlString)
      }
      
      task.priority = URLSessionTask.lowPriority
      task.resume()
      
      return true
   }
   
}

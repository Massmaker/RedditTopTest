//
//  Model.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation
import UIKit

let kPostsLoadingErrorNotification = "PostsLoadingErrorNotification"

fileprivate let kPostEntriesFileName = "Entries"
fileprivate let kPageInfoFileName  = "PageInfo"
fileprivate let kCurrentAfterKey = "currentAfter"
fileprivate let kCurrentTopPostKey = "currentTopPost"

class Model {
   
   /* singletone to speedup development */
   private init() {
      
   }
   static let defaultModel:Model = Model()
   /*-----*/
   
   weak var delegate:ModelDelegate?
   
   private var entries:[EntrySerializable] = [EntrySerializable]()
   private var currentAfter:String?
   private var currentFullSizeImageURL:String?
   
   private var isLoadingFromChacheInProcess = false
   var currentTopPost:String?
   
   func getNextEntries() {
      
      if isLoadingFromChacheInProcess {
         return
      }
      
      RequestsHandler.getNextTop(after: currentAfter, completion: { [weak self] (aData) in
         
         do {
            let parsedData = try JSONDecoder().decode(ResponseRoot.self,
                                                      from: aData)
            if let theAfter = parsedData.data.after {
               self?.currentAfter =  theAfter
               
            }
            
            //print("After: \(self?.currentAfter ?? "empty")")
            
            if let children = parsedData.data.children,
               !children.isEmpty {
               
               let entries = children.compactMap { $0.entry }
               self?.entries.append(contentsOf: entries)
            
            }
         }
         catch (let error) {
            
            dispatchOnMainQueue {
               
               let name = NSNotification.Name(kPostsLoadingErrorNotification)
               NotificationCenter.default.post(name: name,
                                               object: self,
                                               userInfo: ["error": error])
            }
         }
         
         dispatchOnMainQueue {
            self?.delegate?.modelDidGetNextEntries()
         }
         
      }) { (anError) in
         
         if let error = anError {
            
            dispatchOnMainQueue {
               
               let name = NSNotification.Name(kPostsLoadingErrorNotification)
               NotificationCenter.default.post(name: name,
                                               object: self,
                                               userInfo: ["error": error])
            }
         }
      }
   }
   
   //MARK: DataSource
   var entriesCount:Int {
      return entries.count
   }
   
   func entryFor(_ indexPath:IndexPath) -> EntrySerializable? {
      if indexPath.row < entriesCount {
         return entries[indexPath.row]
      }
      return nil
   }
   
   func thumbnailFor(_ indexPath:IndexPath) -> UIImage? {
      guard let entry = entryFor(indexPath),
         let imageUrl = entry.thumbURL else {
         return nil
      }
      
      if let cachedImage = ImageCache.cache.imageFor(imageUrl) {
         return cachedImage
      }
      
      RequestsHandler.downloadImageFor(imageUrl)
      
      return nil
   }
   
   func indexPathForThumbUrl(_ urlString:String) -> IndexPath? {
      if let rowIndex = entries.firstIndex(where: {$0.thumbURL == urlString}) {
         return IndexPath(row: rowIndex, section: 0)
      }
      return nil
   }
   
   func indexPathForPostId(_ postId:String) -> IndexPath? {
      if let rowIndex = entries.firstIndex(where: {$0.id == postId}) {
         return IndexPath(row: rowIndex, section: 0)
      }
      return nil
   }
   
   func imageFor(_ urlString:String) -> UIImage? {
      
      guard let cachedImage = ImageCache.cache.imageFor(urlString) else {
         return nil
      }
      
      return cachedImage
   }
   
   func getFullSizeImage(_ completion: @escaping (UIImage?)->() ) {
      
      guard let urlString = currentFullSizeImageURL else {
         completion(nil)
         return
      }
      
      if let imageFromChache = imageFor(urlString) {
         completion(imageFromChache)
         return
      }
      
      RequestsHandler.downloadImageFor(urlString) { (aImage) in
         dispatchOnMainQueue {
            completion(aImage)
         }
      }
   }
   
   func setCurrentFullSizeImageURL(_ urlString:String?) {
      currentFullSizeImageURL = urlString
   }
   
   //MARK: - State preservation
   func saveStateToDisk() {
      do {
         let encoder = JSONEncoder()
         let entriesData = try encoder.encode(entries)
         let fileManager = FileManager.default
         
         guard let cacheDirectoryPath = cacheURL() else { return }
         
         let fileName = kPostEntriesFileName
         let fileURL = cacheDirectoryPath.appendingPathComponent(fileName,
                                                                 isDirectory: false)
         //write data to disk
         if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
         }
         
         let created = fileManager.createFile(atPath: fileURL.path,
                                              contents: entriesData,
                                              attributes: nil)
         
         //save current pageData to have a point to scroll to after data restoration
         if created {
            guard let currentTopPostId = currentTopPost,
                  let currentAfterId = currentAfter else {
                  return
            }
            
            let currentPageData = [kCurrentAfterKey: currentAfterId,
                                   kCurrentTopPostKey: currentTopPostId]
            
            let pageData = try encoder.encode(currentPageData)
            
            let pageInfoFileName = cacheDirectoryPath.appendingPathComponent(kPageInfoFileName,
                                                                            isDirectory: false)
            
            //write data to disk
            
            if fileManager.fileExists(atPath: pageInfoFileName.path) {
               try fileManager.removeItem(at: pageInfoFileName)
            }
            
            fileManager.createFile(atPath: pageInfoFileName.path,
                                   contents: pageData,
                                   attributes: nil)
         }
         
      }
      catch (let error) {
         print("Failed to save state to disk: \n - error:\n\(error.localizedDescription)")
      }
   }
   
   func loadStateFromDisk() {
      isLoadingFromChacheInProcess = true
//      print("Loading data from cache.")
      guard let cacheURL = cacheURL() else {
         print("No Cache found. Finished Loading data from cache.")
         isLoadingFromChacheInProcess = false
         return
      }
      
      let pageInfoFilePath = cacheURL.appendingPathComponent(kPageInfoFileName,
                                                            isDirectory: false)
      let savedPostsFilePath = cacheURL.appendingPathComponent(kPostEntriesFileName,
                                                               isDirectory: false)
      let fileManager = FileManager.default
      
      if fileManager.fileExists(atPath: savedPostsFilePath.path) {
         
         let decoder = JSONDecoder()
         
         do {
            // try to decode saved posts
            let postsData = try Data(contentsOf: savedPostsFilePath)
            let entriesDecoded = try decoder.decode([EntrySerializable].self, from: postsData)
            self.entries = entriesDecoded
            
            //try to decode topMost post info to be able to scroll towards it
            if fileManager.fileExists(atPath: pageInfoFilePath.path) {
               let pageInfoData = try Data(contentsOf: pageInfoFilePath)
               let pageInfo = try decoder.decode([String:String].self, from: pageInfoData)
               self.currentTopPost = pageInfo[kCurrentTopPostKey]
               self.currentAfter = pageInfo[kCurrentAfterKey]
            }
         }
         catch (let error) {
            print("Error while decoding Saved Data: \n \(error.localizedDescription)")
         }
      }
      else {
         print("No Saved Posts Found.")
      }
      
//      print("Finished Loading data from cache.")
//      print("Current Top Post:  \(currentTopPost ?? "NULL")")
      
      isLoadingFromChacheInProcess = false
      
      if self.entries.count > 0 {
         dispatchOnMainQueue {[weak self] in
            self?.delegate?.modelDidGetNextEntries()
         }
      }
   }
   
   private func cacheURL() -> URL? {
      guard let cacheURL = FileManager.default.urls(for: .cachesDirectory,
                                                    in: .userDomainMask).first else {
         return nil
      }
      return cacheURL
   }
}

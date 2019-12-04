//
//  ResponseSerializable.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation

struct ResponseRoot: Codable {
   let kind:String
   let data:ResponseDataSerializable
   
   enum CodingKeys:String, CodingKey {
      case kind
      case data
   }
}

struct ResponseDataSerializable: Codable {
   let after:String?
   let dist:Int?
   let children:[ChildSerializable]?
   
   enum CodingKeys:String, CodingKey {
      case after
      case dist
      case children
   }
}

struct ChildSerializable: Codable {
   let kind:String?
   let entry:EntrySerializable?
   
   enum CodingKeys:String, CodingKey {
      case kind
      case entry = "data"
   }
}

struct EntrySerializable: Codable {
   let author:String?
   let title:String?
   let created:Int?
   let thumbURL:String?
   let imageURL:String?
   let commentsCount:Int?
   let isVideo:Bool?
   let id:String?
   
   var isTappable:Bool {
      var tappable = false
      
      if let videoBool = isVideo,
         videoBool == false,
         let imageURL = imageURL,
         (imageURL.hasSuffix(".jpg") || imageURL.hasSuffix(".png")) {
         
         tappable = true
      }
      return tappable
   }
   
   enum CodingKeys:String, CodingKey {
      case author
      case title
      case created
      case thumbURL = "thumbnail"
      case imageURL = "url"
      case commentsCount = "num_comments"
      case isVideo = "is_video"
      case id
   }
}

//
//  TableViewCell.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import UIKit



public class TableViewCell: UITableViewCell {

   static let reuseIdentifier = "EntryCell"
   
   @IBOutlet private var ibThumbIcon:UIImageView? {
      didSet {
         ibThumbIcon?.layer.borderColor = UIColor.red.cgColor
      }
   }
   @IBOutlet private var ibEntryTitleLabel:UILabel?
   @IBOutlet private var ibEntryAuthorLabel:UILabel?
   @IBOutlet private var ibDateLabel:UILabel?
   @IBOutlet private var ibCommentsCountLabel:UILabel?
   @IBOutlet private var ibCommentsTitleLabel:UILabel?
   
   var title:String? {
      didSet {
         ibEntryTitleLabel?.text = title
      }
   }
   
   var author:String? {
      didSet {
         ibEntryAuthorLabel?.text = author
      }
   }
   
   var thumbnail:UIImage? {
      didSet {
         ibThumbIcon?.image = thumbnail
      }
   }
   
   var datePublished:Date? {
      didSet {
         ibDateLabel?.text = datePublished?.prettyPrinted
      }
   }
   
   var commentsCount:Int = 0 {
      didSet {
         ibCommentsCountLabel?.text = "\(commentsCount)"
      }
   }
   
   var isTappable:Bool = false {
      didSet {
         ibThumbIcon?.layer.borderWidth = (isTappable) ? 1.0 : 0.0
      }
   }
    
}

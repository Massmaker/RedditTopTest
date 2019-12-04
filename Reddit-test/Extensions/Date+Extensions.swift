//
//  Date+Extensions.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation

extension Date {
   
   var prettyPrinted:String {
      
      //let currentDate = Date()
      var result = String()
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US")
      formatter.timeStyle = .medium
      formatter.dateStyle = .none
      formatter.doesRelativeDateFormatting = true
      
//      result = DateFormatter.localizedString(from: self, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium) ?? "No Date"
      
      result = formatter.string(from: self)
      
      let relFormatter = RelativeDateTimeFormatter()
      relFormatter.dateTimeStyle = .numeric
      relFormatter.unitsStyle = .full
      let test = relFormatter.localizedString(fromTimeInterval: self.timeIntervalSinceNow)
      result = test
      return result
   }
}

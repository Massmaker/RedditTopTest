//
//  NetworkErrors.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation
enum NetworkError : Error {
   case wrongURLFormat(string:String)
}

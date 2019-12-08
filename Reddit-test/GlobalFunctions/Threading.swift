//
//  Threading.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import Foundation

func dispatchOnMainQueue(_ action:@escaping ()->Void) {
   DispatchQueue.main.async(execute: action)
}

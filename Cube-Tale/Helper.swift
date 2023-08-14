//
//  Extensions.swift
//
//  Created by Michelle Faifer on 17/02/18.
//  Copyright © 2018 Micfaifer. All rights reserved.
//

import Foundation

class Helper {
    static func random(min: Int, max: Int) -> Int{
        let result = Int(arc4random_uniform(UInt32(max - min + 1))) +   min
        return result
    }
}

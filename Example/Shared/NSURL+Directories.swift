//
//  NSURL+Directories.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/17/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension NSURL {
    class func applicationDocumentsDirectory() -> NSURL {
        let urls = NSFileManager.default().urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)
        return urls[urls.count-1]
    }
}

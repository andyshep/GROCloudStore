//
//  NSURL+Directories.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 12/17/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension URL {
    static var applicationDocumentsDirectory: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.last!
    }
    
    static var applicationSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let identifier = Bundle.main.bundleIdentifier else {
            fatalError("missing bundle identifier")
        }
        
        guard let url = urls.last?.appendingPathComponent(identifier) else {
            fatalError("missing url for application support directory")
        }
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("error creating application support directory: \(error)")
        }
        
        return url
    }
}

//
//  Message.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/7/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    var imageUrl: String?
    
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    
    var videoUrl: String?
    
    init(dictionary: [String:Any]) {
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        toId = dictionary["toId"] as? String
        
        
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
        
    }
    
    
    
    
}

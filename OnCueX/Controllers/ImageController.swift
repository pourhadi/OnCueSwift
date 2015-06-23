//
//  ImageController.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/23/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AFNetworking

let _imageController = ImageController()
class ImageController: NSObject {
    
    var manager:AFHTTPRequestOperationManager = {
       var manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFImageResponseSerializer()
        return manager
    }()
    
    func getImage(fromURL:NSURL, complete:(url:NSURL, image:UIImage?)->Void) {
        manager.GET(fromURL.absoluteString, parameters: nil, success: { (op, image) -> Void in
            complete(url:fromURL, image:image as? UIImage)
            }) { (op, error) -> Void in
                complete(url: fromURL, image: nil)
        }
    }
}

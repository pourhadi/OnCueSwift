//
//  UIImageHelpers.swift
//  GifMaker
//
//  Created by Daniel Pourhadi on 3/14/15.
//  Copyright (c) 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage {

    class func draw(size:CGSize, block:(rect:CGRect)->Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        block(rect:CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizable() -> UIImage {
        return self.resizableImageWithCapInsets(UIEdgeInsetsMake((self.size.height/2)-1, (self.size.width/2)-1, self.size.height/2, self.size.width/2))
    }
    
    func imageByCropping(toFrame:CGRect) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(toFrame.size, true, self.scale)
        self.drawInRect(CGRectMake(-toFrame.origin.x, -toFrame.origin.y, self.size.width, self.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
        
    }
    
    class func playTriangle(forSize:CGSize, color:UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(forSize, false, 0.0)
        
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(0, 0))
        path.addLineToPoint(CGPointMake(forSize.width, forSize.height/2))
        path.addLineToPoint(CGPointMake(0, forSize.height))
        path.closePath()
        
        color.set()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
        
    }
    
    class func circledStepIcon(forSize:CGSize, color:UIColor) -> UIImage {
        
        var iconRect = CGRectMake(0, 0, forSize.width, forSize.height)
        iconRect = CGRectInset(iconRect, 8,8)
        iconRect.origin.x = (forSize.width - iconRect.size.width) / 2
        iconRect.origin.y = (forSize.height - iconRect.size.height) / 2
        
        let img = self.stepIcon(iconRect.size, color: color).imageWithRenderingMode(.AlwaysTemplate)
        
        UIGraphicsBeginImageContextWithOptions(forSize, false, 0.0)
        
        let path = UIBezierPath(ovalInRect: CGRectInset(CGRectMake(0,0,forSize.width,forSize.height), 1, 1))
        color.set()
        color.setStroke()
        path.stroke()
        img.drawInRect(iconRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func stepIcon(forSize:CGSize, color:UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(forSize, false, 0.0)
        
        let widthChunk = forSize.width / 3
        let barRect = CGRectMake(0, 0, widthChunk/2, forSize.height)
        color.setFill()
        UIRectFill(barRect)
        
        let triangleRect = CGRectMake(widthChunk, 0, forSize.width-widthChunk, forSize.height)
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(triangleRect.origin.x, triangleRect.origin.y))
        path.addLineToPoint(CGPointMake(triangleRect.origin.x, CGRectGetMaxY(triangleRect)))
        path.addLineToPoint(CGPointMake(CGRectGetMaxX(triangleRect), triangleRect.origin.y + (triangleRect.size.height / 2)))
        path.addLineToPoint(CGPointMake(triangleRect.origin.x, triangleRect.origin.y))
        path.closePath()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func pauseImage(forSize:CGSize, color:UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(forSize, false, 0.0)
        
        color.setFill()
        let left = CGRectMake(0, 0, forSize.width/3, forSize.height)
        UIRectFill(left)
        
        let right = CGRectMake((forSize.width/3 * 2), 0, forSize.width/3, forSize.height)
        UIRectFill(right)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
        
    }

}

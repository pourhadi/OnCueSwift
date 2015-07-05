//
//  StackedImageView.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import CoreMotion


class StackedImageView : UIView {
    
    var xAdjustment:CGFloat = 0.3
    var yAdjustment:CGFloat = 0.8
    
    var imageViews = [UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    
    var image:UIImage? {
        didSet {
            self.redraw()
        }
    }
    
    func redraw() {
        if let image = self.image {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
            var scaledFrame = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(0.5, 0.5))
            scaledFrame.origin.x = (self.bounds.size.width - scaledFrame.size.width) / 2
            scaledFrame.origin.y = (self.bounds.size.height - scaledFrame.size.height) / 2
            let bez = UIBezierPath(ovalInRect: scaledFrame)
            CGContextAddPath(UIGraphicsGetCurrentContext(), bez.CGPath)
            bez.addClip()
            image.drawInRect(scaledFrame)
            let drawn = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
            CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 2), 4, UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor)
            drawn.drawInRect(CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height))
            let withShadow = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            var x = 0
            for imageView in self.imageViews {
                self.insertSubview(imageView, atIndex: 0)
                imageView.transform = CGAffineTransformIdentity
                imageView.frame = self.bounds
                imageView.image = withShadow
                let scale:CGFloat = 1 - (CGFloat(x) * 0.025)
                imageView.transform = CGAffineTransformMakeScale(scale, scale)
                
                x += 1
            }
            
        }
    }
    
    func adjustOffsets() {

        for var x = self.imageViews.count-1; x >= 0; x-- {
            let min:CGFloat = -(CGFloat(x) * 10)
            let max = -min
            let xTranslate = ExtrapolateValue(min, max, xAdjustment)
            let yTranslate = ExtrapolateValue(min, max, yAdjustment)
            
            let imgView = self.imageViews[x]
            imgView.transform = CGAffineTransformTranslate(imgView.transform, xTranslate, yTranslate)
        }
    }
}

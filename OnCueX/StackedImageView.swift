//
//  StackedImageView.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import CoreMotion
import ReactiveCocoa

class StackedImageViewLayer : CALayer {
    
    let xAdjustmentSubject:RACSignal = RACSubject()
    let yAdjustmentSubject:RACSignal = RACSubject()
    
    @objc
    dynamic var xAdjustment:CGFloat = 0 {
        didSet {
            let sub = xAdjustmentSubject as! RACSubject
            sub.sendNext(self.xAdjustment)
        }
    }
    
    @objc
    dynamic var yAdjustment:CGFloat = 0 {
        didSet {
            let sub = yAdjustmentSubject as! RACSubject
            sub.sendNext(self.yAdjustment)
        }
    }
    
}

class StackedImageView : UIView {
    
    override class func layerClass() -> AnyClass {
        return StackedImageViewLayer.self
    }
    
    init() {
        super.init(frame:CGRectZero)
        let xMotion = UIInterpolatingMotionEffect(keyPath: "xAdjustment", type: .TiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = 0
        xMotion.maximumRelativeValue = 1
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "yAdjustment", type: .TiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = 0
        yMotion.maximumRelativeValue = 1
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        self.addMotionEffect(group)
        
        let stackedLayer = self.layer.presentationLayer() as! StackedImageViewLayer
        stackedLayer.xAdjustmentSubject.subscribeNext { [weak self] (val) -> Void in
            if let this = self {
                this.xAdjustment += stackedLayer.xAdjustment
            }
        }
        
        stackedLayer.yAdjustmentSubject.subscribeNext { [weak self] (val) -> Void in
            if let this = self {
                this.yAdjustment += stackedLayer.yAdjustment
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var xAdjustment:CGFloat = 0.5 {
        didSet {
            self.adjustOffsets()
        }
    }
    var yAdjustment:CGFloat = 0 {
        didSet {
            self.adjustOffsets()
        }
    }
    
    var imageViews = [UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    
    var image:UIImage? {
        didSet {
            self.redraw()
        }
    }
    
    func redraw() {
        if let image = self.image {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
                var scaledFrame = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(0.7, 0.7))
                scaledFrame.origin.x = (self.bounds.size.width - scaledFrame.size.width) / 2
                scaledFrame.origin.y = (self.bounds.size.height - scaledFrame.size.height) / 2
                let bez = UIBezierPath(ovalInRect: scaledFrame)
                CGContextAddPath(UIGraphicsGetCurrentContext(), bez.CGPath)
                bez.addClip()
                image.drawInRect(scaledFrame)
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
                CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 0), 5, UIColor.blackColor().colorWithAlphaComponent(0.8).CGColor)
                drawn.drawInRect(CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height))
                let withShadow = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var x = 0
                    for imageView in self.imageViews {
                        self.insertSubview(imageView, atIndex: 0)
                        imageView.transform = CGAffineTransformIdentity
                        imageView.frame = self.bounds
                        imageView.image = withShadow
                        let scale:CGFloat = 1 - (CGFloat(x) * 0.03)
                        imageView.transform = CGAffineTransformMakeScale(scale, scale)
                        
                        x += 1
                    }
                })
            })
        }
    }
    
    func adjustOffsets() {

        for var x = self.imageViews.count-1; x >= 0; x-- {
            let min:CGFloat = -(CGFloat(x) * 7)
            let max = -min
            let xTranslate = ExtrapolateValue(max, min, xAdjustment)
            let yTranslate = ExtrapolateValue(max, min, yAdjustment)
            
            let imgView = self.imageViews[x]
            let scale:CGFloat = 1 - (CGFloat(x) * 0.03)
            imgView.transform = CGAffineTransformIdentity
            imgView.transform = CGAffineTransformMakeScale(scale, scale)
            imgView.transform = CGAffineTransformTranslate(imgView.transform, xTranslate, yTranslate)
        }
    }
}

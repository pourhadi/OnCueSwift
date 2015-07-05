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

protocol StackedLayerDelegate:class {
    func motionUpdated()
}

class StackedImageViewLayer : CALayer {
    
    override init() {
        super.init()
    }
    
    override init(layer: AnyObject) {
        super.init(layer: layer)
        if let layer = layer as? StackedImageViewLayer {
            self.motionDelegate = layer.motionDelegate
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var motionDelegate:StackedLayerDelegate!

    @objc
    dynamic var xAdjustment:CGFloat = 0 {
        didSet {
            self.motionDelegate.motionUpdated()
        }
    }
    
    @objc
    dynamic var yAdjustment:CGFloat = 0 {
        didSet {
            self.motionDelegate.motionUpdated()
        }
    }
    
    override class func needsDisplayForKey(key:String) -> Bool {
        if key == "xAdjustment" || key == "yAdjustment" {
            return true
        }
        return super.needsDisplayForKey(key)
    }
}

class StackedImageView : UIView, StackedLayerDelegate {
    
    func motionUpdated() {
        guard let presLayer = self.layer.presentationLayer() else { return }
        print("layer x: \((presLayer as! StackedImageViewLayer).xAdjustment)")
        print("layer y: \((presLayer as! StackedImageViewLayer).yAdjustment)")
        self.xAdjustment += (presLayer as! StackedImageViewLayer).xAdjustment
        self.yAdjustment += (presLayer as! StackedImageViewLayer).yAdjustment
    }
    
    override class func layerClass() -> AnyClass {
        return StackedImageViewLayer.self
    }
    
    init() {
        super.init(frame:CGRectZero)
        (self.layer as! StackedImageViewLayer).motionDelegate = self

        let xMotion = UIInterpolatingMotionEffect(keyPath: "xAdjustment", type: .TiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = 0
        xMotion.maximumRelativeValue = 1
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "yAdjustment", type: .TiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = 0
        yMotion.maximumRelativeValue = 1
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        self.addMotionEffect(group)
        
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

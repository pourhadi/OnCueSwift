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

protocol StackedImageViewDataSource:Identifiable {
    var numberOfItemsInStack:Int { get }
    func getImagesForStack(size:CGSize, complete:(context:StackedImageViewDataSource, images:[UIImage])->Void)
}

protocol StackedLayerDelegate:class {
    var xAdjustment:CGFloat { get set }
    var yAdjustment:CGFloat { get set }
    func motionUpdated(layer:StackedImageViewLayer)
}

class StackedImageViewLayer : CALayer {
    
    override init() {
        super.init()
    }
    
    override init(layer: AnyObject) {
        if let layer = layer as? StackedImageViewLayer {
            self.motionDelegate = layer.motionDelegate
        }
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var motionDelegate:StackedLayerDelegate!

    @objc
    dynamic var xAdjustment:CGFloat {
        get {
            return self.motionDelegate.xAdjustment
        }
        set {
            self.motionDelegate.xAdjustment = newValue
        }
    }
    
    @objc
    dynamic var yAdjustment:CGFloat {
        get {
            return self.motionDelegate.yAdjustment
        }
        set {
            self.motionDelegate.yAdjustment = newValue
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
    
    func motionUpdated(layer:StackedImageViewLayer) {

        self.motionX = layer.xAdjustment
        self.motionY = layer.yAdjustment
    }
    
    override class func layerClass() -> AnyClass {
        return StackedImageViewLayer.self
    }
   
    var motionGroup:UIMotionEffectGroup
    
    init() {

        let xMotion = UIInterpolatingMotionEffect(keyPath: "xAdjustment", type: .TiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -0.5
        xMotion.maximumRelativeValue = 0.5
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "yAdjustment", type: .TiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -0.5
        yMotion.maximumRelativeValue = 0.5
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        self.motionGroup = group
        super.init(frame:CGRectZero)
        (self.layer as! StackedImageViewLayer).motionDelegate = self
        self.addMotionEffect(group)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var motionX:CGFloat = 0 {
        didSet {
            self.adjustOffsets()
        }
    }
    var motionY:CGFloat = 0 {
        didSet {
            self.adjustOffsets()
        }
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
    
    var disableMotion:Bool = false {
        didSet {
            if self.disableMotion {
                self.removeMotionEffect(self.motionGroup)
            } else {
                if oldValue == true {
                    self.addMotionEffect(self.motionGroup)
                }
            }
        }
    }
    
    func resetImageViews() {
        self.imageViews.removeAll()
        for imgView in self.disabledImageViews {
            imgView.alpha = 0
        }
    }
    
    var dataSource:StackedImageViewDataSource? {
        didSet {
            self.resetImageViews()
            if let dataSource = self.dataSource {
                let numOfItems = self.disabledImageViews.count
                for x in 0..<numOfItems {
                    let imgView = self.disabledImageViews[x]
                    self.imageViews.append(imgView)
                }
                
                dataSource.getImagesForStack(self.imageSize, complete: { (context, images) -> Void in
                    guard dataSource.isEqual(context) else { return }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        var croppedImages:[UIImage] = images.map({ (image) -> UIImage in
                            return self.cropped(image)
                        })
                        
                        if croppedImages.count == 0 {
                            return
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            UIView.animateWithDuration(0.2, animations: { () -> Void in
                                var x = 0
                                for imageView in self.imageViews {
                                    var thisImage:UIImage
                                    if x < croppedImages.count {
                                        thisImage = croppedImages[x]
                                    } else {
                                        thisImage = croppedImages.last!
                                    }
                                    self.insertSubview(imageView, atIndex: 0)
                                    imageView.transform = CGAffineTransformIdentity
                                    imageView.frame = self.bounds
                                    imageView.image = thisImage
                                    let scale:CGFloat = 1 - (CGFloat(x) * 0.01)
                                    imageView.transform = CGAffineTransformMakeScale(scale, scale)
                                    imageView.alpha = 1
                                    x += 1
                                }
                                self.adjustOffsets()
                            })
                        })

                    })
                    
                })
            }
        }
    }
    
    var disabledImageViews:[UIImageView] = [UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    var imageViews = [UIImageView]()
    
    var image:UIImage? {
        didSet {
            self.redraw()
        }
    }
    
    var imageSize:CGSize {
        let scaledFrame = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(0.7, 0.7))
        return scaledFrame.size
    }
    
    func cropped(image:UIImage)->UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
        var scaledFrame = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(0.7, 0.7))
        scaledFrame.origin.x = (self.bounds.size.width - scaledFrame.size.width) / 2
        scaledFrame.origin.y = (self.bounds.size.height - scaledFrame.size.height) / 2
        let bez = UIBezierPath(ovalInRect: scaledFrame)
//        CGContextSaveGState(UIGraphicsGetCurrentContext())
      //  bez.addClip()
        CGContextClipToRect(UIGraphicsGetCurrentContext(), scaledFrame)
        image.drawInRect(scaledFrame)
//        CGContextRestoreGState(UIGraphicsGetCurrentContext())

        CGContextAddPath(UIGraphicsGetCurrentContext(), bez.CGPath)
        CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor)
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 2)
        CGContextStrokeRect(UIGraphicsGetCurrentContext(), scaledFrame)
        let drawn = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
        CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 0), 20, UIColor.blackColor().colorWithAlphaComponent(1).CGColor)
        drawn.drawInRect(CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height))
        let withShadow = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return withShadow
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
                CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 0), 20, UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor)
                drawn.drawInRect(CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height))
                let withShadow = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        var x = 0
                        for imageView in self.imageViews {
                            self.insertSubview(imageView, atIndex: 0)
                            imageView.transform = CGAffineTransformIdentity
                            imageView.frame = self.bounds
                            imageView.image = withShadow
                            let scale:CGFloat = 1 - (CGFloat(x) * 0.01)
                            imageView.transform = CGAffineTransformMakeScale(scale, scale)
                            imageView.alpha = 1
                            x += 1
                        }
                        self.adjustOffsets()
                    })
                })
            })
        } else {
            for imageView in self.imageViews {
                imageView.image = nil
                imageView.alpha = 0
            }
        }
    }
    
    func adjustOffsets() {

        for var x = self.imageViews.count-1; x >= 0; x-- {
            let min:CGFloat = -(CGFloat(x) * 4)
            let max = -min
            let xTranslate = ExtrapolateValue(max, min, (motionX))
            let yTranslate = ExtrapolateValue(max, min, (yAdjustment+motionY))
            
            let imgView = self.imageViews[x]
            let scale:CGFloat = 1 - (CGFloat(x) * 0.01)
            imgView.transform = CGAffineTransformIdentity
            imgView.transform = CGAffineTransformMakeScale(scale, scale)
            imgView.transform = CGAffineTransformTranslate(imgView.transform, xTranslate, yTranslate)
        }
    }
}

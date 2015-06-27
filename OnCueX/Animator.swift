//
// Created by Daniel Pourhadi on 4/16/15.
// Copyright (c) 2015 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import QuartzCore

public protocol AnimationItem {

    weak var group:AnimationGroup? { get set }
    var duration:NSTimeInterval { get set }
    var easingFunction:EasingFunction? { get set }

}

public class AnimationGroup : AnimationItem {

    var animations = [AnimationItem]()
    var completionBlock:(()->Void)?

    func addAnimation(var animation:AnimationItem) {
        if animation is Animation {
            var anim = animation as! Animation
            anim.group = self
            animations.append(anim)
            return
        }
        animations.append(animation)
    }

    weak public var group:AnimationGroup?
    public var duration:NSTimeInterval = 0
    public var easingFunction:EasingFunction?
}
// // t: current time, b: begInnIng value, c: change In value, d: duration
public typealias EasingFunction = ((currentTime:NSTimeInterval, beginningValue:CGFloat, changeInValue:CGFloat, duration:NSTimeInterval) -> CGFloat)

public class Animation : AnimationItem {

    private var _easingFunction:EasingFunction?
    public var easingFunction:EasingFunction? {
        get {
            if _easingFunction == nil {
                if let group = self.group {
                    return group.easingFunction
                }
            }
            return _easingFunction
        }

        set {
            _easingFunction = newValue
        }
    }

    private var _duration:NSTimeInterval = 0
    public var duration:NSTimeInterval {
        get {
            if _duration == 0 {
                if let group = self.group {
                    return group.duration
                }
            }
            return _duration
        }
        set {
            _duration = newValue
        }
    }

    public var easingPath:UIBezierPath?
    public var then:AnyObject?
    public var completionBlock:(()->Void)?
    public var delay:NSTimeInterval = 0
    weak public var view:UIView? { didSet { self.fromValue = self.view!.valueForKeyPath(self.keyPath!) as! CGFloat } }
    public var fromValue:CGFloat = 0

    weak public var group:AnimationGroup?
    public var keyPath:String?
    public var toValue:CGFloat = 0

    private var started:Bool = false
    private var finished:Bool = false
    private var startedTime:NSTimeInterval = 0

    public init(keyPath:String) { self.keyPath = keyPath }

}

public class AnimationBuilder {

    public final var frame:AnimationItem { return Animation(keyPath:"frame") }
    public final var affineTransform:AnimationItem { return Animation(keyPath:"transform") }
    public final var centerX:AnimationItem { return Animation(keyPath:"center.x") }
    public final var centerY:AnimationItem { return Animation(keyPath:"center.y") }
}

class Animator:NSObject {

    var displayLink:CADisplayLink?

    var startTime:NSTimeInterval = 0

    var currentAnimation:AnimationItem?

    func beginAnimations(animation:AnimationItem) {
        self.currentAnimation = animation

        self.displayLink = CADisplayLink(target: self, selector: "animationStep")
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        self.startTime = self.displayLink!.timestamp
    }
    
    func animationStep() {
        if (self.startTime == 0) {
            self.startTime = self.displayLink!.timestamp
        }
        var elapsed = self.displayLink!.timestamp - self.startTime

        if self.currentAnimation is AnimationGroup {
            let group = self.currentAnimation as! AnimationGroup

            var statuses = group.animations.map { return ($0 as! Animation).finished }
            var allDone:Bool = statuses.reduce(true) { $0 && $1 }

            if allDone {
                if group.completionBlock != nil {
                    group.completionBlock!()
                }
                self.displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
                self.displayLink = nil
                return
            }

            for animation in group.animations {
                elapsed = self.displayLink!.timestamp - self.startTime
                var animation = animation as! Animation

                if animation.finished {
                    continue
                }

                if !animation.started {
                    if elapsed >= animation.delay {
                        animation.started = true
                        animation.startedTime = self.displayLink!.timestamp
                    } else {
                        continue
                    }
                }

                elapsed = self.displayLink!.timestamp - animation.startedTime
                if elapsed > animation.duration {
                    animation.finished = true
                }

                var percentComplete:CGFloat = CGFloat(elapsed / animation.duration)
//                // println("percent: \(percentComplete)")

                var currentVal = animation.easingFunction!(currentTime: elapsed, beginningValue: animation.fromValue, changeInValue: animation.toValue, duration: animation.duration)
                animation.view!.setValue(currentVal, forKeyPath: animation.keyPath!)
            }

            return
        }

        let animation:Animation = self.currentAnimation as! Animation
        
        var percentComplete:CGFloat = CGFloat(elapsed / animation.duration)
        var currentVal = animation.easingFunction!(currentTime: elapsed, beginningValue: animation.fromValue, changeInValue: animation.toValue, duration: animation.duration)
        
        if (elapsed > animation.delay && currentVal > animation.toValue) {
            if animation.completionBlock != nil {
                animation.completionBlock!()
            }
            self.displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
            return
        }

        
        animation.view!.setValue(currentVal, forKeyPath: animation.keyPath!)
    }

}

let kEaseInOutBack = "inOutBack"
let kEaseInBack = "inBack"
let kEaseOutQuint = "kEaseOutQuint"

public let easingFunctions:[String:EasingFunction] = [
    kEaseOutQuint:{ (var t, b, c, d) -> CGFloat in
        t /= d
        var x:CGFloat = CGFloat(t*t*t*t) + b
        return c*(CGFloat(t)) * x
    },
    kEaseInOutBack:{ (t, b, c, d) -> CGFloat in
        var s:CGFloat = 1.70158
        var tF:CGFloat = CGFloat(t)
        var dF:CGFloat = CGFloat(d)
        if (CGFloat(tF /= dF/2) < 1) {
            var subb:CGFloat = (((s * (1.525)) + 1) * tF - s)
            var suba:CGFloat = (tF * tF * subb)
            return c/2 * suba + b
        }
        var subc:CGFloat = (((s*(1.525))+1)*tF + s)
        var sube:CGFloat = ((tF - 2) * tF * subc)
        var subd:CGFloat = (sube + 2.0)
        return c/2 * subd + b;
    },
    kEaseInBack:{(t, b, c, d) -> CGFloat in
        var s:CGFloat = 1.70158
        var tF:CGFloat = CGFloat(t / d)
        var dF:CGFloat = CGFloat(d)
        
        return c * tF * tF * ((s + 1) * tF - s) + b
        
//        c*(t/=d)*t*((s+1)*t - s) + b
    }
]

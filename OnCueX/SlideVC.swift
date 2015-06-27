//
//  SlideController.swift
//  OnCue8
//
//  Created by Dan Pourhadi on 6/22/14.
//  Copyright (c) 2014 Dan Pourhadi. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class CustomScrollView:UIScrollView {
    
    @objc
    dynamic var xOffset:CGFloat {
        get {
            return self.contentOffset.x
        }
        set {
            var offset = self.contentOffset
            offset.x = newValue
            self.contentOffset = offset
        }
    }
    
}

class SlideVC: UIViewController, UIScrollViewDelegate {
    
    let animatorObject = Animator()
    var currentPage = 0
    
    var queueContainer:UIView = UIView(frame: UIScreen.mainScreen().bounds)
    var libraryContainer:UIView = UIView(frame: UIScreen.mainScreen().bounds)
    var navContainer:UIView = UIView(frame: UIScreen.mainScreen().bounds)
    var scrollView:CustomScrollView = CustomScrollView(frame: UIScreen.mainScreen().bounds)
    
    let navVC:NavVC = NavVC(rootViewController: UIViewController(nibName: nil, bundle: nil))
    
    var navContainerAttachment:UIAttachmentBehavior?
    var libraryContainerAttachment:UIAttachmentBehavior?
    var queueContainerAttachment:UIAttachmentBehavior?
    var animator:UIDynamicAnimator?
    
    var queueContainerWidthConstraint:NSLayoutConstraint?
    var libraryContainerWidthConstraint:NSLayoutConstraint?
    var navContainerWidthConstraint:NSLayoutConstraint?
    
    lazy var containers:[UIView] = [self.navContainer, self.libraryContainer, self.queueContainer]
    var viewControllers:[Int:UIViewController] = [:]
    
    func setViewController(viewController:UIViewController, forSlotIndex:Int) {
        if let currentVC = self.viewControllers[forSlotIndex] {
            currentVC.willMoveToParentViewController(nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParentViewController()
            self.viewControllers.removeValueForKey(forSlotIndex)
        }
        
        let container = containers[forSlotIndex]
        viewController.willMoveToParentViewController(self)
        viewController.view.frame = container.bounds

        container.addSubview(viewController.view)
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
        self.viewControllers[forSlotIndex] = viewController
        
        self.view.layoutIfNeeded()
    }
    
    override func loadView() {
        self.view = UIView(frame: UIScreen.mainScreen().bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func configureAttachment(attachment:UIAttachmentBehavior) {
            attachment.frequency = 1.8
            attachment.damping = 0.55
            attachment.action = { [unowned attachment, unowned self] in
                attachment.anchorPoint = CGPointMake(attachment.anchorPoint.x, self.view.center.y)
            }
            let itemBehavior = UIDynamicItemBehavior(items: attachment.items)
            itemBehavior.allowsRotation = false
            attachment.addChildBehavior(itemBehavior)
        }
        
        scrollView.frame = self.view.bounds
        queueContainer.frame = self.view.bounds
        libraryContainer.frame = self.view.bounds
        navContainer.frame = self.view.bounds
        
        self.view.addSubview(scrollView)
        scrollView.addSubview(queueContainer)
        scrollView.addSubview(libraryContainer)
        scrollView.addSubview(navContainer)
        
        scrollView.contentSize = CGSizeMake(self.view.bounds.size.width*3, self.view.bounds.size.height)
        scrollView.delegate = self
        scrollView.directionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.pagingEnabled = true
        
        var f = self.view.bounds
        navContainer.frame = f
        
        f.origin.x = self.view.bounds.size.width*2
        libraryContainer.frame = f
        
        f.origin.x = self.view.bounds.size.width*3
        queueContainer.frame = f
        
        navContainerAttachment = UIAttachmentBehavior(item: navContainer, attachedToAnchor: navContainer.center)
        libraryContainerAttachment = UIAttachmentBehavior(item: libraryContainer, attachedToAnchor: libraryContainer.center)
        queueContainerAttachment = UIAttachmentBehavior(item: queueContainer, attachedToAnchor: queueContainer.center)
        
        configureAttachment(navContainerAttachment!)
        configureAttachment(libraryContainerAttachment!)
        configureAttachment(queueContainerAttachment!)
        
        animator = UIDynamicAnimator(referenceView: self.scrollView)
        
        animator!.addBehavior(navContainerAttachment!)
        animator!.addBehavior(libraryContainerAttachment!)
        animator!.addBehavior(queueContainerAttachment!)

        
    //    self.addChildViewController(globalLibraryVC)
     //   globalLibraryVC.view.frame = libraryContainer.bounds
      //  libraryContainer.addSubview(globalLibraryVC.view)
       // globalLibraryVC.didMoveToParentViewController(self)
        
        self.addChildViewController(navVC)
        navVC.view.frame = navContainer.bounds
        navContainer.addSubview(navVC.view)
        navVC.didMoveToParentViewController(self)
        
        self.scrollView.rac_signalForKeyPath("contentOffset", observer: self).subscribeNext { [weak self] (val) -> Void in
            if let this = self {
                var offset = this.scrollView.contentOffset.x
            }
        }

    }
    
    func scrollTo(offset:CGFloat, animated:Bool, complete:()->Void) {
        if animated {
            let animation = Animation(keyPath: "xOffset")
            animation.toValue = offset
            animation.easingFunction = easingFunctions[kEaseInOutBack]
            animation.duration = 0.6
            animation.completionBlock = complete
            animation.view = self.scrollView
            animatorObject.beginAnimations(animation)
        }
    }
    
      func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.x
        var currentXStart = self.view.frame.size.width * 2
        var nextXStart = self.view.bounds.size.width * 4
        var distance = -(self.view.bounds.size.width*2)
        var percent = self.scrollView.contentOffset.x / (self.view.bounds.size.width*2)
        var currentX = currentXStart + (distance * percent)
        var nextX = nextXStart + (distance * percent)
        currentX += self.view.bounds.size.width/2
        nextX += self.view.bounds.size.width/2

        func adjustNavContainerPosition() {
            let newX = (-offset) + self.view.bounds.size.width/2
            navContainerAttachment!.anchorPoint = CGPointMake(newX, self.view.center.y)
        }
        
        func adjustLibraryContainerPosition() {
            libraryContainerAttachment!.anchorPoint = CGPointMake(currentX, self.view.center.y)
        }
        
        func adjustQueueContainerPosition() {
            queueContainerAttachment!.anchorPoint = CGPointMake(nextX, self.view.center.y)
        }


        adjustNavContainerPosition()
        adjustLibraryContainerPosition()
        adjustQueueContainerPosition()
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
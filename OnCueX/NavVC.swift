//
//  NavVC.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/20/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class NavBar : UINavigationBar {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    override var barPosition:UIBarPosition {
        return .TopAttached
    }
 
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.delegate = self
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    
    
}

class NavVC: UIViewController, UINavigationBarDelegate, UINavigationControllerDelegate {

    let navController = UINavigationController(nibName: nil, bundle: nil)
    
    lazy var navBar:UINavigationBar = NavBar()

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func popViewControllerAnimated(animated:Bool) {
        self.navController.popViewControllerAnimated(animated)
        self.navBar.popNavigationItemAnimated(animated)
    }
    
    func pushViewController(viewController:UIViewController, animated:Bool) {
        self.navController.pushViewController(viewController, animated: animated)
        self.navBar.pushNavigationItem(viewController.navigationItem, animated: animated)
    }
    
    init(rootViewController:UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.pushViewController(rootViewController, animated: false)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navController.delegate = self
        self.navController.setNavigationBarHidden(true, animated: false)
        self.navBar.delegate = self
        self.navBar.backgroundColor = UIColor.blackColor()
        self.navBar.barTintColor = UIColor.blackColor()
        self.navBar.barStyle = .Black
        
        let black = UIImage.draw(CGSizeMake(4, 4)) { (rect) -> Void in
            UIColor.blackColor().setFill()
            UIRectFill(rect)
        }.resizable()
        self.navBar.setBackgroundImage(black, forBarMetrics: .Default)
        self.navBar.shadowImage = UIImage()
        // Do any additional setup after loading the view.
        
        self.view.addSubview(self.navBar)
        self.navController.willMoveToParentViewController(self)
        self.view.addSubview(self.navController.view)
        self.addChildViewController(self.navController)
        self.navController.didMoveToParentViewController(self)
        
        self.navBar.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view).offset(20)
        }
        
        self.navController.view.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.navBar.snp_bottom)
            make.bottom.left.right.equalTo(self.view)
        }
    }
    
    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
        self.navController.popViewControllerAnimated(true)
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

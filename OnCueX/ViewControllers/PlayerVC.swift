//
//  PlayerVC.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/26/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class TrackSlider : UIScrollView, UIScrollViewDelegate {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
}

class PlayerVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

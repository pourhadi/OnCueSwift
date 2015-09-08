//
//  ViewController.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/16/15.
//  Copyright (c) 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        spotify { (token) -> Void in
            print(token, terminator: "")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


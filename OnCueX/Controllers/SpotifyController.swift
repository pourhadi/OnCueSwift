//
//  SpotifyController.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

let _spotifyController = SpotifyController()
final internal class SpotifyController: NSObject {
    let clientID = "0ab2dfaddf644af88911dcf5ca5fc4f6"
    let clientSecret = "3e29644339794e72923a6e596eac764a"

    var token:String? {
        if let session = self.session {
            if session.isValid() {
                return session.accessToken
            }
        }
        return nil
    }
    
    var session:SPTSession?
    var validSession:Bool {
        if let session = self.session {
            return session.isValid()
        }
        return false
    }
    
    var loginCompletionBlock:((token:String?, error:NSError?)->Void)?
    var authVC:SPTAuthViewController {
        let vc = SPTAuthViewController.authenticationViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .OverCurrentContext
        vc.modalTransitionStyle = .CrossDissolve
        return vc
    }
}

extension SpotifyController: SPTAuthViewDelegate {
    
    func login(complete:(token:String?, error:NSError?)->Void) {
        if let token = self.token {
            complete(token: token, error: nil)
        } else {
            self.loginCompletionBlock = complete
            
            if let rootVC = _delegate.window?.rootViewController {
                rootVC.modalPresentationStyle = .CurrentContext
                rootVC.definesPresentationContext = true
                rootVC.presentViewController(self.authVC, animated: true, completion: nil)
            }
        }
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        if let complete = self.loginCompletionBlock {
            print(error)
            complete(token: nil, error: error)
        }
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        self.session = session
        if let complete = self.loginCompletionBlock {
            complete(token: self.session?.accessToken, error: nil)
        }
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        if let complete = self.loginCompletionBlock {
            complete(token: nil, error: nil)
        }
    }

}

public func spotify(success:(token:String)->Void, failure:()->Void) {
    _spotifyController.login { (token, error) -> Void in
        if let token = token {
            success(token: token)
        } else {
            failure()
        }
    }
}

public func spotify(success:(token:String)->Void) {
    spotify(success) { () -> Void in
        
    }
}
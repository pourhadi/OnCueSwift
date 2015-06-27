//
//  UIManager.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/20/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

let _uiManager = _delegate.uiManager

extension UIManager: MainMenuVCDelegate {
    func mainMenuCellSelected(cell:MainMenuCell) {
        self.slideVC.scrollTo(self.slideVC.view.frame.size.width*2, animated: true) { () -> Void in
            print("animation complete")
        }
    }
}

class UIManager {

    lazy var spotifyManager:SpotifyManager = SpotifyManager(delegate:self)
    var slideVC:SlideVC = SlideVC()

    var browserNav:NavVC?
    
    func configure() {
        self.spotifyManager.getHomeVM { (vm) -> Void in
            let vc = ListVC(listVM: vm)
            let nav = NavVC(rootViewController: vc)
            self.slideVC.setViewController(nav, forSlotIndex: 1)
            self.browserNav = nav
            
            let queue = QueueVC(collectionViewLayout: ListLayout())
            let qNav = NavVC(rootViewController: queue)
            self.slideVC.setViewController(qNav, forSlotIndex: 2)
            
            let menu = MainMenuVC()
            menu.delegate = self
            self.slideVC.setViewController(menu, forSlotIndex: 0)
        }
    }
}

extension UIManager:ItemManagerDelegate {
    func itemManager(itemManager:ItemManager, pushVCForVM:ListVM) {
        let listVC = ListVC(listVM: pushVCForVM)
        if let nav = self.browserNav {
            nav.pushViewController(listVC, animated: true)
        }
    }
}
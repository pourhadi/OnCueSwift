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
    func mainMenuCellSelected(cell:MainMenuCell, title:MainMenuCellTitle) {
        if title == .Artists || title == .Albums || title == .Playlists {
            self.itemProvider.getCollections(SourceCollectionType(rawValue: title.rawValue)!).start({ (event) -> () in
                if let vm = event.value {
                    let listVC = ListVC(listVM: vm)
                    let nav = NavVC(rootViewController: listVC)
                    self.browserNav = nav
                    self.slideVC.setViewController(nav, forSlotIndex: 1)
                }
            })
        }
        self.slideVC.scrollTo(self.slideVC.view.frame.size.width, animated: true) { () -> Void in
            print("animation complete")
        }
    }
}

extension UIManager:ItemProviderDelegate {
    func itemProvider(provider:ItemProvider, pushVCForVM:ListVM) {
        let listVC = ListVC(listVM: pushVCForVM)
        if let nav = self.browserNav {
            nav.pushViewController(listVC, animated: true)
        }
    }
}

class UIManager {

    let itemProvider = ItemProvider()
        var slideVC:SlideVC = SlideVC()

    var browserNav:NavVC?
    
    func configure() {
        self.itemProvider.delegate = self
        let queue = QueueVC(collectionViewLayout: ListLayout())
        let qNav = NavVC(rootViewController: queue)
        self.slideVC.setViewController(qNav, forSlotIndex: 2)
        
        let menu = MainMenuVC()
        menu.delegate = self
        self.slideVC.setViewController(menu, forSlotIndex: 0)
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
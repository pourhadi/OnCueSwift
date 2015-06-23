//
//  ListVM.swift
//  
//
//  Created by Daniel Pourhadi on 6/19/15.
//
//

import UIKit
import ReactiveCocoa

protocol ListVMDelegate: class {
    func listVM(listVM:ListVM, selectedItem:protocol<Item>, deselect:(deselect:Bool)->Void)
}

struct ListVM {
    
    unowned var delegate:ListVMDelegate
//    let updatedSignal:RACSignal = RACSubject()
//    let pushVCSignal:RACSignal = RACSubject()
//    let itemSelectedSignal:RACSignal = RACSubject()
//    
//    internal var pushSubject:RACSubject { return self.pushVCSignal as! RACSubject }
//    
    init(list:ItemList, displayContext:DisplayContext, grouped:Bool, delegate:ListVMDelegate) {
        self.delegate = delegate
        self.list = list
        self.grouped = grouped
        self.displayContext = displayContext
        self.paginated = Int(list.totalCount) > list.items.count
//        super.init()
    }
    
    var displayContext:DisplayContext
    var groups:[[Item]] = []
    var list:ItemList
    var grouped:Bool
    var paginated:Bool
    
    func item(atIndexPath:NSIndexPath) -> Item {
        if self.grouped {
            return self.groups[atIndexPath.section][atIndexPath.row]
        }
        return self.list.items[atIndexPath.row]
    }
    
    func numberOfSections() -> Int {
        if self.grouped {
            return self.groups.count
        }
        return 1
    }
    
    func numberOfItems(section:Int) -> Int {
        if self.grouped {
            return self.groups[section].count
        }
        return self.list.items.count
    }
    
    func reuseIDForItem(indexPath:NSIndexPath) -> String {
        return self.item(indexPath).cellReuseID
    }
    
    func configureCell(cell:UICollectionViewCell, forItemAtIndexPath:NSIndexPath) {
        let item = self.item(forItemAtIndexPath)
        if cell is ListItemCell {
            let listCell = cell as! ListItemCell
            listCell.item = item
        }
    }
    
    func cellTapped(indexPath:NSIndexPath, deselect:(deselect:Bool)->Void) {
        self.delegate.listVM(self, selectedItem: self.item(indexPath), deselect:deselect)
    }
}

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

class ListVM {
    
    unowned var delegate:ListVMDelegate
//    let updatedSignal:RACSignal = RACSubject()
//    let pushVCSignal:RACSignal = RACSubject()
//    let itemSelectedSignal:RACSignal = RACSubject()
//    
//    internal var pushSubject:RACSubject { return self.pushVCSignal as! RACSubject }
//    
    init(lists:[ItemList], displayContext:DisplayContext, delegate:ListVMDelegate) {
        self.delegate = delegate
        self.lists = lists
        self.displayContext = displayContext
        self.paginated = false
//        self.paginated = Int(list.totalCount) > list.items.count
//        super.init()
    }
    
    var displayContext:DisplayContext
    var groups:[[ItemViewModel]] = []
    var lists:[ItemList]
    var paginated:Bool
    
    func item(atIndexPath:NSIndexPath) -> ItemViewModel {
        let list = self.lists[atIndexPath.section]
        return list.items[atIndexPath.row]
    }
    
    func numberOfSections() -> Int {
        return self.lists.count
    }
    
    func numberOfItems(section:Int) -> Int {
       return self.lists[section].items.count
    }
    
    func reuseIDForItem(indexPath:NSIndexPath) -> String {
        return self.item(indexPath).item.cellReuseID
    }
    
    func configureCell(cell:UICollectionViewCell, forItemAtIndexPath:NSIndexPath) {
        let item = self.item(forItemAtIndexPath)
        if cell is ListItemCell {
            let listCell = cell as! ListItemCell
            listCell.item = item
        }
    }
    
    func cellTapped(indexPath:NSIndexPath, deselect:(deselect:Bool)->Void) {
        self.delegate.listVM(self, selectedItem: self.item(indexPath).item, deselect:deselect)
    }
    
    deinit {
        print("ListVM deinit")
    }
}

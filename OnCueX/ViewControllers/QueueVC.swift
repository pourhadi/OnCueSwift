//
//  QueueVC.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

extension QueueVC: QueueObserver {
    var identifier:String {
        return "QueueVC"
    }
    
    func queueUpdated(queue:Queue) {
        let addedOps = _queue.operations.filter { (operation) -> Bool in
            if (operation.type == .Added) {
                return true
            }
            return false
        }
        let added = addedOps.map { (operation) -> Int in
            let index = operation.queueIndex!.index
            return index
        }
        let addedSet = NSMutableIndexSet()
        for index in added {
            addedSet.addIndex(index)
        }
        let removedOps = _queue.operations.filter { operation in
            if operation.type == .Removed {
                return true
            }
            return false
        }
        let removed = removedOps.map { (operation) -> Int in
            let index = operation.queueIndex!.index
            return index
        }
        let removedSet = NSMutableIndexSet()
        for index in removed {
            removedSet.addIndex(index)
        }
        
        self.collectionView!.performBatchUpdates({ () -> Void in
            self.collectionView!.insertSections(addedSet)
            self.collectionView!.deleteSections(removedSet)
        }, completion:nil)
    }
 
}

class QueueVC: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.backgroundColor = UIColor.blackColor()
        _queue.addObserver(self)
        self.collectionView!.registerClass(QueueCell.self, forCellWithReuseIdentifier: "queueCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return _queue.items.count
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        let queuedItem = _queue.items[section]
        return queuedItem.numberOfItems
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("queueCell", forIndexPath: indexPath) as! QueueCell
    
        let item = _queue.items[indexPath.section]
        let track = item.tracks[indexPath.row]
        cell.item = track
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.view.bounds.size.width, 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }

}

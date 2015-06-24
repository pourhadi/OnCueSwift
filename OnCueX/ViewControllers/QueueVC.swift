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
        let added = addedOps.map { (operation) -> [NSIndexPath] in
            let index = operation.queueIndex!.index
            if let item = operation.item {
                var array:[NSIndexPath] = []
                for x in index..<(index+item.numberOfItems) {
                    array.append(NSIndexPath(forItem: x, inSection: 0))
                }
                return array
            }
            return []
        }
        var finalAdded:[NSIndexPath] = []
        for paths in added {
            for path in paths {
                finalAdded.append(path)
            }
        }
        
        let removedOps = _queue.operations.filter { operation in
            if operation.type == .Removed {
                return true
            }
            return false
        }
        let removed = removedOps.map { (operation) -> [NSIndexPath] in
            let index = operation.queueIndex!.index
            if let item = operation.item {
                var array:[NSIndexPath] = []
                for x in index..<(index+item.numberOfItems) {
                    array.append(NSIndexPath(forItem: x, inSection: 0))
                }
                return array
            }
            return []
        }
        var finalRemoved:[NSIndexPath] = []
        for paths in removed {
            for path in paths {
                finalRemoved.append(path)
            }
        }
        self.collectionView!.performBatchUpdates({ () -> Void in
            self.collectionView!.insertItemsAtIndexPaths(finalAdded)
            self.collectionView!.deleteItemsAtIndexPaths(finalRemoved)
            }, completion: nil)
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
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return _queue.items.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("queueCell", forIndexPath: indexPath) as! QueueCell
    
        let item = _queue.items[indexPath.row]
        cell.item = item
        
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

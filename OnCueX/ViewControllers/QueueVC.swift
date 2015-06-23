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
        let added = queue.operations.filter { (operation) -> Bool in
            if (operation.type == .Added) {
                return true
            }
            return false
            }.map { (operation) -> NSIndexPath in
                return NSIndexPath(forItem: operation.queueIndex!.index, inSection: 0)
        }
        
        let removed = queue.operations.filter { operation in
            if operation.type == .Removed {
                return true
            }
            return false
            }.map { (operation) -> NSIndexPath in
                return NSIndexPath(forItem: operation.queueIndex!.index, inSection: 0)
        }
        
        self.collectionView!.performBatchUpdates({ () -> Void in
            self.collectionView!.insertItemsAtIndexPaths(added)
            self.collectionView!.deleteItemsAtIndexPaths(removed)
            }, completion: nil)
        
    }
}

class QueueVC: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        _queue.addObserver(self)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.registerClass(QueueCell.self, forCellWithReuseIdentifier: "queueCell")

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

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

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

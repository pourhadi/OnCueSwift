//
//  MainMenuVC.swift
//  
//
//  Created by Daniel Pourhadi on 6/20/15.
//
//

import UIKit
import SnapKit
let reuseIdentifier = "Cell"

class MainMenuCell : UICollectionViewCell {
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        self.contentView.addSubview(self.label)
        self.label.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20))
        }
        
        self.label.textColor = UIColor.whiteColor()
        self.label.font = UIFont.boldSystemFontOfSize(30)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum MainMenuCellTitle:String {
    case Search = "Search"
    case Artists = "Artists"
    case Albums = "Albums"
    case Playlists = "Playlists"
}

protocol MainMenuVCDelegate {
    func mainMenuCellSelected(cell:MainMenuCell, title:MainMenuCellTitle)
}


class MainMenuVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var delegate:MainMenuVCDelegate?
    
    let cellHeight:CGFloat = 80.0
    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())

    let cellTitles:[MainMenuCellTitle] = [.Search, .Artists, .Albums, .Playlists]
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.view.addSubview(self.collectionView)
        self.collectionView.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.height.equalTo(CGFloat(self.cellTitles.count) * self.cellHeight)
        }
        
        self.collectionView.backgroundColor = UIColor.blackColor()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView.registerClass(MainMenuCell.self, forCellWithReuseIdentifier: "menuCell")

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

     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


     func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return self.cellTitles.count
    }

     func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("menuCell", forIndexPath: indexPath) as UICollectionViewCell as! MainMenuCell
    
        cell.label.text = self.cellTitles[indexPath.row].rawValue
        // Configure the cell
    
        return cell
    }

    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.view.bounds.size.width, cellHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let del = self.delegate {
            del.mainMenuCellSelected(collectionView.cellForItemAtIndexPath(indexPath) as! MainMenuCell, title:self.cellTitles[indexPath.row])
        }
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

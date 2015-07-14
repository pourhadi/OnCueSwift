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
    
    let animator = Animator()
    func animateButtonsOut(complete:()->Void) {
        
        let group = AnimationGroup()
        for (x, cell) in self.collectionView.visibleCells().enumerate() {
            let animation = Animation(keyPath: "layer.transform.translation.x")
            animation.toValue = -self.view.bounds.size.width
            animation.easingFunction = easingFunctions[kEaseInBack]
            animation.duration = 0.4
            animation.delay = NSTimeInterval(x) * 0.05
            animation.view = cell
            group.addAnimation(animation)
        }
        
        group.completionBlock = complete
        animator.beginAnimations(group)
    }
    
    func animateButtonsIn() {
        
    }

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

        self.collectionView.directionalLockEnabled = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.view.addSubview(self.collectionView)
        self.collectionView.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.height.equalTo(CGFloat(self.cellTitles.count) * self.cellHeight)
        }
        
        self.collectionView.backgroundColor = UIColor.blackColor()
        self.collectionView.registerClass(MainMenuCell.self, forCellWithReuseIdentifier: "menuCell")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
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
    

}

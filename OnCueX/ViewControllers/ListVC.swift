//
//  ListVC.swift
//
//
//  Created by Daniel Pourhadi on 6/18/15.
//
//

import UIKit
import ReactiveCocoa

class ListVCDataSource:NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    private var listVC:ListVC
    init(_ listVC:AnyObject) {
        self.listVC = listVC as! ListVC
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.listVC.listVM.numberOfSections()
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.listVC.listVM.numberOfItems(section)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.listVC.listVM.reuseIDForItem(indexPath), forIndexPath: indexPath) as! UICollectionViewCell
        self.listVC.listVM.configureCell(cell, forItemAtIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.listVC.listVM.cellTapped(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.listVC.view.bounds.size.width, 60)
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

class ListVC: UIViewController {

    let listVM:ListVM
    lazy var dataSource:ListVCDataSource = ListVCDataSource(self)
    
    init(listVM:ListVM) {
        self.listVM = listVM
        
        super.init(nibName: nil, bundle: nil)
        self.setupBindings()
    }
    
    func setupBindings() {
        self.listVM.updatedSignal.subscribeNext { [weak self] (val) -> Void in
            if let this = self {
                this.collectionView.reloadData()
            }
        }
        
        self.listVM.pushVCSignal.subscribeNext { [weak self] (val) -> Void in
            if let this = self {
//                if let vm = val as? ListVM<Item> {
                    let vc = ListVC(listVM: val as! ListVM)
                    this.navigationController!.pushViewController(vc, animated: true)
//                }
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    lazy var collectionView:UICollectionView = {
        var view = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        view.delegate = self.dataSource
        view.dataSource = self.dataSource
        return view
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
        
        for (reuseID, cellClass) in CellFactory.cellTypes {
            self.collectionView.registerClass(cellClass, forCellWithReuseIdentifier: reuseID)
        }
        
        self.collectionView.reloadData()
    }
    

  }

//
//  QueueCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class QueueCell: UICollectionViewCell, QueuedItemObserver {
    
    func queueIndexUpdated(forItem:QueuedItem, queueIndex:QueueIndex?) {
        if let item = self.item {
            if item.isEqual(forItem) {
                
            }
        }
    }
    
    weak var item:QueuedItem? {
        didSet {
            if let item = self.item {
                item.observer = self
                self.itemLabelsView.titleLabel.text = item.title
                self.itemLabelsView.subtitleLabel.text = item.subtitle
                item.getImage(self.imageView.frame.size, complete: { (image) -> Void in
                    self.imageView.image = image
                })
            }
        }
    }
    
    let itemLabelsView = ItemLabelsView(frame: CGRectZero)
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.itemLabelsView.backgroundColor = UIColor.clearColor()
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.itemLabelsView)
        
        self.imageView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(80, 80))
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
        }
        
        self.itemLabelsView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.imageView.snp_right).offset(10)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-10)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

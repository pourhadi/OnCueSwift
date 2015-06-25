//
//  QueueCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class QueueCellIndexView : UIView {
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blackColor()
        self.addSubview(self.label)
        self.label.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        
        self.label.textColor = UIColor.whiteColor()
        self.label.textAlignment = .Center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(ovalInRect: self.bounds).CGPath
        maskLayer.frame = self.layer.bounds
        self.layer.mask = maskLayer
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class QueueCell: UICollectionViewCell, QueuedItemObserver {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
    
    deinit {
        if let item = self.item {
            item.observer = nil
        }
    }
    
    func queueIndexUpdated(forItem:Queued, queueIndex:QueueIndex?) {
        if let item = self.item {
            if item.isEqual(forItem) {
                if let index = queueIndex {
                    self.indexView.label.text = index.displayIndex
                }
            }
        }
    }
    
    weak var item:Queued? {
        didSet {
            if let item = self.item {
                item.observer = self
                self.itemLabelsView.titleLabel.text = item.displayInfo.title
                self.itemLabelsView.subtitleLabel.text = item.displayInfo.subtitle
                item.displayInfo.getImage(self.imageView.frame.size, complete: { (image) -> Void in
                    self.imageView.image = image
                })
            }
        }
    }
    
    let itemLabelsView = ItemLabelsView(frame: CGRectZero)
    var imageView = UIImageView()
    let indexView = QueueCellIndexView(frame: CGRectZero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.itemLabelsView.backgroundColor = UIColor.clearColor()
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.itemLabelsView)
        
        self.contentView.addSubview(self.indexView)

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
        let padding:CGFloat = 5
        self.indexView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.imageView).insets(UIEdgeInsetsMake(padding, padding, padding, padding))
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

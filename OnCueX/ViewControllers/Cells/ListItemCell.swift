//
//  ListItemTextCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import SnapKit

class ListCellIndexView: UIView {
    let label = UILabel()
    
    init() {
        super.init(frame:CGRectZero)
        self.backgroundColor = UIColor(white:0.1, alpha:1)
        
        self.addSubview(self.label)
        self.label.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        
        self.label.textAlignment = .Center
        self.label.textColor = UIColor.whiteColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ItemLabelsView: UIView {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        
        self.titleLabel.font = UIFont.boldSystemFontOfSize(16)
        self.titleLabel.textColor = UIColor.whiteColor()
        
        self.subtitleLabel.font = UIFont.boldSystemFontOfSize(12)
        self.subtitleLabel.textColor = UIColor.lightGrayColor()
        
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.top.right.equalTo(self)
            make.bottom.equalTo(self.subtitleLabel.snp_top).offset(-2)
        }
        
        self.subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.bottom.left.right.equalTo(self)
        }
        
        self.snp_updateConstraints { (make) -> Void in
            make.top.equalTo(self.titleLabel)
            make.bottom.equalTo(self.subtitleLabel)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override var alpha:CGFloat {
//        didSet {
//            self.invalidateIntrinsicContentSize()
//        }
//    }
//    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(60, UIViewNoIntrinsicMetric)
    }
    
}

class ListItemCell : UICollectionViewCell {
    weak var item:ItemViewModel?
    
    let border = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let selectedView = UIView(frame: self.bounds)
        selectedView.backgroundColor = UIColor(white:0.3, alpha:1)
        self.selectedBackgroundView = selectedView
        
        self.border.backgroundColor = UIColor(white: 0.1, alpha: 1)
        self.addSubview(self.border)
        self.border.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class ListItemTextCell: ListItemCell {
    
    let indexView = ListCellIndexView()
    let itemLabelsView = ItemLabelsView(frame:CGRectZero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(white: 0, alpha: 1)
        self.contentView.addSubview(self.itemLabelsView)

        let padding:CGFloat = 10.0
        self.itemLabelsView.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, padding, 0, padding))
            make.centerY.equalTo(self.contentView)
        }
        
        self.contentView.addSubview(self.indexView)
        self.indexView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(10)
            make.top.equalTo(self.contentView).offset(4)
            make.bottom.equalTo(self.contentView).offset(4)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override weak var item:ItemViewModel? {
        didSet {
            
            self.itemLabelsView.titleLabel.text = ""
            self.itemLabelsView.subtitleLabel.text = ""
            
            if let item = self.item {
                item.observer = self
                if let title = item.title {
                    self.itemLabelsView.titleLabel.text = title
                }
                
                if let subtitle = item.subtitle {
                    self.itemLabelsView.subtitleLabel.text = subtitle
                }
            }
        }
    }
    
    var indexViewVisible:Bool = false {
        didSet {
            let toAlpha:CGFloat = self.indexViewVisible ? 1.0 : 0
            self.itemLabelsView.snp_updateConstraints { (make) -> Void in
                if self.indexViewVisible {
                    make.left.equalTo(self.indexView.snp_right).offset(10)
                } else {
                    make.left.equalTo(self.contentView).offset(10)
                }
            }
            UIView.animateWithDuration(0.2) { () -> Void in
                self.indexView.alpha = toAlpha
                self.contentView.layoutIfNeeded()
            }
        }
    }
}

extension ListItemTextCell: ItemViewModelObserver {
    func queueIndexUpdate(viewModel:ItemViewModel, queueIndex:QueueIndex?) {
        if let item = self.item {
            if viewModel.isEqual(item) {
                if let index = queueIndex {
                    self.indexView.label.text = index.displayIndex
                    self.indexViewVisible = true
                } else {
                    self.indexViewVisible = false
                }
            }
        }
    }
}
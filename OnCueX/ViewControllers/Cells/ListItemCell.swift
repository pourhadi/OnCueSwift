//
//  ListItemTextCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import SnapKit

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
    
}

class ListItemCell : UICollectionViewCell {
    weak var item:ItemViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let selectedView = UIView(frame: self.bounds)
        selectedView.backgroundColor = UIColor(white:0.1, alpha:1)
        self.selectedBackgroundView = selectedView
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class ListItemTextCell: ListItemCell {
    
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
        
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override weak var item:ItemViewModel? {
        didSet {
            self.itemLabelsView.titleLabel.text = ""
            self.itemLabelsView.subtitleLabel.text = ""
            
            if let item = self.item {
                if let title = item.title {
                    self.itemLabelsView.titleLabel.text = title
                }
                
                if let subtitle = item.subtitle {
                    self.itemLabelsView.subtitleLabel.text = subtitle
                }
            }
        }
    }
}

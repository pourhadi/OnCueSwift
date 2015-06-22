//
//  ListItemTextCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import SnapKit

class ListItemCell : UICollectionViewCell {
    var item:Item?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let selectedView = UIView(frame: self.bounds)
        selectedView.backgroundColor = UIColor.blackColor()
        self.selectedBackgroundView = selectedView
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class ListItemTextCell: ListItemCell {
    
    lazy var titleLabel:UILabel = UILabel()
    lazy var subtitleLabel:UILabel = UILabel()
    
    var labelContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        self.titleLabel.font = UIFont.boldSystemFontOfSize(14)
        self.titleLabel.textColor = UIColor.whiteColor()
        
        self.subtitleLabel.font = UIFont.systemFontOfSize(11)
        self.subtitleLabel.textColor = UIColor.lightGrayColor()
        
        contentView.addSubview(self.labelContainer)
        self.labelContainer.addSubview(self.titleLabel)
        self.labelContainer.addSubview(self.subtitleLabel)
        
        let padding:CGFloat = 10.0
        self.labelContainer.snp_makeConstraints { (make) -> Void in
            make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, padding, 0, padding))
            make.centerY.equalTo(self.contentView)
            make.top.equalTo(self.titleLabel)
            make.bottom.equalTo(self.subtitleLabel)
        }
        
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.top.right.equalTo(self.labelContainer)
            make.bottom.equalTo(self.subtitleLabel.snp_top).offset(-2)
        }
        
        self.subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.bottom.left.right.equalTo(self.labelContainer)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var item:Item? {
        didSet {
            self.titleLabel.text = ""
            self.subtitleLabel.text = ""
            
            if let item = self.item {
                if let title = item.title {
                    self.titleLabel.text = title
                }
                
                if let subtitle = item.subtitle {
                    self.subtitleLabel.text = subtitle
                }
            }
        }
    }
}

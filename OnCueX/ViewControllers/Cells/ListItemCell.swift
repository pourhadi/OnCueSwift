//
//  ListItemTextCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import Snap

protocol ListItemCell {
    var item:Item? { get set }
}

class ListItemTextCell: UICollectionViewCell, ListItemCell {
    
    lazy var titleLabel:UILabel = UILabel()
    lazy var subtitleLabel:UILabel = UILabel()
    
    var labelContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(white: 0.2, alpha: 1)
        
        self.titleLabel.font = UIFont.boldSystemFontOfSize(12)
        self.titleLabel.textColor = UIColor.whiteColor()
        
        self.subtitleLabel.font = UIFont.systemFontOfSize(11)
        self.subtitleLabel.textColor = UIColor.lightGrayColor()
        
        contentView.addSubview(self.labelContainer)
        self.labelContainer.addSubview(self.titleLabel)
        self.labelContainer.addSubview(self.subtitleLabel)
        
        var padding:CGFloat = 10.0
        self.labelContainer.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(padding, padding, padding, padding))
        }
        
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.top.and.right.equalTo(self.labelContainer)
            make.bottom.equalTo(self.subtitleLabel.snp_top)
        }
        
        self.subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.bottom.left.and.right.equalTo(self.labelContainer)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var item:Item? {
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

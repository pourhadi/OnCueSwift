//
//  QueueCell.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/21/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

class QueueCell: UICollectionViewCell {
    
    var item:Queueable?
    
    let itemLabelsView = ItemLabelsView(frame: CGRectZero)
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
     
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.itemLabelsView)
        
        self.imageView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(80, 80))
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
        }
        
        self.itemLabelsView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.imageView.snp_right)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-10)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
    let imageView = UIImageView()
    func setText(text:String) {
        if (text == "") {
            self.alpha = 0
        } else {
            self.alpha = 1
        }
        
        self.label.text = text
//        let shadow = NSShadow()
//        shadow.shadowBlurRadius = 3;
//        shadow.shadowColor = UIColor.blackColor()
//        shadow.shadowOffset = CGSizeZero
//        
//        let par = NSMutableParagraphStyle()
//        par.alignment = .Center
//        
//        let fontSize:CGFloat = (text as NSString).length > 2 ? 16 : 24
//        let attr:[String:AnyObject] = [NSShadowAttributeName:shadow, NSFontAttributeName:UIFont.boldSystemFontOfSize(fontSize), NSParagraphStyleAttributeName:par, NSForegroundColorAttributeName:UIColor.whiteColor()]
//        self.label.attributedText = NSAttributedString(string: text, attributes: attr)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        self.imageView.contentMode = .ScaleAspectFill
        self.addSubview(self.imageView)
        self.imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        self.addSubview(self.label)
        self.label.snp_makeConstraints { (make) -> Void in
            let padding:CGFloat = 10
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(padding, padding, padding, padding))
        }
        
        self.label.textColor = UIColor.whiteColor()
        self.label.textAlignment = .Center
        self.label.font = UIFont.boldSystemFontOfSize(24)
        self.label.minimumScaleFactor = 0.6
        self.label.adjustsFontSizeToFitWidth = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let image = UIImage.draw(self.bounds.size) { (rect) -> Void in
            
            let locations:[CGFloat] = [0.0, 1.0]
            let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [UIColor(white:0, alpha:0.7).CGColor, UIColor(white: 0, alpha: 0).CGColor], locations)
            CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, self.imageView.center, 0, self.imageView.center, self.bounds.size.width/2, CGGradientDrawingOptions(kCGGradientDrawsAfterEndLocation))
            
        }
        
        self.imageView.image = image
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class QueueCell: UICollectionViewCell, QueuedItemObserver {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.indexView.label.text = nil
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
                    self.indexView.setText(index.displayIndex)
                }
            }
        }
    }
    
    weak var item:Queued? {
        didSet {
            self.imageView.image = nil
            if let item = self.item {
                item.observer = self
                self.itemLabelsView.titleLabel.text = item.displayInfo.title
                self.itemLabelsView.subtitleLabel.text = item.displayInfo.subtitle
                item.displayInfo.getImage(self.imageView.frame.size, complete: {  (context, image) -> Void in
                    if let localItem = self.item {
                        guard localItem.isEqual(context) || localItem.displayInfo.isEqual(context) else { return }
                        self.imageView.image = image
                    }
                })
                if let index = item.queueIndex {
                    self.indexView.setText(index.displayIndex)
                }
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
        self.imageView.contentMode = .ScaleAspectFill
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.itemLabelsView)
        self.contentView.addSubview(self.indexView)

        self.imageView.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(80, 80))
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
        }
        
        self.itemLabelsView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.imageView.snp_right).offset(20)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-10)
        }
        let padding:CGFloat = 0
        self.indexView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.imageView).insets(UIEdgeInsetsMake(padding, padding, padding, padding))
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2
        self.imageView.clipsToBounds = true
    }
}

//
//  ListLayout.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/27/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

func CalculatePercentComplete(start:CGFloat, end:CGFloat, current:CGFloat) -> CGFloat {
    var x = end - start
    return (current - start) / x
}

func ExtrapolateValue(from:CGFloat, _ to:CGFloat, _ percent:CGFloat) -> CGFloat {
    let value = from + ((to - from) * percent)
    return value
}

func CATransform3DMake(m11:CGFloat, _ m12:CGFloat, _ m13:CGFloat, _ m14:CGFloat,
    _ m21:CGFloat, _ m22:CGFloat, _ m23:CGFloat, _ m24:CGFloat,
    _ m31:CGFloat, _ m32:CGFloat, _ m33:CGFloat, _ m34:CGFloat,
    _ m41:CGFloat, _ m42:CGFloat, _ m43:CGFloat, _ m44:CGFloat) -> CATransform3D
{
    var t = CATransform3D();
    t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
    t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
    t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
    t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
    return t
}

func MakeUpSwing(percent:CGFloat) -> CATransform3D {
    let m22End:CGFloat = 0;
    let m22Start:CGFloat = 1.0;
    let m24End:CGFloat = -0.0010;
    let m24Start:CGFloat = 0;
    let m32End:CGFloat = 1;
    let m32Start:CGFloat = 0;
    let m44End:CGFloat = 0.9;
    let m44Start:CGFloat = 1.0;
    let m22:CGFloat = ExtrapolateValue(m22Start, m22End, percent);
    let m24:CGFloat = ExtrapolateValue(m24Start, m24End, percent);
    let m32:CGFloat = ExtrapolateValue(m32Start, m32End, percent);
    let m44:CGFloat = ExtrapolateValue(m44Start, m44End, percent);

    let transform = CATransform3DMake(
        1, 0, 0, 0,
        0, m22, 0, m24,
        0, m32, 1, 0,
        0, 0, 0, m44)
    return transform;
}

extension UICollectionViewLayoutAttributes {
    
    var animationPercent:CGFloat {
        get {
            if let percent = objc_getAssociatedObject(self.indexPath, "animationPercent") as? NSNumber {
                return CGFloat(percent.floatValue)
            }
            return 0.0
        }
        set {
            objc_setAssociatedObject(self.indexPath, "animationPercent", NSNumber(float:Float(newValue)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

class ListLayout: UICollectionViewFlowLayout {

    var attributes:[[UICollectionViewLayoutAttributes]] = []
    
    override func prepareLayout() {
        super.prepareLayout()
        
        self.attributes.removeAll()
        let offset = self.collectionView!.contentOffset.y  - self.collectionView!.contentInset.top
        
        let numOfSections = self.collectionView!.numberOfSections()
        for x in 0..<numOfSections {
            var section:[UICollectionViewLayoutAttributes] = []
            let numOfItems = self.collectionView!.numberOfItemsInSection(x)
            for y in 0..<numOfItems {
                let attr = self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: y, inSection: x))!.copy() as! UICollectionViewLayoutAttributes
                
                let height = attr.frame.size.height
                
                let topArea = offset - height
                if attr.frame.origin.y > topArea && attr.frame.origin.y < offset {
                    let percent = CalculatePercentComplete(offset, end: topArea, current: attr.frame.origin.y)
                    attr.transform3D = MakeUpSwing(percent)
                    attr.alpha = ExtrapolateValue(1, 0, percent)
                    print(percent)
                    
                }
                section.append(attr)

                
            }
            self.attributes.append(section)
        }
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attr:[UICollectionViewLayoutAttributes] = []
        for section in self.attributes {
            for item in section {
                if CGRectIntersectsRect(item.frame, rect) {
                    attr.append(item)
                }
            }
        }
        return attr
    }
    
}

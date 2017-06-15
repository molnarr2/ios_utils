//
//  FixedCollectionViewLayout.swift
//
//  Created by Robert Molnar 2 on 3/14/17.
//  Copyright © 2017 HRJ Software LLC. All rights reserved.
//

import Foundation
import UIKit

    
protocol FixedCollectionItemProtocol {
    var colspan: Int {get}
}

class FixedCollectionViewConfig {
    
    // The offset margin between columns.
    let offsetMargin: CGFloat
    // column count for phone in landscape mode
    let phoneLandscape: Int
    // column count for phone in portrait mode
    let phonePortrait: Int
    // column count for pad in landscape mode
    let padLandscape: Int
    // column count for pad in portrait mode
    let padPortrait: Int
    // The fixed height of the cell
    let fixedHeightCell: CGFloat
    
    init(offsetMargin: CGFloat, phoneLandscape: Int, phonePortrait: Int,  padLandscape: Int, padPortrait: Int, fixedHeightCell: CGFloat) {
        self.offsetMargin = offsetMargin
        self.phoneLandscape = phoneLandscape
        self.phonePortrait = phonePortrait
        self.padPortrait = padPortrait
        self.padLandscape = padLandscape
        self.fixedHeightCell = fixedHeightCell
    }
}

class FixedCollectionViewLayout: UICollectionViewLayout {
    
    let config: FixedCollectionViewConfig
    
    let items: [FixedCollectionItemProtocol]
    
    var atts = [UICollectionViewLayoutAttributes]()
    
    var sz = CGSize()
    
    init(items: [FixedCollectionItemProtocol], config: FixedCollectionViewConfig) {
        self.config = config
        self.items = items
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Assuming only one section.
    // The Grid widget can only have two columns max. A banner can span across the whole screen.
    override func prepare() {
        
        // Get the width of the device.
        let sz = self.collectionView!.bounds.size
        let width = sz.width
        
        // Reset the attributes to be re-calculated.
        self.atts = [UICollectionViewLayoutAttributes]()
        
        // Total number of items to be displayed.
        let itemsTotal = items.count
        
        // Determine number of columns based on what the device is.
        var totalColumns = 1
        if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
                totalColumns = config.phoneLandscape
            } else {
                totalColumns = config.phonePortrait
            }
        } else if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
                totalColumns = config.padLandscape
            } else {
                totalColumns = config.padPortrait
            }
        }
        
        // Calculate the cell width by evenly diving up the width minus the margins
        let oneCellWidth: CGFloat = (width - ((CGFloat(totalColumns) + 1.0) * config.offsetMargin)) / CGFloat(totalColumns)
        
        // Current x position of the column to be processed
        var columnPos = 0
        // Current y position of the item to be positioned.
        var yPos = config.offsetMargin
        
        for i in 0 ..< itemsTotal {
            let item = items[i]
            
            // The item does not fit within the row so go to next row.
            if totalColumns - item.colspan - columnPos < 0 {
                columnPos = 0
                yPos += config.fixedHeightCell + config.offsetMargin
            }
            
            // Calculate the cell width
            let cellWidth: CGFloat = (oneCellWidth * CGFloat(item.colspan) + config.offsetMargin * (CGFloat(item.colspan) - 1.0))
            
            // Calculate the cell height
            let cellHeight = config.fixedHeightCell
            
            // Calculate the x position
            let xPos: CGFloat = (CGFloat(columnPos) + 1.0) * config.offsetMargin
            
            // Build the frame and add it to the attributes.
            let att = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            att.frame = CGRect(x: xPos, y: yPos, width: cellWidth, height: cellHeight)
            self.atts.append(att)
            
            columnPos += item.colspan
        }
        
        self.sz = CGSize(width: width, height: yPos + config.fixedHeightCell + config.offsetMargin)
    }
    
    override var collectionViewContentSize : CGSize {
        return self.sz
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.atts
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.atts[indexPath.row]
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let ok = newBounds.size.width != self.sz.width
        return ok
    }
}



    

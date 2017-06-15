//
//  VariableCollectionViewLayout.swift
//
//  Created by Robert Molnar 2 on 3/14/17.
//  Copyright © 2017 HRJ Software LLC. All rights reserved.
//

import Foundation
import UIKit

protocol VariableCollectionItemProtocol {

    /**
     Determines the number of columns the cell should span.
     - parameters:
        - columnsInRow: number of columns within a row
     - returns: 
        Number of columns to the cell will span
     */
    func variableCollectionItem(columnsInRow: Int) -> Int

    /**
     Calculates the height of the cell from the width.
     - parameters:
        - width: The width of the cell.
     - returns:
        Height of the cell.
     */
    func variableCollectionItem(width: CGFloat) -> CGFloat
    
}

class VariableCollectionViewConfig {
    
    // The margin between columns.
    var marginColumns: CGFloat = 8
    // The margin between rows.
    var marginRows: CGFloat = 8
    // column count for phone in landscape mode
    let columnLandscape: Int
    // column count for phone in portrait mode
    let columnPortrait: Int
    
    init(phoneLandscape: Int, phonePortrait: Int,  padLandscape: Int, padPortrait: Int) {
        if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            self.columnPortrait = phonePortrait
            self.columnLandscape = phoneLandscape
            
        } else {
            self.columnPortrait = padPortrait
            self.columnLandscape = padLandscape
        }
    }
    
    convenience init(offsetMargin: CGFloat, phoneLandscape: Int, phonePortrait: Int,  padLandscape: Int, padPortrait: Int) {
        self.init(phoneLandscape: phoneLandscape, phonePortrait: phonePortrait, padLandscape: padLandscape, padPortrait: padPortrait)

        self.marginColumns = offsetMargin
        self.marginRows = offsetMargin
    }
    
    convenience init(offsetMarginPhone: CGFloat, offsetMarginPad: CGFloat, phoneLandscape: Int, phonePortrait: Int,  padLandscape: Int, padPortrait: Int) {
        
        var offsetMargin = offsetMarginPad
        if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            offsetMargin = offsetMarginPhone
        }
        
        self.init(offsetMargin: offsetMargin, phoneLandscape: phoneLandscape, phonePortrait: phonePortrait, padLandscape: padLandscape, padPortrait: padPortrait)
    }
    
    convenience init(marginColumnsPhone: CGFloat, marginColumnsPad: CGFloat, marginRowsPhone: CGFloat, marginRowsPad: CGFloat, phoneLandscape: Int, phonePortrait: Int,  padLandscape: Int, padPortrait: Int) {
        
        self.init(phoneLandscape: phoneLandscape, phonePortrait: phonePortrait, padLandscape: padLandscape, padPortrait: padPortrait)
        
        self.marginColumns = marginColumnsPad
        if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            self.marginColumns = marginColumnsPhone
        }
        
        self.marginRows = marginRowsPad
        if UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            self.marginRows = marginRowsPhone
        }
    }
}

/**
 * Layout that allows for a variable cell height and width based on the number of columns.
 */
class VariableCollectionViewLayout: UICollectionViewLayout {

    let config: VariableCollectionViewConfig
    
    var items: [VariableCollectionItemProtocol]
    
    var atts = [UICollectionViewLayoutAttributes]()
    
    var sz = CGSize()
    
    init(items: [VariableCollectionItemProtocol], config: VariableCollectionViewConfig) {
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
        if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
            totalColumns = config.columnLandscape
        } else {
            totalColumns = config.columnPortrait
        }
        
        // Calculate the cell width by evenly diving up the width minus the margins
        let oneCellWidth: CGFloat = (width - ((CGFloat(totalColumns) + 1.0) * config.marginColumns)) / CGFloat(totalColumns)
        
        // Current x position of the column to be processed
        var columnPos = 0
        // Current y position of the item to be positioned.
        var yPos = config.marginRows
        // The max height the row will be. Columns can be different heights.
        var rowMaxHeight = CGFloat(0)
        
        for i in 0 ..< itemsTotal {
            let item = items[i]
            
            let cellColumnSpan = CGFloat(item.variableCollectionItem(columnsInRow: totalColumns))
            
            // The item does not fit within the row so go to next row.
            if totalColumns - item.variableCollectionItem(columnsInRow: totalColumns) - columnPos < 0 {
                columnPos = 0
                yPos += rowMaxHeight + config.marginRows
                rowMaxHeight = CGFloat(0)
            }

            // Calculate the cell width
            let cellWidth: CGFloat = (oneCellWidth * cellColumnSpan + config.marginColumns * (cellColumnSpan - 1.0))
            
            // Calculate the cell height
            let cellHeight = item.variableCollectionItem(width: cellWidth)
            if cellHeight > rowMaxHeight {
                rowMaxHeight = cellHeight
            }
            
            // Calculate the x position
            let xPos: CGFloat = cellWidth * CGFloat(columnPos) + (CGFloat(columnPos) + 1.0) * config.marginColumns
            
            // Build the frame and add it to the attributes.
            let att = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            att.frame = CGRect(x: xPos, y: yPos, width: cellWidth, height: cellHeight)
            self.atts.append(att)
            
            columnPos += item.variableCollectionItem(columnsInRow: totalColumns)
        }
        
        self.sz = CGSize(width: width, height: yPos + rowMaxHeight + config.marginRows)
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

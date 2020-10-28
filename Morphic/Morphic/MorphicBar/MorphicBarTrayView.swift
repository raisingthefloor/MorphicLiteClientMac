// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Cocoa

///The view that displays any MorphicBar items that couldn't fit on the bar
public class MorphicBarTrayView: MorphicBarView {
    
    public private(set) var itemViewGrid: [[MorphicBarItemViewProtocol]] = []
    
    private var freeSpaceArray: [CGFloat] = []    //indicates free space left in each column
    
    public var collapsed = true {    //indicates if view is closed for compression reasons
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var maxSpace: CGFloat = 0    //calculated height of morphic bar so tray is always smaller
    
    private var topColumn: Int = 0 //current column being added to
    
    /// Add an item view to the end of the MorphicBar
    ///
    /// - parameters:
    ///   - itemView: The item view to add
    public override func add(itemView: MorphicBarItemViewProtocol) {
        if itemView.intrinsicContentSize.height <= freeSpaceArray[topColumn] {
            freeSpaceArray[topColumn] -= itemView.intrinsicContentSize.height + itemSpacing
            itemViewGrid[topColumn].append(itemView)
            itemView.morphicBarView = self
            addSubview(itemView)
            invalidateIntrinsicContentSize()
        }
        else {  //if column is full, add a new column
            itemViewGrid.append([MorphicBarItemViewProtocol]())
            freeSpaceArray.append(maxSpace)
            topColumn += 1
        }
    }
    
    /// Remove the item view at the given index
    ///
    /// - parameters:
    ///   - index: The index of the item to remove
    public func removeItemView(column: Int, index: Int) {
        let itemView = itemViewGrid[column][index]
        freeSpaceArray[column] += itemView.intrinsicContentSize.height + itemSpacing
        itemViewGrid[column].remove(at: index)
        itemView.removeFromSuperview()
        itemView.morphicBarView = nil
        invalidateIntrinsicContentSize()
    }
    
    /// Remove all item views from the MorphicBar
    public override func removeAllItemViews() {
        for i in (0..<itemViewGrid.count).reversed() {
            for j in (0..<itemViewGrid[i].count).reversed() {
                removeItemView(column: i, index: j)
            }
            itemViewGrid.remove(at: i)
        }
        itemViewGrid.append([MorphicBarItemViewProtocol]())
        freeSpaceArray.removeAll()
        freeSpaceArray.append(maxSpace)
        topColumn = 0
    }
    
    public func isEmpty() -> Bool {
        return itemViewGrid[0].isEmpty
    }
    
    public override func layout() {
        let itemViewsWithFrames = calculateFramesOfItemViews(itemViewGrid)
        for itemViewWithFrame in itemViewsWithFrames {
            itemViewWithFrame.itemView.frame = itemViewWithFrame.frame
        }
    }
    
    ///only calculates for vertical
    func calculateFramesOfItemViews(_ itemViewGrid: [[MorphicBarItemViewProtocol]]) -> [(itemView: MorphicBarItemViewProtocol, frame: CGRect)] {
        var result: [(itemView: MorphicBarItemViewProtocol, frame: CGRect)] = []
        var xoffset: CGFloat = 0
        var yoffset: CGFloat = 0
        for column in itemViewGrid {
            yoffset = 0
            let cwidth = getColumnWidth(column: column)
            for itemView in column {
                let itemViewIntrinsicSize = itemView.intrinsicContentSize
                var frame = CGRect(x: 600, y: 0, width: 0, height: 0)
                frame.size.width = itemViewIntrinsicSize.width
                frame.size.height = itemViewIntrinsicSize.height
                frame.origin.x = (cwidth - itemViewIntrinsicSize.width) / 2.0 + xoffset
                frame.origin.y = yoffset
                result.append((itemView: itemView, frame: frame))
                yoffset += frame.size.height + itemSpacing
            }
            xoffset += cwidth + itemSpacing
        }
        
        return result
    }
    
    private func getColumnWidth(column: [MorphicBarItemViewProtocol]) -> CGFloat {
        var width: CGFloat = 0
        for itemView in column {
            width = max(width, itemView.intrinsicContentSize.width)
        }
        return width
    }
    
    private func getColumnHeight(column: [MorphicBarItemViewProtocol]) -> CGFloat {
        var height: CGFloat = 0
        for itemView in column {
            height += itemView.intrinsicContentSize.height
            height += itemSpacing
        }
        height -= itemSpacing
        return height
    }
    
    public override var intrinsicContentSize: NSSize {
        if orientation == .horizontal || collapsed {
            return NSSize(width: 1, height: 1)
        }
        var size: NSSize
        size = NSSize(width: 0, height: 0)
        for column in itemViewGrid {
            size.width += getColumnWidth(column: column) + itemSpacing
            size.height = max(size.height, getColumnHeight(column: column))
        }
        size.width -= itemSpacing
        return size
    }
    
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }
}

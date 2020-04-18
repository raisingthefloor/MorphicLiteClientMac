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

/// The view that shows a collection of quick strip items
public class QuickStripView: NSView {
    
    // MARK: - Item Views
    
    /// The item views in order of appearance
    public private(set) var itemViews = [QuickStripItemView]()
    
    /// Add an item view to the end of the quick strip
    ///
    /// - parameters:
    ///   - itemView: The item view to add
    public func add(itemView: QuickStripItemView){
        itemViews.append(itemView)
        itemView.quickStripView = self
        addSubview(itemView)
        invalidateIntrinsicContentSize()
    }
    
    /// Remove the item view at the given index
    ///
    /// - parameters:
    ///   - index: The index of the item to remove
    public func removeItemView(at index: Int){
        let itemView = itemViews[index]
        itemViews.remove(at: index)
        itemView.removeFromSuperview()
        itemView.quickStripView = nil
        invalidateIntrinsicContentSize()
    }
    
    /// Remove all item views from the quick strip
    public func removeAllItemViews(){
        for i in (0..<itemViews.count).reversed(){
            removeItemView(at: i)
        }
    }
    
    // MARK: - Layout
    
    public override var isFlipped: Bool{
        return true
    }
    
    public override func layout() {
        var frame = CGRect(x: 0, y: 0, width: 0, height: bounds.size.height)
        for itemView in itemViews{
            let size = itemView.intrinsicContentSize
            frame.size.width = size.width
            itemView.frame = frame
            frame.origin.x += frame.size.width + itemSpacing
        }
    }
    
    /// The desired spacing between each item
    public var itemSpacing: CGFloat = 18.0{
        didSet{
            needsLayout = true
            invalidateIntrinsicContentSize()
        }
    }
    
    public override var intrinsicContentSize: NSSize{
        var size = NSSize(width: itemSpacing * CGFloat(itemViews.count - 1), height: NSView.noIntrinsicMetric)
        for itemView in itemViews{
            let itemSize = itemView.intrinsicContentSize
            size.width += itemSize.width
        }
        return size
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // accept first mouse so the event propagates up to the window and we
        // can intercept mouseUp to snap the window to a corner
        return true
    }
    
}

extension NSSize{
    
    public func roundedUp() -> NSSize{
        return NSSize(width: ceil(width), height: ceil(height))
    }
    
}

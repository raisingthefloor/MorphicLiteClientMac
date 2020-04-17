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

// A control similar to a segmented control, but with momentary buttons and custom styling.
//
// Typically a control of this kind will have only two segments, like On and Off or
// Show and Hide.  The interaction is exactly as if the buttons were distinct.
// They are grouped together to emphasize their relationship to each other.
//
// The segments are styled similarly with different shades of a color depending
// on whether a segment is considered to be a primary segment or not.
//
// Given the styling and behavior constraints, it seemed better to make a custom control
// that draws a series of connected buttons than to use NSSegmentedControl.
class QuickStripSegmentedButton: NSControl {
    
    // MARK: - Creating a Segmented Button
    
    init(segments: [Segment]){
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        font = .morphicBold
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 3
        layer?.rasterizationScale = 2
        self.segments = segments
        updateButtons()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    // MARK: - Style
    
    /// The color of segments with the `isPrimary` flag set to `true`
    var primarySegmentColor: NSColor = .morphicPrimaryColor
    
    /// The color of segments with the `isPrimary` flag set to `false`
    var secondarySegmentColor: NSColor = .morphicPrimaryColorLightend
    
    /// The color of text or icons on the segments
    ///
    /// - note: Since primary and secondary segments share the same title color,
    ///   their background colors should be similar enough that the title color works on both
    var titleColor: NSColor = .white
    
    // MARK: - Segments
    
    /// A segment's information
    struct Segment{
        
        /// The title to be shown on the segment, if any
        ///
        /// - important: `title` and `icon` are mutually exclusive.  If both sare specified,
        ///   the `title` property takes precedence
        var title: String?
        
        /// The icon to be shown on the segment, if any
        ///
        /// - important: `title` and `icon` are mutually exclusive.  If both sare specified,
        ///   the `title` property takes precedence
        var icon: NSImage?
        
        /// Indicates the segment is a primary button and should be colored differently from non-primary buttons
        var isPrimary: Bool = false
        
        /// The help title text to be shown in the Quick Help Window
        var helpTitle: String?
        
        /// The help message text to be shown in the Quick Help Window
        var helpMessage: String?
        
        /// Create a segment with a title
        init(title: String, helpTitle: String, helpMessage: String, isPrimary: Bool){
            self.title = title
            self.helpTitle = helpTitle
            self.helpMessage = helpMessage
            self.isPrimary = isPrimary
        }
        
        /// Create a segment with an icon
        init(icon: NSImage, helpTitle: String, helpMessage: String, isPrimary: Bool){
            self.icon = icon
            self.helpTitle = helpTitle
            self.helpMessage = helpMessage
            self.isPrimary = isPrimary
        }
    }
    
    /// The segments on the control
    var segments = [Segment](){
        didSet{
            updateButtons()
        }
    }
    
    // MARK: - Layout
    
    override var isFlipped: Bool{
        return true
    }
    
    /// Amount of inset each button segment should have
    var contentInsets = NSEdgeInsets(top: 7, left: 9, bottom: 7, right: 9){
        didSet{
            invalidateIntrinsicContentSize()
            for button in segmentButtons{
                (button as? Button)?.contentInsets = contentInsets
            }
        }
    }
    
    override var intrinsicContentSize: NSSize{
        var size = NSSize(width: 0, height: contentInsets.top + contentInsets.bottom + 13)
        for button in segmentButtons{
            let buttonSize = button.intrinsicContentSize
            size.width += buttonSize.width
        }
        return size
    }
    
    override func layout() {
        var frame = NSRect(origin: .zero, size: NSSize(width: 0, height: bounds.height))
        for button in segmentButtons{
            let buttonSize = button.intrinsicContentSize
            frame.size.width = buttonSize.width
            button.frame = frame
            frame.origin.x += frame.size.width
        }
    }
    
    // MARK: - Segment Buttons
    
    /// NSButton subclass that provides a custom intrinsic size with content insets
    private class Button: NSButton{
        
        private var boundsTrackingArea: NSTrackingArea!
        
        public override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(boundsTrackingArea)
        }
        
        required init?(coder: NSCoder) {
            return nil
        }
        
        public var contentInsets = NSEdgeInsetsZero{
            didSet{
                invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: NSSize{
            var size = super.intrinsicContentSize.roundedUp()
            size.width += contentInsets.left + contentInsets.right
            size.height += contentInsets.top + contentInsets.bottom
            return size
        }
        
        var helpTitle: String?
        var helpMessage: String?
        
        override func mouseEntered(with event: NSEvent) {
            guard let title = helpTitle, let message = helpMessage else{
                return
            }
            QuickHelpWindow.show(title: title, message: message)
        }
        
        override func mouseExited(with event: NSEvent) {
            QuickHelpWindow.hide()
        }
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            removeTrackingArea(boundsTrackingArea)
            boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(boundsTrackingArea)
        }
        
    }
    
    /// The list of buttons corresponding to the segments
    private var segmentButtons = [NSButton]()
    
    /// Update the segment buttons
    private func updateButtons(){
        setNeedsDisplay(bounds)
        invalidateIntrinsicContentSize()
        removeAllButtons()
        for segment in segments{
            let button = self.createButton(for: segment)
            add(button: button)
        }
        needsLayout = true
    }
    
    /// Create a button for a segment
    private func createButton(for segment: Segment) -> NSButton{
        let button = Button()
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.contentTintColor = titleColor
        button.contentInsets = contentInsets
        if let title = segment.title{
            button.title = title
        }else if let icon = segment.icon{
            button.image = icon
        }
        button.helpTitle = segment.helpTitle
        button.helpMessage = segment.helpMessage
        (button.cell as? NSButtonCell)?.backgroundColor = segment.isPrimary ? primarySegmentColor : secondarySegmentColor
        button.font = font
        return button
    }
    
    /// Remove all buttons
    private func removeAllButtons(){
        for i in (0..<segmentButtons.count).reversed(){
            removeButton(at: i)
        }
    }
    
    /// Remove a button at the give index
    ///
    /// - parameters:
    ///   - index: The index of the button to remove
    private func removeButton(at index: Int){
        let button = segmentButtons[index]
        button.action = nil
        button.target = nil
        segmentButtons.remove(at: index)
        button.removeFromSuperview()
    }
    
    /// Add a button
    ///
    /// - parameters:
    ///   - button: The button to add to the end of the list
    private func add(button: NSButton){
        let index = segmentButtons.count
        button.tag = index
        button.target = self
        button.action = #selector(QuickStripSegmentedButton.segmentAction)
        segmentButtons.append(button)
        addSubview(button)
    }
    
    // MARK: - Actions
    
    /// Handles a segment button click and calls this control's action
    @objc
    private func segmentAction(_ sender: Any?){
        guard let button = sender as? NSButton else{
            return
        }
        integerValue = button.tag
        sendAction(action, to: target)
    }
}

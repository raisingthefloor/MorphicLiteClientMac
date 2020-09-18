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
class MorphicBarSegmentedButton: NSControl {
    // NOTE: in macOS 10.14, setting integerValue to a segment index # doesn't necessarily persist the value; selectedSegmentIndex serves the purpose explicitly instead
    var selectedSegmentIndex: Int = 0
    
    var rightClickAction: Selector? = nil
    
    // MARK: - Creating a Segmented Button
    
    init(segments: [Segment]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        switch style {
        case .autoWidth:
            font = .morphicBold
        case .fixedWidth(_):
            font = .morphicBold // .morphicRegular
        }
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
    
    /// The color of text or icons on the segments
    ///
    /// - note: Since primary and secondary segments share the same title color,
    ///   their background colors should be similar enough that the title color works on both
    var titleColor: NSColor = .white
    
    // MARK: - Segments
    
    /// A segment's information
    struct Segment {
        
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
        
        /// Indicates the color of the button segment
        let fillColor: NSColor
        
        var helpProvider: QuickHelpContentProvider?
        
        var style: MorphicBarControlItemStyle
        
        var accessibilityLabel: String?
        
        /// Create a segment with a title
        init(title: String, fillColor: NSColor, helpProvider: QuickHelpContentProvider?, accessibilityLabel: String?, style: MorphicBarControlItemStyle) {
            self.title = title
            self.helpProvider = helpProvider
            self.fillColor = fillColor
            self.accessibilityLabel = accessibilityLabel
            self.style = style
        }
        
        /// Create a segment with an icon
        init(icon: NSImage, fillColor: NSColor, helpProvider: QuickHelpContentProvider?, accessibilityLabel: String?, style: MorphicBarControlItemStyle) {
            self.icon = icon
            self.helpProvider = helpProvider
            self.fillColor = fillColor
            self.accessibilityLabel = accessibilityLabel
            self.style = style
        }
    }
    
    /// The segments on the control
    var segments = [Segment]() {
        didSet{
            updateButtons()
        }
    }
    
    // MARK: - Layout
    
    let horizontalMarginBetweenSegments = CGFloat(1.5)
    
    var style: MorphicBarControlItemStyle = .autoWidth

    override var isFlipped: Bool {
        return true
    }
    
    /// Amount of inset each button segment should have
    var contentInsets = NSEdgeInsets(top: 7, left: 9, bottom: 7, right: 9) {
        didSet {
            invalidateIntrinsicContentSize()
            for button in segmentButtons {
                button.contentInsets = contentInsets
            }
        }
    }
    
    override var intrinsicContentSize: NSSize {
        switch self.style {
        case .autoWidth:
            var size = NSSize(width: 0, height: contentInsets.top + contentInsets.bottom + 13)
            for button in segmentButtons {
                let buttonSize = button.intrinsicContentSize
                size.width += buttonSize.width
            }
            size.width += CGFloat(max(segmentButtons.count - 1, 0)) * horizontalMarginBetweenSegments
            return size
        case .fixedWidth(let segmentWidth):
            let totalWidth = (CGFloat(segments.count) * (segmentWidth + horizontalMarginBetweenSegments)) - horizontalMarginBetweenSegments
            let size = NSSize(width: totalWidth, height: contentInsets.top + contentInsets.bottom + 13)
            return size
        }
    }
    
    override func layout() {
        var frame = NSRect(origin: .zero, size: NSSize(width: 0, height: bounds.height))
        for button in segmentButtons {
            let buttonSize = button.intrinsicContentSize
            frame.size.width = buttonSize.width
            button.frame = frame
            frame.origin.x += frame.size.width + horizontalMarginBetweenSegments
        }
    }
    
    // MARK: - Segment Buttons
    
    /// NSButton subclass that provides a custom intrinsic size with content insets
    class Button: NSButton {
        
        private var boundsTrackingArea: NSTrackingArea!
        
        public var style: MorphicBarControlItemStyle = .autoWidth
        
        public override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            createBoundsTrackingArea()
        }
        
        required init?(coder: NSCoder) {
            return nil
        }
        
        public var contentInsets = NSEdgeInsetsZero {
            didSet{
                invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: NSSize {
            var size = super.intrinsicContentSize.roundedUp()
            switch style {
            case .autoWidth:
                size.width += contentInsets.left + contentInsets.right
                size.height += contentInsets.top + contentInsets.bottom
            case .fixedWidth(let width):
                size.width = width
            }
            return size
        }
        
        var showsHelp: Bool = true {
            didSet {
                createBoundsTrackingArea()
            }
        }
        
        var helpProvider: QuickHelpContentProvider?
        
        override func mouseEntered(with event: NSEvent) {
            updateHelpWindow()
        }
        
        override func mouseExited(with event: NSEvent) {
            QuickHelpWindow.hide()
        }
        
        public var rightClickAction: Selector? = nil
        override func rightMouseDown(with event: NSEvent) {
            super.sendAction(rightClickAction, to: target)
        }
        
        override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
            guard super.sendAction(action, to: target) else {
                return false
            }
            updateHelpWindow()
            return true
        }
        
        func updateHelpWindow() {
            if showsHelp == true {
                guard let viewController = helpProvider?.quickHelpViewController() else {
                    return
                }
                QuickHelpWindow.show(viewController: viewController)
            }
        }
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            createBoundsTrackingArea()
        }
        
        private func createBoundsTrackingArea() {
            if boundsTrackingArea != nil {
                removeTrackingArea(boundsTrackingArea)
            }
            if showsHelp {
                boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
                addTrackingArea(boundsTrackingArea)
            }
        }
        
    }
    
    public var showsHelp: Bool = true {
        didSet {
            for button in segmentButtons {
                button.showsHelp = showsHelp
            }
        }
    }
    
    /// The list of buttons corresponding to the segments
    var segmentButtons = [Button]()
    
    /// Update the segment buttons
    private func updateButtons() {
        setNeedsDisplay(bounds)
        invalidateIntrinsicContentSize()
        removeAllButtons()
        for segment in segments {
            let button = self.createButton(for: segment)
            add(button: button)
        }
        needsLayout = true
    }
    
    /// Create a button for a segment
    private func createButton(for segment: Segment) -> Button {
        let button = Button()
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.contentTintColor = titleColor
        button.contentInsets = contentInsets
        if let title = segment.title {
            button.title = title
        } else if let icon = segment.icon {
            button.image = icon
        }
        button.setAccessibilityLabel(segment.accessibilityLabel)
        button.helpProvider = segment.helpProvider
        (button.cell as? NSButtonCell)?.backgroundColor = segment.fillColor
        //
        button.style = segment.style
        switch segment.style {
        case .autoWidth:
            button.font = .morphicBold
        case .fixedWidth(_):
            button.font = .morphicBold // .morphicRegular
        }
        //
        return button
    }
    
    /// Remove all buttons
    private func removeAllButtons() {
        for i in (0..<segmentButtons.count).reversed(){
            removeButton(at: i)
        }
    }
    
    /// Remove a button at the give index
    ///
    /// - parameters:
    ///   - index: The index of the button to remove
    private func removeButton(at index: Int) {
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
    private func add(button: Button) {
        let index = segmentButtons.count
        button.tag = index
        button.target = self
        button.action = #selector(MorphicBarSegmentedButton.segmentAction)
        button.rightClickAction = #selector(MorphicBarSegmentedButton.segmentRightClickAction)
        segmentButtons.append(button)
        addSubview(button)
    }
    
    // MARK: - Actions
    
    /// Handles a segment button click and calls this control's action
    @objc
    private func segmentAction(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        integerValue = button.tag
        selectedSegmentIndex = button.tag
        sendAction(action, to: target)
    }
    
    /// Handles a segment button click and calls this control's right click action
    @objc
    private func segmentRightClickAction(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        integerValue = button.tag
        selectedSegmentIndex = button.tag
        sendAction(rightClickAction, to: target)
    }
}

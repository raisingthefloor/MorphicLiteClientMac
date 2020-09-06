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

public class MorphicBarItemView: NSView {
    
    public weak var morphicBarView: MorphicBarView?
    
    public var showsHelp: Bool = true
    
    public override var isFlipped: Bool {
        return true
    }
    
    public func getAccessChildren() -> [Any?] {
        return [nil]
    }
    
}

class MorphicBarSegmentedButtonItemView: MorphicBarItemView {
    
    var titleLabel: NSTextField
    var segmentedButton: MorphicBarSegmentedButton
    var titleButtonSpacing: CGFloat = 4.0
    
    init(title: String, segments: [MorphicBarSegmentedButton.Segment]) {
        titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .morphicBold
        titleLabel.alignment = .center
        segmentedButton = MorphicBarSegmentedButton(segments: segments)
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        addSubview(titleLabel)
        addSubview(segmentedButton)
        self.needsLayout = true
    }
    
    override var showsHelp: Bool {
        didSet{
            segmentedButton.showsHelp = showsHelp
        }
    }
    
    private var titleYAdjustment: CGFloat {
        guard let font = titleLabel.font else {
            return 0.0
        }
        return ceil(font.capHeight - font.ascender)
    }

    required init?(coder: NSCoder) {
        return nil
    }
    
    override func layout() {
        let labelSize = titleLabel.intrinsicContentSize.roundedUp()
        let buttonSize = segmentedButton.intrinsicContentSize
        // The deafault layout of NSTextField has a couple blank pixes on the left, so we adjust the title's x coordinate by -2
        titleLabel.frame = NSRect(origin: NSPoint(x: round((bounds.size.width - labelSize.width) / 2) - 2, y: titleYAdjustment), size: labelSize)
        segmentedButton.frame = NSRect(origin: NSPoint(x: round((bounds.size.width - buttonSize.width) / 2), y: bounds.size.height - buttonSize.height), size: buttonSize)
    }
    
    override var intrinsicContentSize: NSSize {
        let labelSize = titleLabel.intrinsicContentSize.roundedUp()
        let buttonSize = segmentedButton.intrinsicContentSize
        return NSSize(width: ceil(max(labelSize.width, buttonSize.width)), height: titleYAdjustment + labelSize.height + titleButtonSpacing + buttonSize.height)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // accept first mouse so the event propagates up to the window and we
        // can intercept mouseUp to snap the window to a corner
        return true
    }
    
    override func getAccessChildren() -> [Any?] {
        var reply = [Any]()
        for button in segmentedButton.segmentButtons {
            reply.append(button)
        }
        return reply
    }
    
}

//
//  Label.swift
//  ClickableLabel
//
//  Created by Nobuyuki Tsutsui on 2016/04/09.
//
//

import UIKit

@IBDesignable
public class Label: UIView {
    
    private static let HIGHLIGHT_LINK_CORNER_RADIUS: CGFloat = 3.0
    private static let HIGHLIGHT_LINK_FILL_COLOR = UIColor(white: 0.0, alpha: 0.27)
    
    private let layoutManager: NSLayoutManager = NSLayoutManager()
    private let textContainer: NSTextContainer = NSTextContainer()
    private var textStorage: NSTextStorage?
    
    private let linkHighlightLayer: CAShapeLayer = CAShapeLayer()
    private var highlightedLink: NSURL?
    public var linkTapHandler: ((link: NSURL) -> ())?
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.textContainer.widthTracksTextView = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.linkHighlightLayer.fillColor = Label.HIGHLIGHT_LINK_FILL_COLOR.CGColor
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textContainer.widthTracksTextView = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.linkHighlightLayer.fillColor = Label.HIGHLIGHT_LINK_FILL_COLOR.CGColor
    }
    
    // MARK: - IBInspectable Properties
    
    @IBInspectable public var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = self.attributedText {
                self.textStorage = NSTextStorage(attributedString: attributedText)
            } else {
                self.textStorage = nil
            }
            self.layoutManager.textStorage = self.textStorage
        }
    }
    
    @IBInspectable public var lineFragmentPadding: CGFloat {
        get {
            return self.textContainer.lineFragmentPadding
        }
        set {
            self.textContainer.lineFragmentPadding = newValue
        }
    }
    
    @IBInspectable public var maximumNumberOfLines: Int {
        get {
            return self.textContainer.maximumNumberOfLines
        }
        set {
            self.textContainer.maximumNumberOfLines = newValue
            self.layoutManager.textContainerChangedGeometry(self.textContainer)
        }
    }
    
    // MARK: - Override

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.textContainer.size.width != self.bounds.width {
            self.textContainer.size = CGSize(width: self.bounds.width, height: CGFloat.max)
            self.layoutManager.textContainerChangedGeometry(self.textContainer)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        self.layoutManager.ensureLayoutForTextContainer(self.textContainer)
        let glyphRange = self.layoutManager.glyphRangeForTextContainer(self.textContainer)
        let boundingRect = self.layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: self.textContainer)
        return CGSize(width: boundingRect.width, height: floor(boundingRect.height))
    }

    public override func drawRect(rect: CGRect) {
        let glyphRange = self.layoutManager.glyphRangeForTextContainer(self.textContainer)
        self.layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: CGPointZero)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let textStorage = self.textStorage else {
            return
        }
        let glyphIndex = self.layoutManager.glyphIndexForPoint(touches.first!.locationInView(self), inTextContainer: self.textContainer)
        var effectiveRange: NSRange = NSMakeRange(NSNotFound, 0)
        let attributes = textStorage.attributesAtIndex(glyphIndex, effectiveRange: &effectiveRange)
        let linkAttribute = attributes[NSLinkAttributeName]
        if linkAttribute is NSURL {
            self.highlightedLink = linkAttribute as? NSURL
        } else if linkAttribute is NSString {
            self.highlightedLink = NSURL(string: linkAttribute as! String)
        } else {
            return
        }
        let linkGlyphRange = self.layoutManager.glyphRangeForCharacterRange(effectiveRange, actualCharacterRange: nil)
        let path = UIBezierPath()
        self.layoutManager.enumerateEnclosingRectsForGlyphRange(linkGlyphRange,
                                                                withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0),
                                                                inTextContainer: self.textContainer)
        { (rect, stop) in
            var rect = rect
            rect.size.height += Label.HIGHLIGHT_LINK_CORNER_RADIUS
            path.appendPath(UIBezierPath(roundedRect: rect, cornerRadius: Label.HIGHLIGHT_LINK_CORNER_RADIUS))
        }
        let bounds = path.bounds
        path.applyTransform(CGAffineTransformMakeTranslation(-bounds.origin.x, -bounds.origin.y))
        self.linkHighlightLayer.path = path.CGPath
        showLinkHighlight(bounds)
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if self.highlightedLink != nil {
            guard let touch = touches.first else {
                return
            }
            let pt = self.linkHighlightLayer.convertPoint(touch.locationInView(self), fromLayer: self.layer)
            if CGPathContainsPoint(self.linkHighlightLayer.path, nil, pt, false) {
                if self.linkHighlightLayer.hidden {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.linkHighlightLayer.hidden = false
                    CATransaction.commit()
                }
            } else {
                if !self.linkHighlightLayer.hidden {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.linkHighlightLayer.hidden = true
                    CATransaction.commit()
                }
            }
        }
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let link = self.highlightedLink {
            if !self.linkHighlightLayer.hidden {
                linkTapHandler?(link: link)
            }
            resetLinkHighlight()
        }
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        resetLinkHighlight()
    }
    
    // MARK: Utilities
    
    private func showLinkHighlight(boundingRect: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.linkHighlightLayer.frame = boundingRect
        self.linkHighlightLayer.hidden = false
        self.layer.addSublayer(self.linkHighlightLayer)
        CATransaction.commit()
    }
    
    private func resetLinkHighlight() {
        self.linkHighlightLayer.removeFromSuperlayer()
        self.highlightedLink = nil
    }
    
}

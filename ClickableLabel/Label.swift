//
//  Label.swift
//  ClickableLabel
//
//  Created by cubenoy22 on 2016/04/09.
//
//

import UIKit

@IBDesignable
public class Label: UIView {
    
    private static let highlightLinkCornerRadius: CGFloat = 3.0
    private static let highlightLinkFillColor = UIColor(white: 0.0, alpha: 0.27)
    
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    private var textStorage: NSTextStorage?
    
    private let linkHighlightLayer = CAShapeLayer()
    private var highlightedLink: URL?
    public var linkTapHandler: ((_ link: URL) -> ())?
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.textContainer.widthTracksTextView = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.linkHighlightLayer.fillColor = Label.highlightLinkFillColor.cgColor
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textContainer.widthTracksTextView = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.linkHighlightLayer.fillColor = Label.highlightLinkFillColor.cgColor
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
            self.textContainer.size = CGSize(width: self.bounds.width, height: 0.0)
            self.layoutManager.textContainerChangedGeometry(self.textContainer)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        get {
            self.layoutManager.ensureLayout(for: self.textContainer)
            let glyphRange = self.layoutManager.glyphRange(for: self.textContainer)
            let boundingRect = self.layoutManager.boundingRect(forGlyphRange: glyphRange, in: self.textContainer)
            return CGSize(width: UIView.noIntrinsicMetric, height: floor(boundingRect.height))
        }
    }

    public override func draw(_ rect: CGRect) {
        let glyphRange = self.layoutManager.glyphRange(for: self.textContainer)
        self.layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let textStorage = self.textStorage else {
            return
        }
        let glyphIndex = self.layoutManager.glyphIndex(for: touches.first!.location(in: self), in: self.textContainer)
        var effectiveRange: NSRange = NSMakeRange(NSNotFound, 0)
        let attributes = textStorage.attributes(at: glyphIndex, effectiveRange: &effectiveRange)
        let linkAttribute = attributes[NSAttributedString.Key.link]
        if let linkAttribute = linkAttribute as? URL {
            self.highlightedLink = linkAttribute
        } else if let linkAttribute = linkAttribute as? String {
            self.highlightedLink = URL(string: linkAttribute)
        } else {
            return
        }
        let linkGlyphRange = self.layoutManager.glyphRange(forCharacterRange: effectiveRange, actualCharacterRange: nil)
        let path = UIBezierPath()
        self.layoutManager.enumerateEnclosingRects(forGlyphRange: linkGlyphRange,
                                                   withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0),
                                                   in: self.textContainer)
        { (rect, stop) in
            var rect = rect
            rect.size.height += Label.highlightLinkCornerRadius
            path.append(UIBezierPath(roundedRect: rect, cornerRadius: Label.highlightLinkCornerRadius))
        }
        let bounds = path.bounds
        path.apply(CGAffineTransform(translationX: -bounds.origin.x, y: -bounds.origin.y))
        self.linkHighlightLayer.path = path.cgPath
        showLinkHighlight(boundingRect: bounds)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.highlightedLink != nil {
            guard let touch = touches.first else {
                return
            }
            let pt = self.linkHighlightLayer.convert(touch.location(in: self), from: self.layer)
            if self.linkHighlightLayer.path?.contains(pt) ?? false {
                if self.linkHighlightLayer.isHidden {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.linkHighlightLayer.isHidden = false
                    CATransaction.commit()
                }
            } else {
                if !self.linkHighlightLayer.isHidden {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.linkHighlightLayer.isHidden = true
                    CATransaction.commit()
                }
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let link = self.highlightedLink {
            if !self.linkHighlightLayer.isHidden {
                linkTapHandler?(link)
            }
            resetLinkHighlight()
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        resetLinkHighlight()
    }
    
    // MARK: Utilities
    
    private func showLinkHighlight(boundingRect: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.linkHighlightLayer.frame = boundingRect
        self.linkHighlightLayer.isHidden = false
        self.layer.addSublayer(self.linkHighlightLayer)
        CATransaction.commit()
    }
    
    private func resetLinkHighlight() {
        self.linkHighlightLayer.removeFromSuperlayer()
        self.highlightedLink = nil
    }
    
}

//
//  LabelSupport.swift
//  ClickableLabel
//
//  Created by Nobuyuki Tsutsui on 2016/04/13.
//
//

import UIKit

extension Label {
    
    @IBInspectable public var markupText: NSString? {
        get {
            return nil
        }
        set {
            if let data = newValue?.dataUsingEncoding(NSUnicodeStringEncoding) {
                do {
                    self.attributedText = try NSTextStorage(data: data,
                                                            options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                                                            documentAttributes: nil)
                }
                catch {
                    return
                }
            }
        }
    }
    
}

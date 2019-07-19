//
//  LabelSupport.swift
//  ClickableLabel
//
//  Created by cubenoy22 on 2016/04/13.
//
//

import UIKit

extension Label {
    
    @IBInspectable public var markupText: NSString? {
        get {
            return nil
        }
        set {
            if let data = newValue?.data(using: String.Encoding.unicode.rawValue) {
                do {
                    self.attributedText = try NSTextStorage.init(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.html],
                        documentAttributes: nil
                    )
                }
                catch {
                    return
                }
            }
        }
    }
    
}

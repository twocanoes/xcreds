//
//  NSButton+Color.swift
//  XCreds
//
//  Created by Timothy Perfitt on 1/10/25.
//


import Cocoa

@IBDesignable
 class CustomCheckbox: NSButton
{
    @IBInspectable var background: NSColor?
    @IBInspectable var textColor: NSColor?

    override func awakeFromNib()
    {
        if let textColor = textColor, let font = font
        {
            let style = NSMutableParagraphStyle()
            style.alignment = .center

            let attributes =
            [
                NSAttributedString.Key.foregroundColor: textColor,
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.paragraphStyle: style
            ] as [NSAttributedString.Key : Any]

            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            self.attributedTitle = attributedTitle
        }
    }

    override func draw(_ dirtyRect: NSRect)
    {
        if let bgColor = background
        {
            bgColor.setFill()
            __NSRectFill(dirtyRect)
        }

        super.draw(dirtyRect)
    }
}

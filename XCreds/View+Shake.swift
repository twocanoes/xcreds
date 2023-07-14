//
//  NSView+Shake.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//
//https://onmyway133.com/posts/how-to-shake-nsview-in-macos/

import Foundation
import Cocoa

extension NSView {
    @objc func shake(_ sender: AnyObject?) {
        let midX = self.layer?.position.x ?? 0
        let midY = self.layer?.position.y ?? 0

        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 10, y: midY)
        animation.toValue = CGPoint(x: midX + 10, y: midY)
        self.layer?.add(animation, forKey: "position")
    }

}

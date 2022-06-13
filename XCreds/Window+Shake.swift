//
//  Window+Shake.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//
// https://stackoverflow.com/a/50267597
// thanks to Mike James https://stackoverflow.com/users/531419/mike-james
import Foundation
import Cocoa

extension NSWindow {
    @objc func shake(_ sender: AnyObject?) {
        let numberOfShakes = 3
        let durationOfShake = 0.4
        let vigourOfShake : CGFloat = 0.03
        let frame : CGRect = (self.frame)
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move( to: CGPoint(x:NSMinX(frame), y:NSMinY(frame)))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) - frame.size.width * vigourOfShake, y:NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) + frame.size.width * vigourOfShake, y:NSMinY(frame)))
        }

        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = durationOfShake

        let animations = [NSAnimatablePropertyKey( "frameOrigin") : shakeAnimation]

        self.animations = animations
        self.animator().setFrameOrigin(NSPoint(x: frame.minX, y: frame.minY))
    }
}

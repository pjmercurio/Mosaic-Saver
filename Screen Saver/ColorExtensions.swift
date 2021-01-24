//
//  ColorExtensions.swift
//  Screen Saver
//
//  Created by Paul Mercurio on 12/13/20.
//  Copyright © 2020 Paul Mercurio. All rights reserved.
//

import AppKit

extension NSColor {

    func difference(from color: NSColor) -> Float {
        let redDiff = abs(self.redComponent - color.redComponent)
        let greenDiff = abs(self.greenComponent - color.greenComponent)
        let blueDiff = abs(self.blueComponent - color.blueComponent)
        return Float(redDiff + greenDiff + blueDiff)
    }

}

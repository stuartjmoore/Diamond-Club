//
//  ShadowLabel.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/22/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit

class ShadowLabel: UILabel {

    override func draw(_ rect: CGRect) {
        let colorValues: [CGFloat] = [0, 0, 0, 0.95]

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        defer { context?.restoreGState() }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let color = CGColor(colorSpace: colorSpace, components: colorValues)
        context?.setShadow(offset: CGSize(width: 0, height: 0), blur: 10, color: color)

        super.drawText(in: rect)
    }

}

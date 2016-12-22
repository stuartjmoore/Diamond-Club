//
//  UIView+Find.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/22/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit

extension UIView {

    func findView(is anyClass: String) -> UIView? {
        var foundView: UIView? = nil

        for subview in subviews {
            if NSStringFromClass(type(of: subview)).hasSuffix(anyClass) {
                foundView = subview
                break
            } else if let foundView = subview.findView(is: anyClass) {
                return foundView
            }
        }

        return foundView
    }

}

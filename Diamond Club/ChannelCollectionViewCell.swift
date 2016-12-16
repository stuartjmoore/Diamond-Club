//
//  ChannelCollectionViewCell.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/15/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit

class ChannelCollectionViewCell: UICollectionViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!

    override func awakeFromNib() {
        titleLabel.alpha = 0
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ 
            self.titleLabel.alpha = self.isFocused ? 1 : 0
        }, completion: nil)
    }

}

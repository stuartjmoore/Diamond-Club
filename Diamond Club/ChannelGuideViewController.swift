//
//  ChannelGuideViewController.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/16/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit

protocol ChannelGuideViewControllerDelegate: class {
    func updatePlayerItem(playing: URL)
    func dismissChannelGuide()
}

class ChannelGuideViewController: UIViewController {

    weak var delegate: ChannelGuideViewControllerDelegate? {
        didSet {
            if let number = currentNumber {
                let url = DiamondClub.streamURL(for: number)
                delegate?.updatePlayerItem(playing: url)
            }
        }
    }

    @IBOutlet fileprivate(set) var collectionView: UICollectionView!
    @IBOutlet fileprivate(set) var tableView: UITableView!

    fileprivate(set) var currentNumber: Int?

    fileprivate(set) var channels: [Channel]? {
        didSet {
            collectionView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 35

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.allowedPressTypes = [.upArrow, .downArrow, .menu]
        collectionView.addGestureRecognizer(tapGesture)

        DiamondClub.getLiveChannels() { (channels) in
            self.channels = channels

            if let channelIndex = (channels.count > 0 ? 0 : nil) {
                let url = DiamondClub.streamURL(for: channels[channelIndex].number)
                self.currentNumber = channels[channelIndex].number
                self.delegate?.updatePlayerItem(playing: url)
            }
        }
    }

    func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        delegate?.dismissChannelGuide()
    }

}

// MARK: - Channels

extension ChannelGuideViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! ChannelCollectionViewCell

        guard let channels = channels, indexPath.row < channels.count else {
            return cell
        }

        let item = channels[indexPath.row]
        cell.titleLabel.text = item.title
        cell.iconImageView.image = nil

        DiamondClub.getChannelIcon(for: item.number) { (image) in
            cell.iconImageView.image = image
        }
        
        return cell
    }

}

extension ChannelGuideViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let channels = channels, indexPath.row < channels.count else {
            return
        }

        guard indexPath.row != channels.index(where: { return $0.number == self.currentNumber }) else {
            return
        }

        let item = channels[indexPath.row]
        let url = DiamondClub.streamURL(for: item.number)
        currentNumber = item.number

        delegate?.dismissChannelGuide()
        delegate?.updatePlayerItem(playing: url)
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard let index = channels?.index(where: { return $0.number == self.currentNumber }) else {
            return nil
        }

        return IndexPath(item: index, section: 0)
    }

    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        return context.nextFocusedIndexPath != nil
    }

}

// MARK: - Schedule

extension ChannelGuideViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Today"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! MessageTableViewCell

        cell.usernameLabel.text = "12:00 PM"
        cell.messageLabel.text = "The Morning Stream"

        return cell
    }

}

extension ChannelGuideViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else {
            return
        }

        headerView.textLabel?.textColor = .white
    }

}

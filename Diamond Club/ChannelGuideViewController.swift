//
//  ChannelGuideViewController.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/16/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit
import DiamondClubKit
import ScheduleKit

protocol ChannelGuideViewControllerDelegate: class {
    func updatePlayerItem(playing: URL)
    func updateMetadata(title: String, description: String?)
    func updateMetadata(image: UIImage)
    func dismissChannelGuide(completion: (() -> Void)?)
}

class ChannelGuideViewController: UIViewController {

    weak var delegate: ChannelGuideViewControllerDelegate?

    @IBOutlet fileprivate(set) var collectionView: UICollectionView!
    @IBOutlet fileprivate(set) var tableView: UITableView!

    fileprivate(set) var currentNumber: Int?
    fileprivate(set) var channels: [Channel] = [] {
        didSet {
            if oldValue != channels {
                collectionView?.reloadData()
            }
        }
    }

    private var scheduleTimer: Timer?
    fileprivate var scheduleData: [(title: String, items: [(time: String, title: String)])] = [] {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 35

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.allowedPressTypes = [.upArrow, .downArrow, .menu]
        collectionView.addGestureRecognizer(tapGesture)

        updateChannels()
        updateSchedule()
    }

    func updateChannels() {
        DiamondClub.getLiveChannels { [weak self] (channels) in
            self?.channels = channels

            if self?.currentNumber == nil, let channelIndex = (channels.count > 0 ? 0 : nil) {
                let channel = channels[channelIndex]
                self?.change(channel: channel)
            }
        }
    }

    func updateSchedule(_ timer: Timer? = nil) {
        timer?.invalidate()

        ScheduleClient.fromNow { [weak self] (scheduled) in
            dump(scheduled)

            guard let `self` = self else { return }

            self.scheduleData = scheduled.map { (events) in
                let dateString = events.first?.airingDate.dateString ?? "Schedule"

                return (title: dateString, items: events.map { (event) in
                    let titleAndChatRoom = event.title.components(separatedBy: " #")
                    let title = titleAndChatRoom.first ?? event.title
                    return (time: event.airingDate.timeString, title: title)
                })
            }

            if let firstEvent = scheduled.first?.first {
                let endingDate = firstEvent.airingDate.addingTimeInterval(firstEvent.duration)
                let timer = Timer(fire: endingDate, interval: 0, repeats: false, block: self.updateSchedule)
                RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
                self.scheduleTimer = timer
            }
        }
    }

    func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        delegate?.dismissChannelGuide(completion: nil)
    }

    fileprivate func change(channel: Channel) {
        currentNumber = channel.number

        let url = DiamondClub.streamURL(for: channel.number)
        delegate?.updatePlayerItem(playing: url)
        delegate?.updateMetadata(title: channel.title, description: channel.description)

        DiamondClub.getChannelIcon(for: channel.number) { [weak self] (image) in
            self?.delegate?.updateMetadata(image: image)
        }
    }

    deinit {
        scheduleTimer?.invalidate()
    }

}

// MARK: - Channels

extension ChannelGuideViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! ChannelCollectionViewCell

        guard indexPath.row < channels.count else {
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
        guard indexPath.row < channels.count else {
            return
        }

        guard indexPath.row != channels.index(where: { return $0.number == self.currentNumber }) else {
            return
        }

        let channel = channels[indexPath.row]

        delegate?.dismissChannelGuide() { [weak self] in
            self?.change(channel: channel)
        }
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard let index = channels.index(where: { return $0.number == self.currentNumber }) else {
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
        return scheduleData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleData[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return scheduleData[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! MessageTableViewCell

        let event = scheduleData[indexPath.section].items[indexPath.row]
        cell.usernameLabel.text = event.time
        cell.messageLabel.text = event.title

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

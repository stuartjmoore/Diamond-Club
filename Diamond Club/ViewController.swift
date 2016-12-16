//
//  ViewController.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/10/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit
import AVKit

private var AVPlayerItemStatusObservationContext = 0
private var UITableViewContentSizeObservationContext = 1

class ViewController: UIViewController {

    fileprivate var playerItem: AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &AVPlayerItemStatusObservationContext)
        } didSet {
            playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.initial, .new, .old], context: &AVPlayerItemStatusObservationContext)
        }
    }

    fileprivate let player = AVPlayer()
    fileprivate let playerViewController = AVPlayerViewController()

    @IBOutlet private var showChannelsContraint: NSLayoutConstraint!
    @IBOutlet private var hideChannelsContraint: NSLayoutConstraint!
    @IBOutlet fileprivate var channelCollectionView: UICollectionView!

    @IBOutlet private var showChatContraint: NSLayoutConstraint!
    @IBOutlet private var hideChatContraint: NSLayoutConstraint!
    @IBOutlet fileprivate var chatTableView: UITableView!

    fileprivate let topTapGesture = UITapGestureRecognizer()
    fileprivate let bottomTapGesture = UITapGestureRecognizer()

    private let chatRealm = IRCClient(host: "irc.chatrealm.net", port: 6667, room: "chat", nick: "AppleTV\(arc4random_uniform(10_000))")
    fileprivate var chatData: [(username: String, message: String)] = []

    fileprivate var channels: [Channel]? {
        didSet {
            channelCollectionView?.reloadData()
            channelCollectionView?.setNeedsFocusUpdate()
            channelCollectionView?.updateFocusIfNeeded()
        }
    }

    // MARK: -

    override var preferredFocusedView: UIView? {
        return playerViewController.view
    }

    // MARK: -

    override func viewDidLoad() {
        chatTableView?.addObserver(self, forKeyPath: #keyPath(UITableView.contentSize), options: [.initial], context: &UITableViewContentSizeObservationContext)
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 66

        chatRealm.delegate = self
        chatRealm.start()

        playerViewController.player = player
        playerViewController.view.frame = view.bounds

        addChildViewController(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParentViewController: self)

        playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        playerViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        playerViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        topTapGesture.addTarget(self, action: #selector(handleTopTapGesture(_:)))
        topTapGesture.allowedPressTypes = [NSNumber(integerLiteral: UIPressType.upArrow.rawValue)]
        topTapGesture.delegate = self
        playerViewController.view.addGestureRecognizer(topTapGesture)

        bottomTapGesture.addTarget(self, action: #selector(handleBottomTapGesture(_:)))
        bottomTapGesture.allowedPressTypes = [NSNumber(integerLiteral: UIPressType.downArrow.rawValue)]
        bottomTapGesture.delegate = self
        playerViewController.view.addGestureRecognizer(bottomTapGesture)

        DiamondClub.getLiveChannels() { (channels) in
            self.channels = channels

            if let channelIndex = (channels.count > 0 ? 0 : nil) {
                let url = DiamondClub.streamURL(for: channels[channelIndex].number)
                self.updatePlayerItem(playing: url)
            }
        }
    }

    // MARK: - Touches

    func handleTopTapGesture(_ gesture: UITapGestureRecognizer) {
        if showChannelsContraint.isActive {
            NSLayoutConstraint.deactivate([showChannelsContraint])
            NSLayoutConstraint.activate([hideChannelsContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: {
                self.view.layoutIfNeeded()
            }).startAnimation()
        } else {
            NSLayoutConstraint.activate([showChannelsContraint])
            NSLayoutConstraint.deactivate([hideChannelsContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
                self.view.layoutIfNeeded()
            }).startAnimation()
        }
    }

    func handleBottomTapGesture(_ gesture: UITapGestureRecognizer) {
        if showChatContraint.isActive {
            NSLayoutConstraint.deactivate([showChatContraint])
            NSLayoutConstraint.activate([hideChatContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: {
                self.view.layoutIfNeeded()
            }).startAnimation()
        } else {
            NSLayoutConstraint.activate([showChatContraint])
            NSLayoutConstraint.deactivate([hideChatContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
                self.view.layoutIfNeeded()
            }).startAnimation()
        }
    }

    // MARK: - Change Channel Streams

    fileprivate func updatePlayerItem(playing url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.replaceCurrentItem(with: playerItem)

        self.playerItem = playerItem
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &AVPlayerItemStatusObservationContext {
            if case .readyToPlay? = playerItem?.status, player.rate == 0 {
                player.play()
            }
        } else if context == &UITableViewContentSizeObservationContext {
            chatTableView.contentInset.top = max(0, chatTableView.frame.height - chatTableView.contentSize.height)
            chatTableView.contentOffset.y = chatTableView.contentSize.height - chatTableView.frame.height
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: -

    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &AVPlayerItemStatusObservationContext)
        playerViewController.player = nil
    }

}

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === topTapGesture || gestureRecognizer === bottomTapGesture
    }
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell

        cell.usernameLabel.text = chatData[indexPath.row].username
        cell.messageLabel.text = chatData[indexPath.row].message

        return cell
    }

}

extension ViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels?.count ?? 6 // TODO: remove
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! ChannelCollectionViewCell

        guard let item = channels?[indexPath.row] else {
            cell.titleLabel.text = "Test"
            cell.iconImageView.image = #imageLiteral(resourceName: "offline")
            return cell
        }

        cell.titleLabel.text = item.title
        cell.iconImageView.image = nil

        DiamondClub.getChannelIcon(for: item.number) { (image) in
            cell.iconImageView.image = image
        }

        return cell
    }

}

extension ViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = channels?[indexPath.row] else {
            return
        }

        let url = DiamondClub.streamURL(for: item.number)
        updatePlayerItem(playing: url)
    }

}

extension ViewController: IRCClientDelegate {

    func IRC(_ client: IRCClient, didReceiveCommand command: IRCClient.Command, withMessage message: String?, andArguments: [String], fromSource: String?) {
        print("\(command)\t| \(message ?? "")")

        chatData.append((username: command.rawValue.uppercased(), message: message ?? ""))
        chatTableView.insertRows(at: [IndexPath(row: chatData.count - 1, section: 0)], with: .none)
    }

    func IRC(_ client: IRCClient, didReceiveMessage message: String, fromUsername username: String) {
        print("\(username)\t| \(message)")

        chatData.append((username: username, message: message))
        chatTableView.insertRows(at: [IndexPath(row: chatData.count - 1, section: 0)], with: .none)
    }

    func IRC(_ client: IRCClient, didReceiveError error: Error) {
        return
    }

    func IRCStreamDidEnd(_ client: IRCClient) {
        return
    }

}

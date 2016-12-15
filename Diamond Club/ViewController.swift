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

    enum Direction {
        case left, right
    }

    fileprivate var playerItem: AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &AVPlayerItemStatusObservationContext)
        } didSet {
            playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.initial, .new, .old], context: &AVPlayerItemStatusObservationContext)
        }
    }

    fileprivate let player = AVPlayer()
    fileprivate let playerViewController = AVPlayerViewController()

    private var topConstraint: NSLayoutConstraint?
    private var botomConstraint: NSLayoutConstraint?
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?

    fileprivate let panGesture = UIPanGestureRecognizer()

    private let chatRealm = IRCClient(host: "irc.chatrealm.net", port: 6667, room: "test", nick: "AppleTV\(arc4random_uniform(10_000))")
    @IBOutlet fileprivate var chatTableView: UITableView!
    fileprivate var chatData: [(username: String, message: String)] = []

    fileprivate var channels: [Channel]? {
        didSet {
            channelCollectionView?.reloadData()
            channelCollectionView?.setNeedsFocusUpdate()
            channelCollectionView?.updateFocusIfNeeded()
        }
    }

    @IBOutlet fileprivate var channelCollectionView: UICollectionView!

    override var preferredFocusedView: UIView? {
        return channelCollectionView
    }

    // MARK: -

    override func viewDidLoad() {
        chatTableView?.addObserver(self, forKeyPath: #keyPath(UITableView.contentSize), options: [.initial], context: &UITableViewContentSizeObservationContext)
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 66
/*
        chatRealm.delegate = self
        chatRealm.start()
*/
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
/*
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
*/
        DiamondClub.getLiveChannels() { (channels) in
            self.channels = channels

            if let channelIndex = (channels.count > 0 ? 0 : nil) {
                let url = DiamondClub.streamURL(for: channels[channelIndex].number)
                self.updatePlayerItem(playing: url)
            }
        }
    }

    // MARK: - Overlay

    private func showChangeChannelView() {
        UIViewPropertyAnimator(duration: 0.1, curve: .easeIn, animations: {
        }).startAnimation()
    }

    private func hideChangeChannelView() {
        UIViewPropertyAnimator(duration: 1, curve: .easeOut, animations: {
        }).startAnimation()

        leftConstraint?.constant = 0
        rightConstraint?.constant = 0

        UIViewPropertyAnimator(duration: 0.75, dampingRatio: 0.25, animations: {
            self.view.layoutIfNeeded()
        }).startAnimation()
    }

    // MARK: - Touches
/*
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        dump("pressesBegan: (\(presses), with: \(presses.first?.gestureRecognizers))")
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        dump("pressesEnded: (\(presses), with: \(presses.first?.gestureRecognizers))")
        super.pressesEnded(presses, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showChangeChannelView()
        dump("touchesBegan: (\(touches), with: \(touches.first?.location(in: touches.first?.view)))")
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideChangeChannelView()
        dump("touchesEnded: (\(touches), with: \(touches.first?.location(in: touches.first?.view))")
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideChangeChannelView()
        dump("touchesCancelled: (\(touches), with: \(touches.first?.location(in: touches.first?.view))")
        super.touchesCancelled(touches, with: event)
    }

    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .possible:
            print("possible")
            break

        case .began:
            print("began")
            showChangeChannelView()

        case .changed:
            print("changed")
            showChangeChannelView()

            let translation = gesture.translation(in: gesture.view).x / 6

            if translation > 0 {
                leftConstraint?.constant = abs(translation)
                rightConstraint?.constant = -abs(translation)
            } else if translation < 0 {
                leftConstraint?.constant = -abs(translation)
                rightConstraint?.constant = abs(translation)
            }

        case .ended:
            print("ended")
            let translation = gesture.translation(in: gesture.view).x
            let boundsWidth = gesture.view?.frame.width ?? 0

            if let channelIndex = currentChannelIndex, let channels = channels, channels.count > 1 {
                if translation > 0 && translation > boundsWidth / 2 {
                    let prevChannelIndex = (channelIndex == 0) ? channels.count - 1 : channelIndex - 1
                    let url = DiamondClub.streamURL(for: channels[prevChannelIndex].number)
                    currentChannelIndex = prevChannelIndex
                    updatePlayerItem(playing: url)
                } else if translation < 0  && -translation > boundsWidth / 2 {
                    let nextChannelIndex = (channelIndex == channels.count - 1) ? 0 : channelIndex + 1
                    let url = DiamondClub.streamURL(for: channels[nextChannelIndex].number)
                    currentChannelIndex = nextChannelIndex
                    updatePlayerItem(playing: url)
                }
            }

            fallthrough

        case .failed, .cancelled:
            print("failed, cancelled")
            hideChangeChannelView()
        }
    }
*/
    // MARK: - Change Channel Streams

    fileprivate func updatePlayerItem(playing url: URL) {
/*        if let channelIndex = currentChannelIndex, let channels = channels, channelIndex < channels.count {

            DiamondClub.getChannelIcon(for: channels[channelIndex].number) { (image) in
                //
            }

            currentChannelLabel.text = channels[channelIndex].title

            if channelIndex - 1 >= 0 {
                prevChannelLabel.text = channels[channelIndex - 1].title
            } else if channels.count > 0 {
                prevChannelLabel.text = channels[channels.count - 1].title
            } else {
                prevChannelLabel.text = nil
            }

            if channelIndex + 1 < channels.count {
                nextChannelLabel.text = channels[channelIndex + 1].title
            } else if channels.count > 0 {
                nextChannelLabel.text = channels[0].title
            } else {
                nextChannelLabel.text = nil
            }
        }
*/
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
/*
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === pressGesture || (gestureRecognizer === panGesture && player.rate != 0)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === pressGesture && gestureRecognizer.view === otherGestureRecognizer.view
    }
*/
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
        return channels?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! ChannelCollectionViewCell

        guard let item = channels?[indexPath.row] else {
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

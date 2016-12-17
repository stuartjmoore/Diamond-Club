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
    fileprivate var channelGuideViewController: ChannelGuideViewController!
    @IBOutlet fileprivate var channelBlackView: UIView!

    @IBOutlet private var showChatContraint: NSLayoutConstraint!
    @IBOutlet private var hideChatContraint: NSLayoutConstraint!
    @IBOutlet fileprivate var chatTableView: UITableView!

    fileprivate let topTapGesture = UITapGestureRecognizer()
    fileprivate let bottomTapGesture = UITapGestureRecognizer()

    private let chatRealm = IRCClient(host: "irc.chatrealm.net", port: 6667, room: "test", nick: "AppleTV\(arc4random_uniform(10_000))")
    fileprivate var chatData: [(username: String, message: String)] = []

    // MARK: -

    override var preferredFocusedView: UIView? {
        return showChannelsContraint.isActive ? channelGuideViewController.collectionView : playerViewController.view
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChannelGuideViewControllerSegue" {
            channelGuideViewController = segue.destination as? ChannelGuideViewController
            channelGuideViewController.delegate = self
        }
    }

    // MARK: -

    override func viewDidLoad() {
        chatTableView?.addObserver(self, forKeyPath: #keyPath(UITableView.contentSize), options: [.initial], context: &UITableViewContentSizeObservationContext)
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 66
        chatTableView.mask = nil
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

        topTapGesture.addTarget(self, action: #selector(handleTopTapGesture(_:)))
        topTapGesture.allowedPressTypes = [.upArrow]
        topTapGesture.delegate = self
        playerViewController.view.addGestureRecognizer(topTapGesture)

        bottomTapGesture.addTarget(self, action: #selector(handleBottomTapGesture(_:)))
        bottomTapGesture.allowedPressTypes = [.downArrow]
        bottomTapGesture.delegate = self
        playerViewController.view.addGestureRecognizer(bottomTapGesture)
    }

    // MARK: - Touches

    func handleTopTapGesture(_ gesture: UITapGestureRecognizer) {
        toggleChannelGuide(display: true)
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

    fileprivate func toggleChannelGuide(display: Bool) {
        if display {
            NSLayoutConstraint.activate([showChannelsContraint])
            NSLayoutConstraint.deactivate([hideChannelsContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
                self.channelBlackView.alpha = 1
                self.view.layoutIfNeeded()
            }).startAnimation()
        } else {
            NSLayoutConstraint.deactivate([showChannelsContraint])
            NSLayoutConstraint.activate([hideChannelsContraint])

            UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: {
                self.channelBlackView.alpha = 0
                self.view.layoutIfNeeded()
            }).startAnimation()
        }
        
        setNeedsFocusUpdate()
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

extension ViewController: ChannelGuideViewControllerDelegate {

    func updatePlayerItem(playing url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.replaceCurrentItem(with: playerItem)

        self.playerItem = playerItem
    }

    func dismissChannelGuide() {
        toggleChannelGuide(display: false)
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

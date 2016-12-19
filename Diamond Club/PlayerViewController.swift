//
//  PlayerViewController.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/10/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit
import AVKit

private var AVPlayerItemStatusObservationContext = 0
private var UITableViewContentSizeObservationContext = 1

private let ChannelGuideViewControllerSegue = "ChannelGuideViewControllerSegue"
private let ChatRealmViewControllerSegue = "ChatRealmViewControllerSegue"

class PlayerViewController: UIViewController {

    fileprivate var playerItem: AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &AVPlayerItemStatusObservationContext)
        } didSet {
            playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.initial, .new, .old], context: &AVPlayerItemStatusObservationContext)
        }
    }

    fileprivate let player = AVPlayer()
    fileprivate let playerViewController = AVPlayerViewController()

    @IBOutlet fileprivate var notBroadcastingLabel: UILabel!

    @IBOutlet private var showChannelsContraint: NSLayoutConstraint!
    @IBOutlet private var hideChannelsContraint: NSLayoutConstraint!
    fileprivate var channelGuideViewController: ChannelGuideViewController!
    @IBOutlet fileprivate var channelBlackView: UIView!

    @IBOutlet private var showChatContraint: NSLayoutConstraint!
    @IBOutlet private var hideChatContraint: NSLayoutConstraint!
    fileprivate var chatRealmViewController: ChatRealmViewController!

    fileprivate let topTapGesture = UITapGestureRecognizer()
    fileprivate let bottomTapGesture = UITapGestureRecognizer()

    // MARK: -

    override var preferredFocusedView: UIView? {
        return showChannelsContraint.isActive ? channelGuideViewController.collectionView : playerViewController.view
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ChannelGuideViewControllerSegue {
            channelGuideViewController = segue.destination as? ChannelGuideViewController
            channelGuideViewController.delegate = self
        } else if segue.identifier == ChatRealmViewControllerSegue {
            chatRealmViewController = segue.destination as? ChatRealmViewController
        }
    }

    // MARK: -

    override func viewDidLoad() {
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
        let animator: UIViewPropertyAnimator

        if showChatContraint.isActive {
            NSLayoutConstraint.deactivate([showChatContraint])
            NSLayoutConstraint.activate([hideChatContraint])

            animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                self.view.layoutIfNeeded()
            }
        } else {
            NSLayoutConstraint.activate([showChatContraint])
            NSLayoutConstraint.deactivate([hideChatContraint])

            animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
                self.view.layoutIfNeeded()
            }
        }

        animator.startAnimation()
    }

    fileprivate func toggleChannelGuide(display: Bool, completion: (() -> Void)? = nil) {
        let animator: UIViewPropertyAnimator

        if display {
            NSLayoutConstraint.activate([showChannelsContraint])
            NSLayoutConstraint.deactivate([hideChannelsContraint])

            animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
                self.channelBlackView.alpha = 1
                self.view.layoutIfNeeded()
            }
        } else {
            NSLayoutConstraint.deactivate([showChannelsContraint])
            NSLayoutConstraint.activate([hideChannelsContraint])

            animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                self.channelBlackView.alpha = 0
                self.view.layoutIfNeeded()
            }
        }

        animator.addCompletion { _ in
            completion?()
        }

        animator.startAnimation()
        setNeedsFocusUpdate()
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &AVPlayerItemStatusObservationContext {
            if case .readyToPlay? = playerItem?.status, player.rate == 0 {
                player.play()
            }

            if case .failed? = playerItem?.status {
                let fadeInAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                    self.notBroadcastingLabel.alpha = 1
                }

                fadeInAnimator.startAnimation()
            } else {
                let fadeOutAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
                    self.notBroadcastingLabel.alpha = 0
                }

                fadeOutAnimator.startAnimation()
            }
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

extension PlayerViewController: ChannelGuideViewControllerDelegate {

    func updatePlayerItem(playing url: URL) {
        player.replaceCurrentItem(with: nil)

        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.replaceCurrentItem(with: playerItem)

        self.playerItem = playerItem
    }

    func dismissChannelGuide(completion: (() -> Void)?) {
        toggleChannelGuide(display: false, completion: completion)
    }

}

extension PlayerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === topTapGesture || gestureRecognizer === bottomTapGesture
    }
}

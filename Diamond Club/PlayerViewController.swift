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
private var AVNowPlayingInfoHintViewObservationContext = 2
private var AVNowPlayingDimmingViewObservationContext = 3

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
    private var playerInfoHintView: UIView?
    private var playerDimmingView: UIView?

    @IBOutlet fileprivate var notBroadcastingLabel: UILabel!

    @IBOutlet private var showChannelsContraint: NSLayoutConstraint!
    @IBOutlet private var hideChannelsContraint: NSLayoutConstraint!
    @IBOutlet private var coachChannelContraint: NSLayoutConstraint!
    @IBOutlet private var channelArrowImageView: UIImageView!
    @IBOutlet private var channelCoachLabel: UILabel!
    fileprivate var channelGuideViewController: ChannelGuideViewController!
    @IBOutlet fileprivate var channelBlackView: UIView!

    @IBOutlet private var showChatContraint: NSLayoutConstraint!
    @IBOutlet private var hideChatContraint: NSLayoutConstraint!
    @IBOutlet private var coachChatContraint: NSLayoutConstraint!
    @IBOutlet private var chatArrowImageView: UIImageView!
    @IBOutlet private var chatCoachLabel: UILabel!
    fileprivate var chatRealmViewController: ChatRealmViewController!
    @IBOutlet fileprivate var chatRealmViewContainer: UIView!

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

        playerViewController.contentOverlayView?.addSubview(chatRealmViewContainer)
        playerViewController.contentOverlayView?.addSubview(chatCoachLabel)
        playerViewController.contentOverlayView?.addSubview(chatArrowImageView)

        playerInfoHintView = playerViewController.view.findView(is: "AVNowPlayingInfoHintView")
        playerInfoHintView?.addObserver(self, forKeyPath: #keyPath(UIView.alpha), options: [.initial, .new], context: &AVNowPlayingInfoHintViewObservationContext)

        playerDimmingView = playerViewController.view.findView(is: "AVNowPlayingDimmingView")
        playerDimmingView?.addObserver(self, forKeyPath: #keyPath(UIView.alpha), options: [.initial, .new], context: &AVNowPlayingDimmingViewObservationContext)
    }

    // MARK: - Touches

    func handleTopTapGesture(_ gesture: UITapGestureRecognizer) {
        toggleChannelGuide(display: true)
    }

    func handleBottomTapGesture(_ gesture: UITapGestureRecognizer) {
        let animator: UIViewPropertyAnimator
        let curve: UIViewAnimationCurve

        if showChatContraint.isActive {
            NSLayoutConstraint.deactivate([showChatContraint])
            NSLayoutConstraint.activate([hideChatContraint])
            chatArrowImageView.image = #imageLiteral(resourceName: "swipe-up-icon")
            coachChatContraint.constant = 160
            curve = .easeIn
        } else {
            NSLayoutConstraint.activate([showChatContraint])
            NSLayoutConstraint.deactivate([hideChatContraint])
            chatArrowImageView.image = #imageLiteral(resourceName: "swipe-down-icon")
            coachChatContraint.constant = 28
            curve = .easeOut
        }

        animator = UIViewPropertyAnimator(duration: 0.3, curve: curve) {
            self.view.layoutIfNeeded()
        }

        animator.startAnimation()
    }

    fileprivate func toggleChannelGuide(display: Bool, completion: (() -> Void)? = nil) {
        let animator: UIViewPropertyAnimator
        let curve: UIViewAnimationCurve

        if display {
            NSLayoutConstraint.activate([showChannelsContraint])
            NSLayoutConstraint.deactivate([hideChannelsContraint])
            channelArrowImageView.image = #imageLiteral(resourceName: "swipe-up-icon")
            coachChannelContraint.constant = 28
            curve = .easeOut
        } else {
            NSLayoutConstraint.deactivate([showChannelsContraint])
            NSLayoutConstraint.activate([hideChannelsContraint])
            channelArrowImageView.image = #imageLiteral(resourceName: "swipe-down-icon")
            coachChannelContraint.constant = 58
            curve = .easeIn
        }

        animator = UIViewPropertyAnimator(duration: 0.3, curve: curve) {
            self.channelBlackView.alpha = display ? 1 : 0
            self.view.layoutIfNeeded()
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
        } else if context == &AVNowPlayingInfoHintViewObservationContext, let alpha = change?[.newKey] as? CGFloat {
            channelArrowImageView.alpha = abs(alpha - 1)
            channelCoachLabel.alpha = abs(alpha - 1)
        } else if context == &AVNowPlayingDimmingViewObservationContext, let alpha = change?[.newKey] as? CGFloat {
            channelArrowImageView.alpha = playerInfoHintView?.alpha == 1 ? 0 : alpha
            channelCoachLabel.alpha = playerInfoHintView?.alpha == 1 ? 0 : alpha
            chatArrowImageView.alpha = alpha
            chatCoachLabel.alpha = alpha
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

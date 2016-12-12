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

class ViewController: UIViewController {

    enum Direction {
        case left, right
    }

    fileprivate let leftTapGesture = UITapGestureRecognizer()
    fileprivate let rightTapGesture = UITapGestureRecognizer()

    private var playerItem: AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: "status", context: &AVPlayerItemStatusObservationContext)
        } didSet {
            playerItem?.addObserver(self, forKeyPath: "status", options: [.initial, .new, .old], context: &AVPlayerItemStatusObservationContext)
        }
    }

    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    private var topConstraint: NSLayoutConstraint?
    private var botomConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var offRightContraint: NSLayoutConstraint?
    private var offLeftContraint: NSLayoutConstraint?

    private var channels: [Channel]?
    private var currentChannelIndex: Int?

    override var preferredFocusedView: UIView? {
        return playerViewController?.view
    }

    // MARK: -

    override func viewDidLoad() {
        leftTapGesture.addTarget(self, action: #selector(handleLeftTapGesture(_:)))
        leftTapGesture.allowedPressTypes = [NSNumber(value: UIPressType.leftArrow.rawValue as Int)]
        leftTapGesture.delegate = self

        rightTapGesture.addTarget(self, action: #selector(handleRightTapGesture(_:)))
        rightTapGesture.allowedPressTypes = [NSNumber(value: UIPressType.rightArrow.rawValue as Int)]
        rightTapGesture.delegate = self

        DiamondClub.getLiveChannels() { (channels) in
            self.channels = channels
            self.currentChannelIndex = (channels.count > 0) ? 0 : nil

            if let channelIndex = self.currentChannelIndex {
                let url = DiamondClub.streamURL(for: channels[channelIndex].number)
                self.addPlayerViewController(playing: url)
            }
        }
    }

    // MARK: - Gesture Recognizers

    func handleLeftTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let channelIndex = currentChannelIndex, let channels = channels, channels.count > 1 else {
            return bouncePlayer(from: .left)
        }

        let prevChannelIndex = (channelIndex == 0) ? channels.count - 1 : channelIndex - 1
        let url = DiamondClub.streamURL(for: channels[prevChannelIndex].number)

        addPlayerViewController(playing: url, from: .left)
        currentChannelIndex = prevChannelIndex
    }

    func handleRightTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let channelIndex = currentChannelIndex, let channels = channels, channels.count > 1 else {
            return bouncePlayer(from: .right)
        }

        let nextChannelIndex = (channelIndex == channels.count - 1) ? 0 : channelIndex + 1
        let url = DiamondClub.streamURL(for: channels[nextChannelIndex].number)

        addPlayerViewController(playing: url, from: .right)
        currentChannelIndex = nextChannelIndex
    }

    // MARK: - Change Channel Streams

    private func bouncePlayer(from direction: Direction) {
        self.leftConstraint?.constant = (direction == .left) ? 90 : 0
        self.rightConstraint?.constant = (direction == .right) ? 90 : 0

        let slideOutAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {
            self.view.layoutIfNeeded()
        }

        slideOutAnimator.addCompletion() { _ in
            self.leftConstraint?.constant = 0
            self.rightConstraint?.constant = 0

            let bounceInAnimator = UIViewPropertyAnimator(duration: 0.75, dampingRatio: 0.25) {
                self.view.layoutIfNeeded()
            }
            
            bounceInAnimator.startAnimation()
        }

        slideOutAnimator.startAnimation()
    }

    private func addPlayerViewController(playing url: URL, from direction: Direction? = nil) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let player = AVPlayer(playerItem: playerItem)

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = view.bounds
        playerViewController.view.alpha = (direction == nil) ? 1 : 0
        playerViewController.view.addGestureRecognizer(leftTapGesture)
        playerViewController.view.addGestureRecognizer(rightTapGesture)

        addChildViewController(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParentViewController: self)

        let topConstraint = playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        let botomConstraint = playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let widthConstraint = playerViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor)

        let leftConstraint = playerViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor)
        leftConstraint.priority = 999

        let rightConstraint = playerViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        rightConstraint.priority = 999

        let offRightContraint = playerViewController.view.centerXAnchor.constraint(equalTo: view.rightAnchor)
        let offLeftContraint = playerViewController.view.centerXAnchor.constraint(equalTo: view.leftAnchor)

        topConstraint.isActive = true
        botomConstraint.isActive = true
        widthConstraint.isActive = true

        leftConstraint.isActive = (direction == nil)
        rightConstraint.isActive = (direction == nil)
        offRightContraint.isActive = (direction == .right)
        offLeftContraint.isActive = (direction == .left)

        view.layoutIfNeeded()

        leftConstraint.isActive = true
        rightConstraint.isActive = true
        offRightContraint.isActive = false
        offLeftContraint.isActive = false

        self.leftConstraint?.isActive = (direction == nil)
        self.rightConstraint?.isActive = (direction == nil)
        self.offRightContraint?.isActive = (direction == .left)
        self.offLeftContraint?.isActive = (direction == .right)

        let duration = (direction == nil) ? 0 : 0.3

        let slideInAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn) {
            playerViewController.view.alpha = 1
            self.playerViewController?.view.alpha = 0
            self.view.layoutIfNeeded()
        }

        slideInAnimator.addCompletion { _ in
            self.playerViewController?.willMove(toParentViewController: nil)
            self.playerViewController?.view.removeFromSuperview()
            self.playerViewController?.removeFromParentViewController()

            self.playerItem = playerItem
            self.player = player
            self.playerViewController = playerViewController

            self.topConstraint = topConstraint
            self.botomConstraint = botomConstraint
            self.widthConstraint = widthConstraint
            self.leftConstraint = leftConstraint
            self.rightConstraint = rightConstraint
            self.offRightContraint = offRightContraint
            self.offLeftContraint = offLeftContraint

//            player.play()
        }
        
        slideInAnimator.startAnimation()
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &AVPlayerItemStatusObservationContext {
            if case .readyToPlay? = playerItem?.status, player?.rate == 0 {
                player?.play()
            } else if case .failed? = playerItem?.status {
                
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: -

    deinit {
        playerItem?.removeObserver(self, forKeyPath: "status", context: &AVPlayerItemStatusObservationContext)
        playerViewController?.player = nil
    }

}

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldBeRequiredToFailBy otherGesture: UIGestureRecognizer) -> Bool {
        return (gesture === leftTapGesture && gesture.view === otherGesture.view) || (gesture === rightTapGesture && gesture.view === otherGesture.view)
    }

}

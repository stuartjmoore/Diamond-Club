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

    fileprivate var playerItem: AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: "status", context: &AVPlayerItemStatusObservationContext)
        } didSet {
            playerItem?.addObserver(self, forKeyPath: "status", options: [.initial, .new, .old], context: &AVPlayerItemStatusObservationContext)
        }
    }

    fileprivate var player: AVPlayer?
    fileprivate var playerViewController: AVPlayerViewController?

    @IBOutlet private var changeChannelView: UIView!
    @IBOutlet private var changeChannelPrevConstraint: NSLayoutConstraint!
    @IBOutlet private var changeChannelNextConstraint: NSLayoutConstraint!

    @IBOutlet private var currentChannelImageView: UIImageView!
    @IBOutlet private var currentChannelLabel: UILabel!

    @IBOutlet private var prevChannelLabel: UILabel!
    @IBOutlet private var nextChannelLabel: UILabel!

    private var topConstraint: NSLayoutConstraint?
    private var botomConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var offRightContraint: NSLayoutConstraint?
    private var offLeftContraint: NSLayoutConstraint?

    fileprivate let panGesture = UIPanGestureRecognizer()

    private let chatRealm = IRCClient(host: "irc.chatrealm.net", port: 6667, room: "chat", nick: "AppleTV\(arc4random_uniform(10_000))")

    private var channels: [Channel]?
    private var currentChannelIndex: Int?

    override var preferredFocusedView: UIView? {
        return playerViewController?.view
    }

    // MARK: -

    override func viewDidLoad() {
//        chatRealm.delegate = self
//        chatRealm.start()

        changeChannelView.alpha = 0

        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        DiamondClub.getLiveChannels() { (channels) in
            self.channels = channels
            self.currentChannelIndex = (channels.count > 0) ? 0 : nil

            if let channelIndex = self.currentChannelIndex {
                let url = DiamondClub.streamURL(for: channels[channelIndex].number)
                self.addPlayerViewController(playing: url)
            }
        }
    }

    // MARK: - Overlay

    private func showChangeChannelView() {
        UIViewPropertyAnimator(duration: 0.1, curve: .easeIn, animations: {
            self.changeChannelView.alpha = 1
        }).startAnimation()
    }

    private func hideChangeChannelView() {
        changeChannelPrevConstraint.constant = 90
        changeChannelNextConstraint.constant = 90

        UIViewPropertyAnimator(duration: 1, curve: .easeOut, animations: {
            self.changeChannelView.alpha = 0
            self.changeChannelView.layoutIfNeeded()
        }).startAnimation()

        leftConstraint?.constant = 0
        rightConstraint?.constant = 0

        UIViewPropertyAnimator(duration: 0.75, dampingRatio: 0.25, animations: {
            self.view.layoutIfNeeded()
        }).startAnimation()
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showChangeChannelView()
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideChangeChannelView()
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideChangeChannelView()
        super.touchesCancelled(touches, with: event)
    }

    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .possible:
            break

        case .began:
            showChangeChannelView()

        case .changed:
            showChangeChannelView()

            let translation = gesture.translation(in: gesture.view).x / 6

            if translation > 0 {
                leftConstraint?.constant = abs(translation)
                rightConstraint?.constant = -abs(translation)
                changeChannelPrevConstraint.constant = 90 + abs(translation) / 2
                changeChannelNextConstraint.constant = 90
            } else if translation < 0 {
                leftConstraint?.constant = -abs(translation)
                rightConstraint?.constant = abs(translation)
                changeChannelPrevConstraint.constant = 90
                changeChannelNextConstraint.constant = 90 + abs(translation) / 2
            }

        case .ended:
            let translation = gesture.translation(in: gesture.view).x
            let boundsWidth = gesture.view?.frame.width ?? 0

            if let channelIndex = currentChannelIndex, let channels = channels, channels.count > 1 {
                if translation > 0 && translation > boundsWidth / 2 {
                    let prevChannelIndex = (channelIndex == 0) ? channels.count - 1 : channelIndex - 1
                    let url = DiamondClub.streamURL(for: channels[prevChannelIndex].number)
                    currentChannelIndex = prevChannelIndex
                    addPlayerViewController(playing: url, from: .left)
                } else if translation < 0  && -translation > boundsWidth / 2 {
                    let nextChannelIndex = (channelIndex == channels.count - 1) ? 0 : channelIndex + 1
                    let url = DiamondClub.streamURL(for: channels[nextChannelIndex].number)
                    currentChannelIndex = nextChannelIndex
                    addPlayerViewController(playing: url, from: .right)
                }
            }

            fallthrough

        case .failed, .cancelled:
            hideChangeChannelView()
        }
    }

    // MARK: - Change Channel Streams

    private func addPlayerViewController(playing url: URL, from direction: Direction? = nil) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let player = AVPlayer(playerItem: playerItem)

        let playerViewController = AVPlayerViewController()
        playerViewController.view.frame = view.bounds
        playerViewController.view.alpha = (direction == nil) ? 1 : 0

        addChildViewController(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(playerViewController.view, at: 0)
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

            playerViewController.player = player
        }
        
        slideInAnimator.startAnimation()

        if let channelIndex = currentChannelIndex, let channels = channels, channelIndex < channels.count {
            DiamondClub.getChannelIcon(for: channels[channelIndex].number) { (image) in
                self.currentChannelImageView.image = image
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

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panGesture && player?.rate != 0
    }

}

extension ViewController: IRCClientDelegate {

    func IRC(_ client: IRCClient, didReceiveCommand command: IRCClient.Command, withMessage message: String?, andArguments: [String], fromSource: String?) {
        print("\(command)\t| \(message ?? "")")
    }

    func IRC(_ client: IRCClient, didReceiveMessage message: String, fromUsername username: String) {
        print("\(username)\t| \(message)")
    }

    func IRC(_ client: IRCClient, didReceiveError error: Error) {
        return
    }

    func IRCStreamDidEnd(_ client: IRCClient) {
        return
    }

}

//
//  ChatRealmViewController.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/16/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import UIKit

private var UITableViewContentSizeObservationContext = 1

class ChatRealmViewController: UIViewController {

    @IBOutlet fileprivate var tableView: UITableView!

    private let chatRealm = IRCClient(host: "irc.chatrealm.net", port: 6667, room: "test", nick: "AppleTV\(arc4random_uniform(10_000))")
    fileprivate var data: [(username: String, message: String)] = []

    // MARK: -

    override func viewDidLoad() {
        tableView?.addObserver(self, forKeyPath: #keyPath(UITableView.contentSize), options: [.initial], context: &UITableViewContentSizeObservationContext)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 35
        tableView.mask = nil

        chatRealm.delegate = self
        chatRealm.start()
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &UITableViewContentSizeObservationContext {
            tableView.contentInset.top = max(0, tableView.frame.height - tableView.contentSize.height)
            tableView.contentOffset.y = tableView.contentSize.height - tableView.frame.height
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: -

    deinit {
        tableView?.removeObserver(self, forKeyPath: #keyPath(UITableView.contentSize), context: &UITableViewContentSizeObservationContext)
    }

}

extension ChatRealmViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell

        cell.usernameLabel.text = data[indexPath.row].username
        cell.messageLabel.text = data[indexPath.row].message

        return cell
    }

}

extension ChatRealmViewController: IRCClientDelegate {

    func IRC(_ client: IRCClient, didReceiveCommand command: IRCClient.Command, withMessage message: String?, andArguments: [String], fromSource: String?) {
        print("\(command)\t| \(message ?? "")")

        data.append((username: command.rawValue.uppercased(), message: message ?? ""))
        tableView.insertRows(at: [IndexPath(row: data.count - 1, section: 0)], with: .none)
    }

    func IRC(_ client: IRCClient, didReceiveMessage message: String, fromUsername username: String) {
        print("\(username)\t| \(message)")

        data.append((username: username, message: message))
        tableView.insertRows(at: [IndexPath(row: data.count - 1, section: 0)], with: .none)
    }

    func IRC(_ client: IRCClient, didReceiveError error: Error) {
        return
    }

    func IRCStreamDidEnd(_ client: IRCClient) {
        return
    }
    
}

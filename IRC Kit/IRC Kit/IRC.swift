//
//  IRC.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/11/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation

public class IRCClient {

    public enum Command: RawRepresentable {
        public typealias RawValue = String

        case user, nick, ping, pong, join, message, kick, quit, part, mode, notice, error, code(value: Int)

        public init?(rawValue: RawValue) {
            switch rawValue {
            case "USER": self = .user
            case "NICK": self = .nick
            case "PING": self = .ping
            case "PONG": self = .pong
            case "JOIN": self = .join
            case "PRIVMSG": self = .message
            case "KICK": self = .kick
            case "QUIT": self = .quit
            case "PART": self = .part
            case "MODE": self = .mode
            case "NOTICE": self = .notice
            case "ERROR": self = .error
            default:
                if let value = Int(rawValue) {
                    self = .code(value: value)
                } else {
                    return nil
                }
            }
        }

        public var rawValue: RawValue {
            switch self {
            case .user: return "USER"
            case .nick: return "NICK"
            case .ping: return "PING"
            case .pong: return "PONG"
            case .join: return "JOIN"
            case .message: return "PRIVMSG"
            case .kick: return "KICK"
            case .quit: return "QUIT"
            case .part: return "PART"
            case .mode: return "MODE"
            case .notice: return "NOTICE"
            case .error: return "ERROR"
            case .code(let value): return String(value)
            }
        }
    }

    enum LineParseError: Error {
        case noSource, noCommand, invalidCommand(command: String)
    }

    private var lastPartialLine: String?

    private lazy var task: URLSessionStreamTask = {
        return URLSession.shared.streamTask(withHostName: self.host, port: self.port)
    }()

    public weak var delegate: IRCClientDelegate?

    let host: String
    let port: Int

    let room: String
    let nick: String

    public init(host: String, port: Int, room: String, nick: String) {
        self.host = host
        self.port = port
        self.room = room
        self.nick = nick
    }

    public func start() {
        readFromStream()
        task.resume()

        write(command: .user, arguments: [nick, "8", "*"], message: "Apple TV Watcher")
        write(command: .nick, arguments: [nick])
    }

    private func write(command: Command, arguments: [String] = [], message: String = "") {
        let argString = arguments.joined(separator: " ")
        let line = command.rawValue + (argString != "" ? " " + argString : "") + (message != "" ? " :" + message : "") + "\r\n"

        guard let data = line.data(using: .utf8) else {
            return print("Error: dataUsingEncoding")
        }

        task.write(data, timeout: 30) { (error) in
            if let error = error {
                return print("Error: \(error)")
            }
        }
    }

    private func readFromStream() {
        task.readData(ofMinLength: 16, maxLength: 8096, timeout: .infinity) { [weak self] (data, end, error) in
            guard let this = self else {
                return
            }

            if let error = error {
                // TODO: retry on timeout
                DispatchQueue.main.async {
                    this.delegate?.IRC(this, didReceiveError: error)
                }

                return
            }

            do {
                if let data = data, var message = String(data: data, encoding: .utf8) {
                    if let lastPartialLine = this.lastPartialLine {
                        message = lastPartialLine + message
                        this.lastPartialLine = nil
                    }

                    if let lastNewlineRange = message.rangeOfLastNewline(), lastNewlineRange.upperBound != message.endIndex {
                        this.lastPartialLine = message.substring(from: lastNewlineRange.upperBound)
                        message = message.substring(to: lastNewlineRange.lowerBound)
                    } // TODO: if no newlines…

                    for line in message.components(separatedBy: .newlines) where line.characters.count > 0 {
                        do {
                            let parsed = try this.parseLine(line)

                            if case .ping = parsed.command, let code = parsed.message {
                                this.write(command: .pong, message: code)
                            } else if case .code(let number) = parsed.command, number == 1 {
                                this.write(command: .join, message: "#\(this.room)")
                            }

                            if let usernameRange = parsed.source?.range(of: "!"),
                                let username = parsed.source?.substring(to: usernameRange.lowerBound),
                                let message = parsed.message,
                                case .message = parsed.command {
                                DispatchQueue.main.async {
                                    this.delegate?.IRC(this, didReceiveMessage: message, fromUsername: username)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    this.delegate?.IRC(this,
                                                       didReceiveCommand: parsed.command,
                                                       withMessage: parsed.message,
                                                       andArguments: parsed.arguments,
                                                       fromSource: parsed.source)
                                }
                            }
                        } catch LineParseError.noSource {
                            DispatchQueue.main.async {
                                this.delegate?.IRC(this, didReceiveError: NSError(domain: "LineParseErrorDomain", code: 0, userInfo: nil))
                            }
                        } catch LineParseError.noCommand {
                            DispatchQueue.main.async {
                                this.delegate?.IRC(this, didReceiveError: NSError(domain: "LineParseErrorDomain", code: 1, userInfo: nil))
                            }
                        } catch LineParseError.invalidCommand(let command) {
                            DispatchQueue.main.async {
                                this.delegate?.IRC(this, didReceiveError: NSError(domain: "LineParseErrorDomain", code: 2, userInfo: ["command": command]))
                            }
                        }
                    }
                }

                if end {
                    DispatchQueue.main.async {
                        this.delegate?.IRCStreamDidEnd(this)
                    }
                } else {
                    this.readFromStream()
                }
            } catch {
                DispatchQueue.main.async {
                    this.delegate?.IRC(this, didReceiveError: NSError(domain: "LineParseErrorDomain", code: -1, userInfo: nil))
                }
            }
        }
    }

    private func parseLine(_ line: String) throws -> (source: String?, command: Command, arguments: [String], message: String?) {
        /*

         https://www.alien.net.au/irc/irc2numerics.html
         http://blog.initprogram.com/2010/10/14/a-quick-basic-primer-on-the-irc-protocol/

         :source ###/cmd optional-space-separated-arguments :optional-message-and-colon
         cmd :message (PING)

         */

        guard let sourceRange = line.rangeOfCharacter(from: CharacterSet.whitespaces) else {
            throw LineParseError.noSource
        }

        let sourceString = line.substring(to: sourceRange.lowerBound)
        let afterSource = line.substring(from: sourceRange.upperBound)

        if let command = Command(rawValue: sourceString), afterSource.hasPrefix(":") {
            let message = afterSource.substring(from: afterSource.characters.index(afterSource.startIndex, offsetBy: 1))
            return (source: nil, command: command, arguments: [], message: message)
        }

        let source = sourceString.substring(from: sourceString.characters.index(sourceString.startIndex, offsetBy: sourceString.hasPrefix(":") ? 1 : 0))

        guard let commandRange = afterSource.rangeOfCharacter(from: CharacterSet.whitespaces) else {
            throw LineParseError.noCommand
        }

        let commandString = afterSource.substring(to: commandRange.lowerBound)
        let afterCommand = afterSource.substring(from: commandRange.upperBound)

        guard let command = Command(rawValue: commandString) else {
            throw LineParseError.invalidCommand(command: commandString)
        }

        var arguments = [String]()
        var message: String? = nil

        if let argumentsRange = afterCommand.range(of: " :") {
            arguments = afterCommand.substring(to: argumentsRange.lowerBound).components(separatedBy: " ")
            message = afterCommand.substring(from: argumentsRange.upperBound)
        } else if afterCommand.hasPrefix(":") {
            message = afterCommand.substring(from: afterCommand.characters.index(afterCommand.startIndex, offsetBy: 1))
        } else {
            arguments = afterCommand.components(separatedBy: " ")
        }

        return (source: source, command: command, arguments: arguments, message: message)
    }

    deinit {
        task.closeRead()
        task.closeWrite()

        write(command: .part, arguments: [room], message: "Live stream closed.")
        write(command: .quit, message: "Live stream closed.")

        task.cancel()
    }
}

public protocol IRCClientDelegate: class {
    func IRC(_ client: IRCClient, didReceiveCommand: IRCClient.Command, withMessage: String?, andArguments: [String], fromSource: String?)
    func IRC(_ client: IRCClient, didReceiveMessage: String, fromUsername: String)
    func IRC(_ client: IRCClient, didReceiveError: Error)
    func IRCStreamDidEnd(_ client: IRCClient)
}

extension String {
    func rangeOfLastNewline() -> Range<Index>? {
        return rangeOfCharacter(from: CharacterSet.newlines, options: [.backwards])
    }
}

//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices
import Services

public protocol ChatManagerDelegate: AnyObject {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol])
    func messagesLooked(friendID: String, _ value: Bool)
    func typing(friendID: String, _ value: Bool)
}

public protocol ChatManagerProtocol {
    func addDelegate(_ delegate: ChatManagerDelegate)
    func removeDelegate<T>(_ delegate: T)
    func observeNewMessages(friendID: String)
    func observeLookedMessages(friendID: String)
    func observeTypingStatus(friendID: String)
}

public final class ChatManager {
    private let messagingService: MessagingServiceProtocol
    private let accountID: String
    private let coreDataService: CoreDataServiceProtocol
    private var sockets = [SocketProtocol]()
    private var delegates = [ChatManagerDelegate]()
    
    public init(messagingService: MessagingServiceProtocol,
                coreDataService: CoreDataServiceProtocol,
                accountID: String) {
        self.messagingService = messagingService
        self.accountID = accountID
        self.coreDataService = coreDataService
    }
    
    deinit {
        sockets.forEach { $0.remove() }
    }
}

extension ChatManager: ChatManagerProtocol {

    public func addDelegate(_ delegate: ChatManagerDelegate) {
        delegates.append(delegate)
    }
    
    public func removeDelegate<T>(_ delegate: T) {
        guard let index = delegates.firstIndex(where: { ($0 as? T) != nil }) else { return }
        delegates.remove(at: index)
    }
    
    public func observeNewMessages(friendID: String) {
        let cacheService = ChatsCacheService(accountID: accountID,
                                             friendID: friendID,
                                             coreDataService: coreDataService)
        let socket = messagingService.initMessagesSocket(lastMessageDate: cacheService.lastMessage?.date,
                                                         accountID: accountID,
                                                         from: friendID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messageModels):
                let messages: [MessageModelProtocol] = messageModels.compactMap {
                    guard let message = MessageModel(model: $0) else { return nil }
                    guard message.id != cacheService.lastMessage?.id else { return nil }
                    cacheService.storeRecievedMessage(message)
                    return message
                }
                self.delegates.forEach { delegate in
                    delegate.newMessagesRecieved(friendID: friendID, messages: messages)
                }
            case .failure:
                break
            }
        }
        sockets.append(socket)
    }
    
    public func observeLookedMessages(friendID: String) {
        let cacheService = ChatsCacheService(accountID: accountID,
                                             friendID: friendID,
                                             coreDataService: coreDataService)
        let socket = messagingService.initLookedSendedMessagesSocket(accountID: accountID, from: friendID) { [weak self] looked in
            defer {
                self?.delegates.forEach { delegate in
                    delegate.messagesLooked(friendID: friendID, looked)
                }
            }
            guard looked else { return }
            cacheService.removeAllNotLooked()
        }
        sockets.append(socket)
    }
    
    public func observeTypingStatus(friendID: String) {
        let socket = messagingService.initTypingStatusSocket(from: accountID, friendID: friendID) { typing in
            guard let typing = typing else { return }
            self.delegates.forEach { delegate in
                delegate.typing(friendID: friendID, typing)
            }
        }
        sockets.append(socket)
    }
}

//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices

public protocol CommunicationManagerProtocol: AnyObject {
    func isProfileFriend(userID: String) -> Bool
    func isProfileBlocked(userID: String) -> Bool
    func isProfileWaiting(userID: String) -> Bool
    func isProfileRequested(userID: String) -> Bool
    func requestCommunication(userID: String)
    func acceptRequestCommunication(userID: String, completion: @escaping (Result<Void, Error>) -> ())
    func denyRequestCommunication(userID: String)
    func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void)
    func blockProfile(_ id: String,
                      completion: @escaping (Result<Void, CommunicationManagerError.Block>) -> Void)
    func unblockProfile(_ id: String,
                        completion: @escaping (Result<Void, CommunicationManagerError.Block>) -> Void)
    func getChatsAndRequests() -> (chats: [ChatModelProtocol], requests: [RequestModelProtocol])
    func observeFriends(completion: @escaping ([ChatModelProtocol], [ChatModelProtocol]) -> Void)
    func observeRequests(completion: @escaping ([RequestModelProtocol], [RequestModelProtocol]) -> Void)
    func remove(chat: ChatModelProtocol)
}

public typealias CommunicationCacheServiceProtocol = AccountCacheServiceProtocol & RequestsCacheServiceProtocol & ChatsCacheServiceProtocol

public final class CommunicationManager {
    private let account: AccountModelProtocol
    private let accountID: String
    private let accountService: AccountServiceProtocol
    private let cacheService: CommunicationCacheServiceProtocol
    private let profileService: ProfilesServiceProtocol
    private let requestsService: RequestsServiceProtocol
    private var socket: SocketProtocol?
    
    init(accountID: String,
         account: AccountModelProtocol,
         accountService: AccountServiceProtocol,
         cacheService: CommunicationCacheServiceProtocol,
         profileService: ProfilesServiceProtocol,
         requestsService: RequestsServiceProtocol) {
        self.accountID = accountID
        self.account = account
        self.accountService = accountService
        self.cacheService = cacheService
        self.profileService = profileService
        self.requestsService = requestsService
    }
    
    deinit {
        socket?.remove()
    }
}

extension CommunicationManager: CommunicationManagerProtocol {
    
    public func isProfileFriend(userID: String) -> Bool {
        account.friendIds.contains(userID)
    }
    
    public func isProfileWaiting(userID: String) -> Bool {
        account.waitingsIds.contains(userID)
    }
    
    public func isProfileRequested(userID: String) -> Bool {
        account.requestIds.contains(userID)
    }
    
    public func isProfileBlocked(userID: String) -> Bool {
        account.blockedIds.contains(userID)
    }
    
    public func getChatsAndRequests() -> (chats: [ChatModelProtocol], requests: [RequestModelProtocol]) {
        return (cacheService.storedChats, cacheService.storedRequests)
    }

    public func denyRequestCommunication(userID: String) {
        requestsService.deny(toID: userID, fromID: accountID) { _ in }
    }
    
    public func acceptRequestCommunication(userID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        requestsService.accept(toID: userID, fromID: accountID) { _ in }
    }

    public func remove(chat: ChatModelProtocol) {
        self.requestsService.removeFriend(with: chat.friendID, from: accountID) { _ in }
    }

    public func observeFriends(completion: @escaping ([ChatModelProtocol], [ChatModelProtocol]) -> Void) {
        socket = requestsService.initFriendsSocket(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success((let add, let removed)):
                self.updateCurrentAccountFriends(add: add, removed: removed)
                var newFriends = [ChatModelProtocol]()
                let group = DispatchGroup()
                add.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chat = ChatModel(friend: profile)
                            guard !self.cacheService.storedChats.contains(where: { $0.friendID == chat.friendID }) else { return }
                            self.cacheService.store(chatModel: chat)
                            newFriends.append(chat)
                        case .failure:
                            break
                        }
                    }
                }
                var removedFriends = [ChatModelProtocol]()
                removed.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chat = ChatModel(friend: profile)
                            guard self.cacheService.storedChats.contains(where: { $0.friendID == chat.friendID }) else { return }
                            self.cacheService.removeChat(with: chat.friendID)
                            removedFriends.append(chat)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(newFriends, removedFriends)
                }
            case .failure:
                break
            }
        }
    }
    
    public func observeRequests(completion: @escaping ([RequestModelProtocol], [RequestModelProtocol]) -> Void) {
        socket = requestsService.initRequestsSocket(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success((let add, let removed)):
                self.updateCurrentAccountRequests(add: add, removed: removed)
                var newRequests = [RequestModelProtocol]()
                let group = DispatchGroup()
                add.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let request = RequestModel(sender: profile)
                            guard !self.cacheService.storedRequests.contains(where: { $0.senderID == request.senderID }) else { return }
                            self.cacheService.store(requestModel: request)
                            newRequests.append(request)
                        case .failure:
                            break
                        }
                    }
                }
                var removedRequests = [RequestModelProtocol]()
                removed.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let request = RequestModel(sender: profile)
                            guard self.cacheService.storedRequests.contains(where: { $0.senderID == request.senderID }) else { return }
                            self.cacheService.removeRequest(with: request.senderID)
                            removedRequests.append(request)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(newRequests, removedRequests)
                }
            case .failure:
                break
            }
        }
    }
    
    public func getChatsAndRequests(completion: @escaping (Result<([ChatModelProtocol], [RequestModelProtocol]), Error>) -> ()) {
        let storedRequests = cacheService.storedRequests
        let storedChats = cacheService.storedChats
        completion(.success((storedChats, storedRequests)))

        var refreshedChats = [ChatModelProtocol]()
        var refreshedRequests = [RequestModelProtocol]()
        let group = DispatchGroup()
        group.enter()
        getRequests { result in
            defer { group.leave() }
            switch result {
            case .success(let requests):
                refreshedRequests = requests
            case .failure:
                break
            }
        }
        group.enter()
        getChats { result in
            defer { group.leave() }
            switch result {
            case .success(let chats):
                refreshedChats = chats
            case .failure:
                break
            }
        }
        group.notify(queue: .main) {
            completion(.success((refreshedChats, refreshedRequests)))
        }
    }

    public func requestCommunication(userID: String) {
        requestsService.send(toID: userID, fromID: accountID) { result in
            switch result {
            case .success:
                self.account.requestIds.insert(userID)
                self.cacheService.store(accountModel: self.account)
            case .failure:
                break
            }
        }
    }
    
    public func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void) {
        accountService.getBlockedIds(accountID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                self.account.blockedIds = Set(ids)
                self.cacheService.store(accountModel: self.account)
                let group = DispatchGroup()
                var profiles = [ProfileModelProtocol]()
                ids.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            profiles.append(ProfileModel(profile: profile))
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(.success(profiles))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func blockProfile(_ id: String,
                             completion: @escaping (Result<Void, CommunicationManagerError.Block>) -> Void) {
        accountService.blockUser(accountID: accountID,
                                 userID: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                var errors = [Error]()
                let group = DispatchGroup()
                group.enter()
                self.requestsService.removeFriend(with: id, from: self.accountID) { result in
                    defer { group.leave() }
                    switch result {
                    case .success():
                        break
                    case .failure(let error):
                        errors.append(error)
                    }
                }
                group.enter()
                self.requestsService.deny(toID: id, fromID: self.accountID) { result in
                    defer { group.leave() }
                    switch result {
                    case .success():
                        break
                    case .failure(let error):
                        errors.append(error)
                    }
                }
                group.enter()
                self.requestsService.cancelRequest(toID: id, fromID: self.accountID) { result in
                    defer { group.leave() }
                    switch result {
                    case .success():
                        break
                    case .failure(let error):
                        errors.append(error)
                    }
                }
                group.notify(queue: .main) {
                    guard errors.isEmpty else {
                        completion(.failure(.cantBlock))
                        return
                    }
                    self.account.blockedIds.insert(id)
                    self.account.friendIds.remove(id)
                    self.account.waitingsIds.remove(id)
                    self.account.requestIds.remove(id)
                    self.cacheService.store(accountModel: self.account)
                    completion(.success(()))
                }
            case .failure:
                completion(.failure(.cantBlock))
            }
        }
    }
    
    public func unblockProfile(_ id: String,
                               completion: @escaping (Result<Void, CommunicationManagerError.Block>) -> Void) {
        accountService.unblockUser(accountID: accountID,
                                   userID: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                guard let firstIndex = self.account.blockedIds.firstIndex(of: id) else { return }
                self.account.blockedIds.remove(at: firstIndex)
                self.cacheService.store(accountModel: self.account)
                completion(.success(()))
            case .failure:
                completion(.failure(.cantUnblock))
            }
        }
    }
}

private extension CommunicationManager {
    func updateCurrentAccountFriends(add: [String], removed: [String]) {
        add.forEach {
            self.account.friendIds.insert($0)
        }
        removed.forEach {
            self.account.friendIds.remove($0)
        }
        cacheService.store(accountModel: self.account)
    }
    
    func updateCurrentAccountRequests(add: [String], removed: [String]) {
        add.forEach {
            self.account.waitingsIds.insert($0)
        }
        removed.forEach {
            self.account.waitingsIds.remove($0)
        }
        cacheService.store(accountModel: self.account)
    }
}

private extension CommunicationManager {
    func getRequests(completion: @escaping (Result<[RequestModelProtocol], Error>) -> ()) {
        requestsService.waitingIDs(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                self.account.waitingsIds = Set(ids)
                self.cacheService.store(accountModel: self.account)
                var requests = [RequestModelProtocol]()
                let group = DispatchGroup()
                ids.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let requestModel = RequestModel(sender: profile)
                            self.cacheService.store(requestModel: requestModel)
                            requests.append(requestModel)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(.success(requests))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getChats(completion: @escaping (Result<[ChatModelProtocol], Error>) -> ()) {
        requestsService.friendIDs(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                self.account.friendIds = Set(ids)
                self.cacheService.store(accountModel: self.account)
                var chats = [ChatModelProtocol]()
                let group = DispatchGroup()
                ids.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chatModel = ChatModel(friend: profile)
                            self.cacheService.store(chatModel: chatModel)
                            chats.append(chatModel)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(.success(chats))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

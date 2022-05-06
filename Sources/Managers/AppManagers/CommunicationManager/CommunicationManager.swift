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
}

public final class CommunicationManager {
    private let account: AccountModelProtocol
    private let accountID: String
    private let accountService: AccountServiceProtocol
    private let cacheService: AccountCacheServiceProtocol
    private let profileService: ProfilesServiceProtocol
    private let requestsService: RequestsServiceProtocol
    
    init(accountID: String,
         account: AccountModelProtocol,
         accountService: AccountServiceProtocol,
         cacheService: AccountCacheServiceProtocol,
         profileService: ProfilesServiceProtocol,
         requestsService: RequestsServiceProtocol) {
        self.accountID = accountID
        self.account = account
        self.accountService = accountService
        self.cacheService = cacheService
        self.profileService = profileService
        self.requestsService = requestsService
    }
}

extension CommunicationManager: CommunicationManagerProtocol {

    public func denyRequestCommunication(userID: String) {
        requestsService.deny(toID: userID, fromID: accountID)
        account.waitingsIds.remove(userID)
        cacheService.store(accountModel: account)
    }
    
    public func acceptRequestCommunication(userID: String, completion: @escaping (Result<Void, Error>) -> ()) {
        requestsService.accept(toID: userID, fromID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success():
                self.account.waitingsIds.remove(userID)
                self.account.friendIds.insert(userID)
                self.cacheService.store(accountModel: self.account)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
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
                self.account.blockedIds.insert(id)
                self.cacheService.store(accountModel: self.account)
                completion(.success(()))
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

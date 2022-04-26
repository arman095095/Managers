//
//  AuthManager.swift
//
//
//  Created by Арман Чархчян on 13.04.2022.
//

import NetworkServices
import Foundation

public protocol AccountManagerProtocol: AnyObject {
    func launch(completion: @escaping (Result<Void, AccountManagerError>) -> ())
    func isProfileBlocked(userID: String) -> Bool
    func getAccount(completion: @escaping (Result<Void, AccountManagerError>) -> ())
    func editAccount(username: String,
                     info: String,
                     sex: String,
                     country: String,
                     city: String,
                     birthday: String,
                     image: Data?,
                     imageURL: URL?,
                     completion: @escaping (Result<Void, AccountManagerError>) -> Void)
    func recoverAccount(completion: @escaping (Result<Void, AccountManagerError>) -> Void)
    func removeAccount(completion: @escaping (Result<Void, AccountManagerError>) -> Void)
    func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], AccountManagerError>) -> Void)
    func blockProfile(_ id: String,
                      completion: @escaping (Result<Void, AccountManagerError>) -> Void)
    func unblockProfile(_ id: String,
                        completion: @escaping (Result<Void, AccountManagerError>) -> Void)
    func setOffline()
    func setOnline()
    func signOut()
}

public enum AccountManagerContext {
    case afterAuthorization(accountID: String, account: AccountModelProtocol)
    case afterLaunch(accountID: String)
}

public final class AccountManager {
    
    private let accountID: String
    private var account: AccountModelProtocol?
    private let authService: AuthServiceProtocol
    private let accountService: AccountServiceProtocol
    private let remoteStorageService: RemoteStorageServiceProtocol
    private let profileService: ProfilesServiceProtocol
    
    private let quickAccessManager: QuickAccessManagerProtocol
    private let cacheService: AccountCacheServiceProtocol
    private let context: AccountManagerContext
    
    public init(context: AccountManagerContext,
                authService: AuthServiceProtocol,
                accountService: AccountServiceProtocol,
                remoteStorage: RemoteStorageServiceProtocol,
                quickAccessManager: QuickAccessManagerProtocol,
                profileService: ProfilesServiceProtocol,
                cacheService: AccountCacheServiceProtocol) {
        self.authService = authService
        self.accountService = accountService
        self.remoteStorageService = remoteStorage
        self.quickAccessManager = quickAccessManager
        self.profileService = profileService
        self.cacheService = cacheService
        self.context = context
        switch context {
        case .afterAuthorization(let accountID, _):
            self.accountID = accountID
        case .afterLaunch(let accountID):
            self.accountID = accountID
        }
    }
}

extension AccountManager: AccountManagerProtocol {
    
    public func launch(completion: @escaping (Result<Void, AccountManagerError>) -> ()) {
        switch context {
        case .afterAuthorization(_, let account):
            afterAuthorization(account: account, completion: completion)
        case .afterLaunch(let accountID):
            if let account = cacheService.storedAccount(with: accountID) {
                self.account = account
                completion(.success(()))
                getAccount { _ in }
            } else {
                getAccount(completion: completion)
            }
        }
    }
    
    public func getAccount(completion: @escaping (Result<Void, AccountManagerError>) -> ()) {
        profileService.getProfileInfo(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                self.accountService.getBlockedIds(accountID: self.accountID) { result in
                    switch result {
                    case .success(let ids):
                        let profile = ProfileModel(profile: user)
                        let account = AccountModel(profile: profile,
                                                   blockedIDs: Set(ids))
                        self.afterAuthorization(account: account, completion: completion)
                    case .failure(let error):
                        completion(.failure(.another(error: error)))
                    }
                }
            case .failure(let error):
                guard case .getData = error as? GetUserInfoError else {
                    completion(.failure(.another(error: error)))
                    return
                }
                completion(.failure(.profile(value: .emptyProfile)))
            }
        }
    }
    
    public func isProfileBlocked(userID: String) -> Bool {
        guard let currentAccount = account else { return false }
        return currentAccount.blockedIds.contains(userID)
    }
    
    public func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], AccountManagerError>) -> Void) {
        accountService.getBlockedIds(accountID: accountID) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success(let ids):
                currentAccount.blockedIds = Set(ids)
                self.cacheService.store(accountModel: currentAccount)
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
                completion(.failure(.another(error: error)))
            }
        }
    }
    
    public func blockProfile(_ id: String,
                             completion: @escaping (Result<Void, AccountManagerError>) -> Void) {
        accountService.blockUser(accountID: accountID,
                                 userID: id) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success:
                currentAccount.blockedIds.insert(id)
                self.cacheService.store(accountModel: currentAccount)
                completion(.success(()))
            case .failure:
                completion(.failure(.blocking(value: .cantBlock)))
            }
        }
    }
    
    public func unblockProfile(_ id: String,
                               completion: @escaping (Result<Void, AccountManagerError>) -> Void) {
        accountService.unblockUser(accountID: accountID,
                                   userID: id) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success:
                guard let firstIndex = currentAccount.blockedIds.firstIndex(of: id) else { return }
                currentAccount.blockedIds.remove(at: firstIndex)
                self.cacheService.store(accountModel: currentAccount)
                completion(.success(()))
            case .failure:
                completion(.failure(.blocking(value: .cantUnblock)))
            }
        }
    }
    
    public func removeAccount(completion: @escaping (Result<Void, AccountManagerError>) -> Void) {
        accountService.removeAccount(accountID: accountID) { [weak self] error in
            if let _ = error {
                completion(.failure(.remove(value: .cantRemove)))
                return
            }
            self?.quickAccessManager.profileRemoved = true
            self?.signOut()
            completion(.success(()))
        }
    }
    
    public func recoverAccount(completion: @escaping (Result<Void, AccountManagerError>) -> Void) {
        accountService.recoverAccount(accountID: accountID) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success:
                self.accountService.setOnline(accountID: self.accountID)
                self.account?.profile.removed = false
                self.quickAccessManager.profileRemoved = false
                self.cacheService.store(accountModel: currentAccount)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.another(error: error)))
            }
        }
    }
    
    public func editAccount(username: String,
                            info: String,
                            sex: String,
                            country: String,
                            city: String,
                            birthday: String,
                            image: Data?,
                            imageURL: URL?,
                            completion: @escaping (Result<Void, AccountManagerError>) -> Void) {
        if let imageData = image {
            remoteStorageService.uploadProfile(accountID: accountID, image: imageData) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    let edited = ProfileNetworkModel(userName: username,
                                                     imageName: url.absoluteString,
                                                     identifier: self.accountID,
                                                     sex: sex,
                                                     info: info,
                                                     birthDay: birthday,
                                                     country: country,
                                                     city: city)
                    self.accountService.editAccount(accountID: self.accountID,
                                                    profile: edited) { [weak self] result in
                        guard let self = self,
                              let currentAccount = self.account else { return }
                        switch result {
                        case .success:
                            let model = ProfileModel(profile: edited)
                            self.account?.profile = model
                            self.cacheService.store(accountModel: currentAccount)
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(.another(error: error)))
                        }
                    }
                case .failure(let error):
                    completion(.failure(.another(error: error)))
                }
            }
        } else {
            guard let imageURL = imageURL?.absoluteString else {
                completion(.failure(.profile(value: .emptyProfile)))
                return
            }
            let edited = ProfileNetworkModel(userName: username,
                                             imageName: imageURL,
                                             identifier: accountID,
                                             sex: sex,
                                             info: info,
                                             birthDay: birthday,
                                             country: country,
                                             city: city)
            accountService.editAccount(accountID: accountID,
                                       profile: edited) { [weak self] result in
                guard let self = self,
                      let currentAccount = self.account else { return }
                switch result {
                case .success:
                    let model = ProfileModel(profile: edited)
                    self.account?.profile = model
                    self.cacheService.store(accountModel: currentAccount)
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(.another(error: error)))
                }
            }
        }
    }
    
    public func signOut() {
        authService.signOut { [weak self] _ in
            self?.setOffline()
            self?.quickAccessManager.clearAll()
        }
    }
    
    public func setOnline() {
        accountService.setOnline(accountID: accountID)
    }
    
    public func setOffline() {
        accountService.setOffline(accountID: accountID)
    }
}

private extension AccountManager {
    func afterAuthorization(account: AccountModelProtocol,
                                    completion: @escaping (Result<Void, AccountManagerError>) -> ()) {
        self.account = account
        self.cacheService.store(accountModel: account)
        guard !account.profile.removed else {
            self.quickAccessManager.profileRemoved = true
            completion(.failure(.profile(value: .profileRemoved)))
            return
        }
        self.accountService.setOnline(accountID: self.accountID)
        completion(.success(()))
    }
}

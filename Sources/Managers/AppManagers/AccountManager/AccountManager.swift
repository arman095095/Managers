//
//  AuthManager.swift
//
//
//  Created by Арман Чархчян on 13.04.2022.
//

import NetworkServices
import Foundation
import Swinject
import UIKit
import ModelInterfaces

public enum ProfileInfoManagersName: String {
    case auth
    case account
}

public protocol ProfileInfoManagerProtocol: AnyObject {
    func sendProfile(username: String,
                     info: String,
                     sex: String,
                     country: String,
                     city: String,
                     birthday: String,
                     image: Data?,
                     completion: @escaping (Result<AccountModelProtocol, Error>) -> Void)
}

public protocol AccountManagerProtocol: ProfileInfoManagerProtocol {
    func processAccountAfterSuccessAuthorization(account: AccountModelProtocol,
                                                 completion: @escaping (Result<Void, AccountManagerError.Profile>) -> ())
    func processAccountAfterLaunch(completion: @escaping (Result<Void, AccountManagerError.Profile>) -> ())
    func recoverAccount(completion: @escaping (Result<Void, AccountManagerError.Remove>) -> Void)
    func removeAccount(completion: @escaping (Result<Void, AccountManagerError.Remove>) -> Void)
    func setOffline()
    func setOnline()
    func signOut()
}

public enum AccountManagerContext {
    case afterAuthorization(accountID: String, account: AccountModelProtocol)
    case afterLaunch(accountID: String)
}

public final class AccountManager {
    
    private var account: AccountModelProtocol?
    private let accountID: String
    private let authService: AuthServiceProtocol
    private let accountService: AccountServiceProtocol
    private let requestsService: RequestsServiceProtocol
    private let remoteStorageService: RemoteStorageServiceProtocol
    private let profileService: ProfilesServiceProtocol
    private let container: Container
    private let quickAccessManager: QuickAccessManagerProtocol
    private let cacheService: AccountCacheServiceProtocol
    
    public init(accountID: String,
                authService: AuthServiceProtocol,
                accountService: AccountServiceProtocol,
                requestsService: RequestsServiceProtocol,
                remoteStorage: RemoteStorageServiceProtocol,
                quickAccessManager: QuickAccessManagerProtocol,
                profileService: ProfilesServiceProtocol,
                cacheService: AccountCacheServiceProtocol,
                container: Container) {
        self.authService = authService
        self.accountService = accountService
        self.requestsService = requestsService
        self.remoteStorageService = remoteStorage
        self.quickAccessManager = quickAccessManager
        self.profileService = profileService
        self.cacheService = cacheService
        self.accountID = accountID
        self.container = container
        initObservers()
    }
}

extension AccountManager: AccountManagerProtocol {
    
    public func processAccountAfterSuccessAuthorization(account: AccountModelProtocol,
                                                        completion: @escaping (Result<Void, AccountManagerError.Profile>) -> ()) {
        saveAccount(account: account,
                    completion: completion)
    }
    
    public func processAccountAfterLaunch(completion: @escaping (Result<Void, AccountManagerError.Profile>) -> ()) {
        guard let account = cacheService.storedAccount(with: accountID) else {
            getAccount { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let account):
                    self.saveAccount(account: account, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        self.account = account
        self.registerAccount(at: container)
        completion(.success(()))
        getAccount { [weak self] result in
            switch result {
            case .success(let account):
                self?.updateCurrentAccount(with: account)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func removeAccount(completion: @escaping (Result<Void, AccountManagerError.Remove>) -> Void) {
        accountService.removeAccount(accountID: accountID) { [weak self] error in
            if let _ = error {
                completion(.failure(.cantRemove))
                return
            }
            self?.quickAccessManager.profileRemoved = true
            self?.signOut()
            completion(.success(()))
        }
    }
    
    public func recoverAccount(completion: @escaping (Result<Void, AccountManagerError.Remove>) -> Void) {
        accountService.recoverAccount(accountID: accountID) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success:
                self.account?.profile.removed = false
                self.quickAccessManager.profileRemoved = false
                self.cacheService.store(accountModel: currentAccount)
                self.accountService.setOnline(accountID: self.accountID)
                completion(.success(()))
            case .failure:
                completion(.failure(.cantRecover))
            }
        }
    }
    
    public func sendProfile(username: String,
                            info: String,
                            sex: String,
                            country: String,
                            city: String,
                            birthday: String,
                            image: Data?,
                            completion: @escaping (Result<AccountModelProtocol, Error>) -> Void) {
        guard let image = image else {
            guard let imageURL = account?.profile.imageUrl else { return }
            let edited = ProfileNetworkModel(userName: username,
                                             imageName: imageURL,
                                             identifier: self.accountID,
                                             sex: sex,
                                             info: info,
                                             birthDay: birthday,
                                             country: country,
                                             city: city)
            set(edited: edited, completion: completion)
            return
        }
        remoteStorageService.uploadProfile(accountID: accountID, image: image) { [weak self] (result) in
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
                self.set(edited: edited, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func signOut() {
        setOffline()
        quickAccessManager.clearAll()
        authService.signOut { _ in }
    }
    
    @objc public func setOnline() {
        accountService.setOnline(accountID: accountID)
    }
    
    @objc public func setOffline() {
        accountService.setOffline(accountID: accountID)
    }
}

private extension AccountManager {
    
    func getAccount(completion: @escaping (Result<AccountModelProtocol, AccountManagerError.Profile>) -> ()) {
        var profile: ProfileModelProtocol?
        var blockedIDs: [String]?
        var friendIDs: [String]?
        var requestIDs: [String]?
        var waitingsIDs: [String]?
        
        let group = DispatchGroup()
        group.enter()
        profileService.getProfileInfo(userID: accountID) { result in
            defer { group.leave() }
            switch result {
            case .success(let model):
                profile = ProfileModel(profile: model)
            case .failure:
                break
            }
        }
        group.enter()
        accountService.getBlockedIds(accountID: accountID) { result in
            defer { group.leave() }
            switch result {
            case .success(let ids):
                blockedIDs = ids
            case .failure:
                break
            }
        }
        group.enter()
        requestsService.waitingIDs(userID: accountID) { result in
            defer { group.leave() }
            switch result {
            case .success(let ids):
                waitingsIDs = ids
            case .failure:
                break
            }
        }
        group.enter()
        requestsService.requestIDs(userID: accountID) { result in
            defer { group.leave() }
            switch result {
            case .success(let ids):
                requestIDs = ids
            case .failure:
                break
            }
        }
        group.enter()
        requestsService.friendIDs(userID: accountID) { result in
            defer { group.leave() }
            switch result {
            case .success(let ids):
                friendIDs = ids
            case .failure:
                break
            }
        }
        group.notify(queue: .main) {
            guard let profile = profile,
            let blockedIDs = blockedIDs,
            let waitingsIDs = waitingsIDs,
            let requestIDs = requestIDs,
            let friendIDs = friendIDs else {
                completion(.failure(.emptyProfile))
                return
            }
            let account = AccountModel(profile: profile, blockedIDs: Set(blockedIDs), friendIds: Set(friendIDs), waitingsIds: Set(waitingsIDs), requestIds: Set(requestIDs))
            completion(.success(account))
        }
    }
    
    func saveAccount(account: AccountModelProtocol,
                     completion: @escaping (Result<Void, AccountManagerError.Profile>) -> ()) {
        self.cacheService.store(accountModel: account)
        self.account = account
        self.registerAccount(at: container)
        guard !account.profile.removed else {
            self.quickAccessManager.profileRemoved = true
            completion(.failure(.profileRemoved))
            return
        }
        self.accountService.setOnline(accountID: self.accountID)
        completion(.success(()))
    }
    
    func updateCurrentAccount(with account: AccountModelProtocol) {
        self.account?.blockedIds = account.blockedIds
        self.account?.friendIds = account.friendIds
        self.account?.requestIds = account.requestIds
        self.account?.waitingsIds = account.waitingsIds
        self.account?.profile = account.profile
        self.cacheService.store(accountModel: account)
    }
    
    func registerAccount(at container: Container) {
        guard let account = self.account else { return }
        container.register(AccountModelProtocol.self) { _ in
            account
        }.inObjectScope(.weak)
    }
    
    func initObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(setOnline), name: UIScene.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setOffline), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setOffline), name: UIScene.didDisconnectNotification, object: nil)
    }
    
    func set(edited: ProfileNetworkModelProtocol,
             completion: @escaping (Result<AccountModelProtocol, Error>) -> Void) {
        accountService.editAccount(accountID: self.accountID,
                                   profile: edited) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.account else { return }
            switch result {
            case .success:
                let model = ProfileModel(profile: edited)
                self.account?.profile = model
                self.cacheService.store(accountModel: currentAccount)
                completion(.success((currentAccount)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

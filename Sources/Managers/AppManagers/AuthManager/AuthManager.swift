//
//  AuthManager.swift
//  
//
//  Created by Арман Чархчян on 13.04.2022.
//

import NetworkServices
import Foundation

public protocol AuthManagerProtocol: AnyObject {
    var currentAccount: AccountModelProtocol? { get }
    func isProfileBlocked(userID: String) -> Bool
    func register(email: String, password: String, handler: @escaping (Result<Void, Error>) -> Void)
    func createAccount(username: String,
                       info: String,
                       sex: String,
                       country: String,
                       city: String,
                       birthday: String,
                       userImage: Data,
                       completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func login(email: String, password: String, handler: @escaping (Result<Void, AuthManagerError>) -> Void)
    func getAccount(completion: @escaping (Result<AccountModelProtocol, AuthManagerError>) -> ())
    func editAccount(username: String,
                     info: String,
                     sex: String,
                     country: String,
                     city: String,
                     birthday: String,
                     image: Data?,
                     imageURL: URL?,
                     completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func recoverAccount(completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func removeAccount(completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], AuthManagerError>) -> Void)
    func blockProfile(_ id: String,
                      completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func unblockProfile(_ id: String,
                        completion: @escaping (Result<Void, AuthManagerError>) -> Void)
    func setOffline()
    func setOnline()
    func signOut()
}

public final class AuthManager {
    
    private var accountID: String?
    public private(set) var currentAccount: AccountModelProtocol?
    private var savedAccount: Account?

    private let authService: AuthServiceProtocol
    private let accountService: AccountServiceProtocol
    private let remoteStorageService: RemoteStorageServiceProtocol
    private let profileService: ProfilesServiceProtocol

    private let quickAccessManager: QuickAccessManagerProtocol
    private let cacheService: AccountCacheServiceProtocol
    
    public init(authService: AuthServiceProtocol,
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
        self.accountID = quickAccessManager.userID
        self.savedAccount = cacheService.getAccount(with: accountID)
    }
}

extension AuthManager: AuthManagerProtocol {
    
    public func getAccount(completion: @escaping (Result<AccountModelProtocol, AuthManagerError>) -> ()) {
        guard let accountID = quickAccessManager.userID else {
            completion(.failure(.profile(value: .emptyProfile)))
            return
        }
        self.accountID = accountID
        profileService.getProfileInfo(userID: accountID, completion: { [weak self] result in
            switch result {
            case .success(let user):
                self?.accountService.getBlockedIds(accountID: accountID) { result in
                    switch result {
                    case .success(let ids):
                        let profile = ProfileModel(profile: user)
                        let account = AccountModel(profile: profile,
                                                   blockedIDs: Set(ids))
                        self?.currentAccount = account
                        guard !profile.removed else {
                            completion(.failure(.profile(value: .profileRemoved)))
                            return
                        }
                        self?.quickAccessManager.userID = accountID
                        self?.accountService.setOnline(accountID: accountID)
                        self?.savedAccount = self?.cacheService.store(accountModel: account)
                        completion(.success((account)))
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
        })
    }
    
    public func isProfileBlocked(userID: String) -> Bool {
        guard let currentAccount = currentAccount else { return false }
        return currentAccount.blockedIds.contains(userID)
    }
    
    public func blockedProfiles(completion: @escaping (Result<[ProfileModelProtocol], AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        accountService.getBlockedIds(accountID: accountID) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.currentAccount else { return }
            switch result {
            case .success(let ids):
                currentAccount.blockedIds = Set(ids)
                self.savedAccount = self.cacheService.store(accountModel: currentAccount)
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
                             completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        accountService.blockUser(accountID: accountID,
                                 userID: id) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.currentAccount else { return }
            switch result {
            case .success:
                currentAccount.blockedIds.insert(id)
                self.savedAccount = self.cacheService.store(accountModel: currentAccount)
                completion(.success(()))
            case .failure:
                completion(.failure(.blocking(value: .cantBlock)))
            }
        }
    }
    
    public func unblockProfile(_ id: String,
                               completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        accountService.unblockUser(accountID: accountID,
                                   userID: id) { [weak self] result in
            guard let self = self,
                  let currentAccount = self.currentAccount else { return }
            switch result {
            case .success:
                guard let firstIndex = currentAccount.blockedIds.firstIndex(of: id) else { return }
                currentAccount.blockedIds.remove(at: firstIndex)
                self.savedAccount = self.cacheService.store(accountModel: currentAccount)
                completion(.success(()))
            case .failure:
                completion(.failure(.blocking(value: .cantUnblock)))
            }
        }
    }
    
    public func register(email: String,
                         password: String,
                         handler: @escaping (Result<Void, Error>) -> Void) {
        authService.register(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let userID):
                self?.accountID = userID
                handler(.success(()))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
    
    public func createAccount(username: String,
                              info: String,
                              sex: String,
                              country: String,
                              city: String,
                              birthday: String,
                              userImage: Data,
                              completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        remoteStorageService.uploadProfile(accountID: accountID, image: userImage) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                let muser = ProfileNetworkModel(userName: username,
                                                imageName: url.absoluteString,
                                                identifier: accountID,
                                                sex: sex,
                                                info: info,
                                                birthDay: birthday,
                                                country: country,
                                                city: city)
                self.accountService.createAccount(accountID: accountID,
                                                  profile: muser) { [weak self] result in
                    switch result {
                    case .success:
                        let profile = ProfileModel(profile: muser)
                        let account = AccountModel(profile: profile,
                                                   blockedIDs: [])
                        self?.accountService.setOnline(accountID: accountID)
                        self?.quickAccessManager.userID = accountID
                        self?.savedAccount = self?.cacheService.store(accountModel: account)
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(.another(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(.another(error: error)))
            }
        }
    }
    
    public func login(email: String, password: String, handler: @escaping (Result<Void, AuthManagerError>) -> Void) {
        authService.login(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let userID):
                self?.accountID = userID
                self?.profileService.getProfileInfo(userID: userID, completion: { result in
                    switch result {
                    case .success(let user):
                        self?.accountService.getBlockedIds(accountID: userID) { result in
                            switch result {
                            case .success(let ids):
                                let profile = ProfileModel(profile: user)
                                let account = AccountModel(profile: profile,
                                                           blockedIDs: Set(ids))
                                self?.currentAccount = account
                                guard !profile.removed else {
                                    handler(.failure(.profile(value: .profileRemoved)))
                                    return
                                }
                                self?.quickAccessManager.userID = userID
                                self?.accountService.setOnline(accountID: userID)
                                self?.savedAccount = self?.cacheService.store(accountModel: account)
                                handler(.success(()))
                            case .failure(let error):
                                handler(.failure(.another(error: error)))
                            }
                        }
                    case .failure(let error):
                        guard case .getData = error as? GetUserInfoError else {
                            handler(.failure(.another(error: error)))
                            return
                        }
                        handler(.failure(.profile(value: .emptyProfile)))
                    }
                })
            case .failure(let error):
                handler(.failure(.another(error: error)))
            }
        }
    }
    
    public func removeAccount(completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        accountService.removeAccount(accountID: accountID) { [weak self] error in
            if let _ = error {
                completion(.failure(.remove(value: .cantRemove)))
                return
            }
            self?.signOut()
            completion(.success(()))
        }
    }
    
    public func recoverAccount(completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID,
              let currentAccount = currentAccount else { return }
        accountService.recoverAccount(accountID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.quickAccessManager.userID = accountID
                self.accountService.setOnline(accountID: accountID)
                currentAccount.profile.removed = false
                self.savedAccount = self.cacheService.store(accountModel: currentAccount)
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
                            completion: @escaping (Result<Void, AuthManagerError>) -> Void) {
        guard let accountID = accountID else { return }
        if let imageData = image {
            remoteStorageService.uploadProfile(accountID: accountID, image: imageData) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    let edited = ProfileNetworkModel(userName: username,
                                                     imageName: url.absoluteString,
                                                     identifier: accountID,
                                                     sex: sex,
                                                     info: info,
                                                     birthDay: birthday,
                                                     country: country,
                                                     city: city)
                    self.accountService.editAccount(accountID: accountID,
                                                    profile: edited) { [weak self] result in
                        guard let self = self,
                              let currentAccount = self.currentAccount else { return }
                        switch result {
                        case .success:
                            let model = ProfileModel(profile: edited)
                            self.currentAccount?.profile = model
                            self.savedAccount = self.cacheService.store(accountModel: currentAccount)
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
                      let currentAccount = self.currentAccount else { return }
                switch result {
                case .success:
                    let model = ProfileModel(profile: edited)
                    self.currentAccount?.profile = model
                    self.savedAccount = self.cacheService.store(accountModel: currentAccount)
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
            self?.accountID = nil
            self?.currentAccount = nil
        }
    }
    
    public func setOnline() {
        guard let accountID = accountID else { return }
        accountService.setOnline(accountID: accountID)
    }
    
    public func setOffline() {
        guard let accountID = accountID else { return }
        accountService.setOffline(accountID: accountID)
    }
}

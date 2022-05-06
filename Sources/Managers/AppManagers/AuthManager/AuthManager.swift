//
//  AuthManager.swift
//  
//
//  Created by Арман Чархчян on 13.04.2022.
//

import NetworkServices
import Foundation
import ModelInterfaces

public protocol AuthManagerProtocol: ProfileInfoManagerProtocol {
    func register(email: String,
                  password: String,
                  handler: @escaping (Result<Void, Error>) -> Void)
    func login(email: String,
               password: String,
               handler: @escaping (Result<AccountModelProtocol, AuthManagerError>) -> Void)
}

public final class AuthManager {
    
    private var accountID: String?
    private let authService: AuthServiceProtocol
    private let accountService: AccountServiceProtocol
    private let remoteStorageService: RemoteStorageServiceProtocol
    private let profileService: ProfilesServiceProtocol
    private let requestsService: RequestsServiceProtocol
    private let quickAccessManager: QuickAccessManagerProtocol
    
    public init(authService: AuthServiceProtocol,
                accountService: AccountServiceProtocol,
                remoteStorage: RemoteStorageServiceProtocol,
                quickAccessManager: QuickAccessManagerProtocol,
                profileService: ProfilesServiceProtocol,
                requestsService: RequestsServiceProtocol) {
        self.authService = authService
        self.accountService = accountService
        self.remoteStorageService = remoteStorage
        self.quickAccessManager = quickAccessManager
        self.profileService = profileService
        self.accountID = quickAccessManager.userID
        self.requestsService = requestsService
    }
}

extension AuthManager: AuthManagerProtocol {
    
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
    
    public func sendProfile(username: String,
                            info: String,
                            sex: String,
                            country: String,
                            city: String,
                            birthday: String,
                            image: Data?,
                            completion: @escaping (Result<AccountModelProtocol, Error>) -> Void) {
        guard let accountID = accountID,
              let image = image else { return }
        remoteStorageService.uploadProfile(accountID: accountID, image: image) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                let profileModel = ProfileNetworkModel(userName: username,
                                                imageName: url.absoluteString,
                                                identifier: accountID,
                                                sex: sex,
                                                info: info,
                                                birthDay: birthday,
                                                country: country,
                                                city: city)
                self.accountService.createAccount(accountID: accountID,
                                                  profile: profileModel) { [weak self] result in
                    switch result {
                    case .success:
                        let profile = ProfileModel(profile: profileModel)
                        let account = AccountModel(profile: profile,
                                                   blockedIDs: [],
                                                   friendIds: [],
                                                   waitingsIds: [],
                                                   requestIds: [])
                        self?.quickAccessManager.userID = accountID
                        completion(.success((account)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func login(email: String, password: String, handler: @escaping (Result<AccountModelProtocol, AuthManagerError>) -> Void) {
        var profile: ProfileModelProtocol?
        var blockedIDs: [String]?
        var friendIDs: [String]?
        var requestIDs: [String]?
        var waitingsIDs: [String]?
        
        let group = DispatchGroup()
        group.enter()
        authService.login(email: email, password: password) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let id):
                self?.accountID = id
            case .failure(let error):
                handler(.failure(.another(error: error)))
            }
        }
        group.wait()
        guard let accountID = accountID else { return }
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
                handler(.failure(.profile(value: .emptyProfile)))
                return
            }
            let account = AccountModel(profile: profile, blockedIDs: Set(blockedIDs), friendIds: Set(friendIDs), waitingsIds: Set(waitingsIDs), requestIds: Set(requestIDs))
            self.quickAccessManager.userID = accountID
            handler(.success(account))
        }
    }
}


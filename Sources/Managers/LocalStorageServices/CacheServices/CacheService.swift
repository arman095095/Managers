//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation
import CoreData
import ModelInterfaces

public protocol AccountCacheServiceProtocol {
    var storedAccount: AccountModelProtocol? { get }
    func store(accountModel: AccountModelProtocol)
}

public protocol ChatsCacheServiceProtocol {
    var storedChats: [ChatModelProtocol]? { get }
}

public protocol RequestsCacheServiceProtocol {
    var storedRequests: [RequestModelProtocol]? { get }
}

public final class CacheService {

    private let coreDataService: CoreDataServiceProtocol
    private let accountID: String
    
    public init(coreDataService: CoreDataServiceProtocol,
                accountID: String) {
        self.coreDataService = coreDataService
        self.accountID = accountID
    }
}

extension CacheService: AccountCacheServiceProtocol {
    public var storedAccount: AccountModelProtocol? {
        guard let account = object(with: accountID) else { return nil }
        return AccountModel(account: account)
    }
    
    public func store(accountModel: AccountModelProtocol) {
        let accountID = accountModel.profile.id
        if let account = object(with: accountID) {
            update(account: account, model: accountModel)
            return
        }
        create(accountModel: accountModel)
    }
}

extension CacheService: ChatsCacheServiceProtocol {
    public var storedChats: [ChatModelProtocol]? {
        guard let storedAccount = object(with: accountID),
              let storedChats = storedAccount.chats else { return nil }
        return storedChats.compactMap { ChatModel(chat: $0 as? Chat) }
    }
}

private extension CacheService {
    
    func object(with id: String) -> Account? {
        coreDataService.model(Account.self, id: id)
    }
    
    func fillFields(profile: Profile,
                    model: ProfileModelProtocol) {
        profile.userName = model.userName
        profile.info = model.info
        profile.sex = model.sex
        profile.imageUrl = model.imageUrl
        profile.id = model.id
        profile.country = model.country
        profile.city = model.city
        profile.birthday = model.birthday
        profile.removed = model.removed
        profile.online = model.online
        profile.lastActivity = model.lastActivity
        profile.postsCount = Int16(model.postsCount)
    }
    
    func fillFields(account: Account,
                    model: AccountModelProtocol) {
        account.blockedIDs = model.blockedIds
        account.requestIDs = model.requestIds
        account.waitingsIDs = model.waitingsIds
        account.friendIDs = model.friendIds
        account.id = model.profile.id
    }
    
    func create(accountModel: AccountModelProtocol) {
        coreDataService.initModel(Account.self) { account in
            fillFields(account: account,
                       model: accountModel)
            account.profile = coreDataService.initModel(Profile.self, initHandler: { profile in
                fillFields(profile: profile,
                           model: accountModel.profile)
            })
        }
    }
    
    func update(account: Account, model: AccountModelProtocol) {
        
        coreDataService.update(account) { account in
            fillFields(account: account, model: model)
        }
        guard let profile = account.profile else {
            coreDataService.initModel(Profile.self) { profile in
                fillFields(profile: profile,
                           model: model.profile)
            }
            return
        }
        coreDataService.update(profile) { profile in
            fillFields(profile: profile,
                       model: model.profile)
        }
    }
}

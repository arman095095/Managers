//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation
import CoreData

public protocol AccountCacheServiceProtocol {
    func store(accountModel: AccountModelProtocol)
    func storedAccount(with id: String) -> AccountModelProtocol?
}

public final class AccountCacheService {

    private let coreDataService: CoreDataServiceProtocol
    
    public init(coreDataService: CoreDataServiceProtocol) {
        self.coreDataService = coreDataService
    }
}

extension AccountCacheService: AccountCacheServiceProtocol {
    
    public func storedAccount(with id: String) -> AccountModelProtocol? {
        guard let account = object(with: id) else { return nil }
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

private extension AccountCacheService {
    
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

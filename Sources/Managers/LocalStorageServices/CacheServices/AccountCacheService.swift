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
    private let quickAccessManager: QuickAccessManagerProtocol
    
    public init(coreDataService: CoreDataServiceProtocol,
                quickAccessManager: QuickAccessManagerProtocol) {
        self.coreDataService = coreDataService
        self.quickAccessManager = quickAccessManager
        
    }
}

extension AccountCacheService: AccountCacheServiceProtocol {
    
    public func storedAccount(with id: String) -> AccountModelProtocol? {
        if let objectID = quickAccessManager.accounts[id] {
            guard let account = coreDataService.getObject(type: Account.self,
                                                  id: objectID) else { return nil }
            return AccountModel(account: account)
        }
        guard let account = object(with: id) else { return nil }
        return AccountModel(account: account)
    }
    
    public func store(accountModel: AccountModelProtocol) {
        let accountID = accountModel.profile.id
        if let account = object(with: accountID) {
            update(account: account, model: accountModel)
            return
        }
        var accountObject: Account?
        coreDataService.create(type: Account.self) { account in
            account.id = accountModel.profile.id
            account.blockedIDs = accountModel.blockedIds
            account.profile = self.create(profileModel: accountModel.profile)
            accountObject = account
        }
        if let accountObject = accountObject {
            var accounts = quickAccessManager.accounts
            accounts[accountID] = accountObject.objectID
            quickAccessManager.accounts = accounts
        }
    }
}

private extension AccountCacheService {
    
    func object(with id: String) -> Account? {
        coreDataService.getObject(type: Account.self,
                          predicate: NSPredicate(format: "SELF.id == %@", "\(id)"))
    }
    
    func objectID(with id: String) -> NSManagedObjectID? {
        object(with: id)?.objectID
    }
    
    func update(account: Account, model: AccountModelProtocol) {
        guard let profile = account.profile else { return }
        account.id = profile.id
        account.blockedIDs = model.blockedIds
        profile.userName = model.profile.userName
        profile.info = model.profile.info
        profile.sex = model.profile.sex
        profile.imageUrl = model.profile.imageUrl
        profile.id = model.profile.id
        profile.country = model.profile.country
        profile.city = model.profile.city
        profile.birthday = model.profile.birthday
        profile.removed = model.profile.removed
        profile.online = model.profile.online
        profile.lastActivity = model.profile.lastActivity
        profile.postsCount = Int16(model.profile.postsCount)
        coreDataService.saveContext()
    }

    func create(profileModel: ProfileModelProtocol) -> Profile? {
        var profileResult: Profile?
        coreDataService.create(type: Profile.self) { profile in
            profile.userName = profileModel.userName
            profile.info = profileModel.info
            profile.sex = profileModel.sex
            profile.imageUrl = profileModel.imageUrl
            profile.id = profileModel.id
            profile.country = profileModel.country
            profile.city = profileModel.city
            profile.birthday = profileModel.birthday
            profile.removed = profileModel.removed
            profile.online = profileModel.online
            profile.lastActivity = profileModel.lastActivity
            profile.postsCount = Int16(profileModel.postsCount)
            profileResult = profile
        }
        return profileResult
    }
}

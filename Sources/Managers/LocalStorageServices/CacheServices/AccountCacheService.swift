//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation
import CoreData

public protocol AccountCacheServiceProtocol {
    @discardableResult
    func store(accountModel: AccountModelProtocol) -> Account?
    func getAccount(with id: String?) -> Account?
}

public final class AccountCacheService {

    private let service: CoreDataServiceProtocol
    
    public init(service: CoreDataServiceProtocol) {
        self.service = service
    }
}

extension AccountCacheService: AccountCacheServiceProtocol {

    public func getAccount(with id: String?) -> Account? {
        guard let accountID = id else { return nil }
        return service.getObject(type: Account.self, predicate: NSPredicate(format: "SELF.id == %@", "\(accountID)"))
    }
    
    @discardableResult
    public func store(accountModel: AccountModelProtocol) -> Account? {
        let accountID = accountModel.profile.id
        
        if let account = getAccount(with: accountID) {
            update(account: account, model: accountModel)
            return account
        }
        var accountResult: Account?
        service.create(type: Account.self) { account in
            account.id = accountModel.profile.id
            account.blockedIDs = accountModel.blockedIds
            account.profile = self.create(profileModel: accountModel.profile)
            accountResult = account
        }
        return accountResult
    }
}

private extension AccountCacheService {
    
    func update(account: Account, model: AccountModelProtocol) {
        guard let profile = account.profile else { return }
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
        service.saveContext()
    }

    func create(profileModel: ProfileModelProtocol) -> Profile? {
        var profileResult: Profile?
        service.create(type: Profile.self) { profile in
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

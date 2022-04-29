//
//  File.swift
//  
//
//  Created by Арман Чархчян on 27.04.2022.
//

import Foundation
import Swinject
import NetworkServices

public enum AccountManagerAssembly {
    public static func assemble(container: Container) {
        CoreDataServiceAssembly.assemble(container: container)
        AccountCacheServiceAssembly.assemble(container: container)
        container.register(AccountManagerProtocol.self) { r in
            guard let authService = r.resolve(AuthServiceProtocol.self),
                  let accountService = r.resolve(AccountServiceProtocol.self),
                  let remoteStorage = r.resolve(RemoteStorageServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self),
                  let cacheService = r.resolve(AccountCacheServiceProtocol.self),
                  let accountID = quickAccessManager.userID else { fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return AccountManager(accountID: accountID,
                                  authService: authService,
                                  accountService: accountService,
                                  remoteStorage: remoteStorage,
                                  quickAccessManager: quickAccessManager,
                                  profileService: profileService,
                                  cacheService: cacheService,
                                  container: container)
        }.inObjectScope(.weak)
    }
}

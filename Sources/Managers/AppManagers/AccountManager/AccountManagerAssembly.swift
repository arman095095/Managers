//
//  File.swift
//  
//
//  Created by Арман Чархчян on 27.04.2022.
//

import Foundation
import Swinject
import NetworkServices
import Services

final class AccountManagerAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(AccountManagerProtocol.self) { r in
            guard let accountService = r.resolve(AccountServiceProtocol.self),
                  let remoteStorage = r.resolve(ProfileRemoteStorageServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self),
                  let accountInfoService = r.resolve(AccountInfoNetworkServiceProtocol.self),
                  let cacheService = r.resolve(AccountCacheServiceProtocol.self),
                  let accountID = quickAccessManager.userID else { fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return AccountManager(accountID: accountID,
                                  accountService: accountService,
                                  accountInfoService: accountInfoService,
                                  remoteStorage: remoteStorage,
                                  quickAccessManager: quickAccessManager,
                                  profileService: profileService,
                                  cacheService: cacheService,
                                  container: container)
        }.inObjectScope(.weak)
    }
}

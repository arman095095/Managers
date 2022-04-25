//
//  File.swift
//  
//
//  Created by Арман Чархчян on 22.04.2022.
//

import Swinject
import Foundation
import NetworkServices

public final class AuthManagerAssembly {
    public static func assemble(container: Container) {
        container.register(AuthManagerProtocol.self) { r in
            guard let authService = r.resolve(AuthServiceProtocol.self),
                  let accountService = r.resolve(AccountServiceProtocol.self),
                  let remoteStorage = r.resolve(RemoteStorageServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self) else { fatalError(ErrorMessage.dependency.localizedDescription) }
            return AuthManager(authService: authService,
                               accountService: accountService,
                               remoteStorage: remoteStorage,
                               quickAccessManager: quickAccessManager,
                               profileService: profileService)
        }.inObjectScope(.weak)
    }
}

enum ErrorMessage: LocalizedError {
    case dependency
}

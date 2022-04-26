//
//  File.swift
//  
//
//  Created by Арман Чархчян on 22.04.2022.
//

import Foundation
import Swinject
import NetworkServices

public final class QuickAccessManagerAssembly {
    public static func assemble(container: Container) {

        container.register(KeychainServiceProtocol.self) { r in
            KeychainService(configuration: KeychainConfiguration(account: "test"))
        }
    
        container.register(UserDefaultsServiceProtocol.self) { r in
            UserDefaultsService()
        }
    
        container.register(QuickAccessManagerProtocol.self) { r in
            guard let userDefaultsService = r.resolve(UserDefaultsServiceProtocol.self),
                  let keychainService = r.resolve(KeychainServiceProtocol.self) else { fatalError() }
            return QuickAccessManager(keychainService: keychainService,
                                      userDefaultsService: userDefaultsService)
        }
    }
}

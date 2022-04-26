//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation
import Swinject

public enum AccountCacheServiceAssembly {
    public static func assemble(container: Container) {
        container.register(AccountCacheServiceProtocol.self) { r in
            guard let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self) else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return AccountCacheService(coreDataService: coreDataService,
                                       quickAccessManager: quickAccessManager)
        }
    }
}

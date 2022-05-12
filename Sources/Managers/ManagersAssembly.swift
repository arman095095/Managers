//
//  File.swift
//  
//
//  Created by Арман Чархчян on 29.04.2022.
//

import Foundation
import Swinject
import Services

public final class ManagersAssembly: Assembly {
    
    public init() { }
    
    public func assemble(container: Container) {
        QuickAccessManagerAssembly().assemble(container: container)
        AccountManagerAssembly().assemble(container: container)
        ProfilesManagerAssembly().assemble(container: container)
        CommunicationManagerAssembly().assemble(container: container)
    }
}

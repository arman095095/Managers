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
        BlockingManagerAssembly().assemble(container: container)
    }
}

enum ErrorMessage: LocalizedError {
    case dependency
}

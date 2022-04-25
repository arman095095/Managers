//
//  File.swift
//  
//
//  Created by Арман Чархчян on 25.04.2022.
//

import Foundation
import Swinject

public enum CoreDataServiceAssembly {
    enum FileNames: String {
        case model = "Model"
    }
    public static func assemble(container: Container) {
        container.register(DatabaseServiceProtocol.self) { r in
            CoreDataService(fileName: FileNames.model.rawValue)
        }
    }
}

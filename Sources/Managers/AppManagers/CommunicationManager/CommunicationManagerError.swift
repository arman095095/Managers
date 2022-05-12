//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import Foundation

public enum BlockingManagerError: LocalizedError {
    
    case cantBlock
    case cantUnblock
    
    public var errorDescription: String? {
        switch self {
        case .cantBlock:
            return "Не удалось заблокировать пользователя"
        case .cantUnblock:
            return "Не удалось разблокировать пользователя"
        }
    }
}

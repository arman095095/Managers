//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import Foundation

public enum CommunicationManagerError: LocalizedError {
    case blocking(value: Block)
    
    public enum Block: LocalizedError {
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
}

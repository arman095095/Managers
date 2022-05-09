//
//  UserDefaultsService.swift
//  
//
//  Created by Арман Чархчян on 09.04.2022.
//

import Foundation

public enum UserDefaultsItem: String, CaseIterable {
    case userRemembered
    case accounts
}

public protocol UserDefaultsServiceProtocol {
    func getData(item: UserDefaultsItem) -> Any?
    func store(_ value: Any, item: UserDefaultsItem)
    func removeItem(_ item: UserDefaultsItem)
    func clear()
}

public final class UserDefaultsService {
    public init() { }
}

extension UserDefaultsService: UserDefaultsServiceProtocol {
    public func getData(item: UserDefaultsItem) -> Any? {
        UserDefaults.standard.value(forKey: item.rawValue)
    }
    
    public func store(_ value: Any, item: UserDefaultsItem) {
        UserDefaults.standard.setValue(value, forKey: item.rawValue)
    }
    
    public func removeItem(_ item: UserDefaultsItem) {
        UserDefaults.standard.removeObject(forKey: item.rawValue)
    }
    
    public func clear() {
        UserDefaultsItem.allCases.forEach { removeItem($0) }
    }
}

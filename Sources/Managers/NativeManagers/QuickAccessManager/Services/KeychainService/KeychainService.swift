//
//  KeychainService.swift
//  
//
//  Created by Арман Чархчян on 09.04.2022.
//

import Foundation

public struct KeychainConfiguration {
    let account: String
    
    public init(account: String) {
        self.account = account
    }
}

public enum KeychainItem: String {
    case userID
}

public protocol KeychainServiceProtocol: AnyObject {
    func removeItem(_ item: KeychainItem)
    func getData(for key: KeychainItem) -> Result<Data, KeychainServiceError>
    @discardableResult
    func store(data: Data, for key: KeychainItem) -> KeychainServiceError?
    @discardableResult
    func clear() -> KeychainServiceError?
}

public final class KeychainService {
    private let account: String
    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
    }

    public init(configuration: KeychainConfiguration) {
        account = configuration.account
    }
}

// MARK: - KeychainService Conformance
extension KeychainService: KeychainServiceProtocol {

    public func removeItem(_ item: KeychainItem) {
        var query = baseQuery
        query[kSecAttrService as String] = item.rawValue
        query[kSecAttrAccount as String] = account
        // remove exiting item
        SecItemDelete(query as CFDictionary)
    }
    
    // swiftlint:disable implicitly_unwrapped_optional
    public func getData(for key: KeychainItem) -> Result<Data, KeychainServiceError> {
        var query = baseQuery
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        query[kSecAttrService as String] = key.rawValue
        query[kSecAttrAccount as String] = account
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return .failure(.itemNotFound)
        }
        guard status == errSecSuccess,
              let existingItem = item?.firstObject as? [String: Any],
              let data = existingItem[kSecValueData as String] as? Data
        else {
            return .failure(.undefined(description: status.toString()))
        }
        return .success(data)
    }

    @discardableResult
    public func store(data: Data, for key: KeychainItem) -> KeychainServiceError? {
        var query = baseQuery
        query[kSecValueData as String] = data as AnyObject
        query[kSecAttrService as String] = key.rawValue
        query[kSecAttrAccount as String] = account
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        // remove exiting item
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            return .undefined(description: status.toString())
        }
        return nil
    }
    
    @discardableResult
    public func clear() -> KeychainServiceError? {
        let query = baseQuery
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound {
            return .itemNotFound
        }
        if status != errSecSuccess {
            return .undefined(description: status.toString())
        }
        return nil
    }
}

extension OSStatus {
    func toString() -> String? {
        if #available(iOS 11.3, *) {
            return SecCopyErrorMessageString(self, nil) as String?
        } else {
            return nil
        }
    }
}

public enum KeychainServiceError: Error {
    case itemNotFound
    case undefined(description: String?)
}

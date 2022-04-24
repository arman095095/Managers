
public protocol QuickAccessManagerProtocol: AnyObject {
    var userRemembered: Bool { get set }
    var userID: String? { get set }
    func clearSecurityStorage()
    func clearUserSettings()
    func clearAll()
}

final public class QuickAccessManager {
    private let keychainService: KeychainServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    
    public init(keychainService: KeychainServiceProtocol,
                userDefaultsService: UserDefaultsServiceProtocol) {
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
    }
}

extension QuickAccessManager: QuickAccessManagerProtocol {
    
    public var userRemembered: Bool {
        get {
            userDefaultsService.getData(item: .userRemembered) as? Bool ?? false
        }
        set {
            userDefaultsService.store(newValue, item: .userRemembered)
        }
    }
    
    public var userID: String? {
        get {
            guard case let .success(data) = keychainService.getData(for: .userID) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            guard let newValue = newValue else {
                keychainService.removeItem(.userID)
                return
            }
            guard let data = newValue.data(using: .utf8) else { return }
            keychainService.store(data: data, for: .userID)
        }
    }
    
    public func clearSecurityStorage() {
        keychainService.clear()
    }
    
    public func clearUserSettings() {
        userDefaultsService.clear()
    }
    
    public func clearAll() {
        keychainService.clear()
        userDefaultsService.clear()
    }
}

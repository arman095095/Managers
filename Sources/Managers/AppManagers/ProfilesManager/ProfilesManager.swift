//
//  File.swift
//  
//
//  Created by Арман Чархчян on 17.04.2022.
//

import Foundation
import NetworkServices

public protocol ProfilesManagerProtocol: AnyObject {
    func getProfile(userID: String, completion: @escaping (Result<ProfileModelProtocol, Error>) -> Void)
    func getFirstProfiles(accountID: String, completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void)
    func getNextProfiles(accountID: String, completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void)
}

public final class ProfilesManager: ProfilesManagerProtocol {
    
    private let profileService: ProfilesServiceProtocol
    
    public init(profileService: ProfilesServiceProtocol) {
        self.profileService = profileService
    }
    
    public func getProfile(userID: String, completion: @escaping (Result<ProfileModelProtocol, Error>) -> Void) {
        profileService.getProfileInfo(userID: userID) { result in
            switch result {
            case .success(let profile):
                let profileModel = ProfileModel(profile: profile)
                completion(.success(profileModel))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getFirstProfiles(accountID: String, completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void) {
        profileService.getFirstProfilesIDs { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                let group = DispatchGroup()
                var profilesIDs = ids
                if let firstIndex = profilesIDs.firstIndex(of: accountID) {
                    profilesIDs.remove(at: firstIndex)
                }
                var profiles = [ProfileModelProtocol]()
                profilesIDs.forEach {
                    group.enter()
                    self.getProfile(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            profiles.append(profile)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(.success(profiles))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getNextProfiles(accountID: String, completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void) {
        profileService.getNextProfilesIDs { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                let group = DispatchGroup()
                var profilesIDs = ids
                if let firstIndex = profilesIDs.firstIndex(of: accountID) {
                    profilesIDs.remove(at: firstIndex)
                }
                var profiles = [ProfileModelProtocol]()
                profilesIDs.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let profileModel = ProfileModel(profile: profile)
                            profiles.append(profileModel)
                        case .failure:
                            break
                        }
                    }
                    group.notify(queue: .main) {
                        completion(.success(profiles))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

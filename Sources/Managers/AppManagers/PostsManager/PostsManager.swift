//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 02.05.2022.
//

import Foundation
import NetworkServices
import UIKit

public protocol PostsManagerProtocol: AnyObject {
    func create(image: UIImage?,
                imageSize: CGSize?,
                content: String,
                completion: @escaping (Result<Void, Error>) -> Void)
    func getAllFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getAllNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getFirstPosts(for userID: String,
                       completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getNextPosts(for userID: String,
                      completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getCurrentUserFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getCurrentUserNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func removePost(post: PostModelProtocol)
    func like(post: PostModelProtocol)
    func unlike(post: PostModelProtocol)
}

public final class PostsManager {
    
    private let postsService: PostsServiceProtocol
    private let remoteStorage: RemoteStorageServiceProtocol
    private let profilesService: ProfilesServiceProtocol
    private let accountID: String
    
    init(accountID: String,
         postsService: PostsServiceProtocol,
         remoteStorage: RemoteStorageServiceProtocol,
         profilesService: ProfilesServiceProtocol) {
        self.accountID = accountID
        self.postsService = postsService
        self.remoteStorage = remoteStorage
        self.profilesService = profilesService
    }
}

extension PostsManager: PostsManagerProtocol {
    public func create(image: UIImage?,
                       imageSize: CGSize?,
                       content: String,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        if let data = image?.jpegData(compressionQuality: 0.4),
           let size = imageSize {
            remoteStorage.uploadPost(image: data) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    let postNetworkModel = PostNetworkModel(userID: self.accountID,
                                                            textContent: content,
                                                            urlImage: url,
                                                            imageHeight: size.height,
                                                            imageWidth: size.width)
                    self.postsService.createPost(accountID: self.accountID,
                                                 post: postNetworkModel) { result in
                        switch result {
                        case .success():
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let postNetworkModel = PostNetworkModel(userID: accountID,
                                                    textContent: content,
                                                    urlImage: nil,
                                                    imageHeight: nil,
                                                    imageWidth: nil)
            postsService.createPost(accountID: accountID, post: postNetworkModel) { result in
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func getAllFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        postsService.getAllFirstPosts { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let models):
                self.handle(models: models, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getAllNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        postsService.getAllNextPosts { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let models):
                self.handle(models: models, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getFirstPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        self.profilesService.getProfileInfo(userID: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard !profile.removed else {
                    completion(.success([]))
                    return
                }
                self.postsService.getUserFirstPosts(userID: userID) { result in
                    switch result {
                    case .success(let models):
                        let posts = models.map { PostModel(model: $0, owner: profile) }
                        completion(.success(posts))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getNextPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        self.profilesService.getProfileInfo(userID: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard !profile.removed else {
                    completion(.success([]))
                    return
                }
                self.postsService.getUserNextPosts(userID: userID) { result in
                    switch result {
                    case .success(let models):
                        let posts = models.map { PostModel(model: $0, owner: profile) }
                        completion(.success(posts))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getCurrentUserFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        getFirstPosts(for: accountID, completion: completion)
    }
    
    public func getCurrentUserNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        getNextPosts(for: accountID, completion: completion)
    }
    
    public func removePost(post: PostModelProtocol) {
        postsService.deletePost(accountID: accountID, postID: post.id)
    }
    
    public func like(post: PostModelProtocol) {
        let model = PostNetworkModel(userID: post.userID,
                                     textContent: post.textContent,
                                     urlImage: post.urlImage,
                                     imageHeight: post.imageHeight,
                                     imageWidth: post.imageWidth)
        postsService.likePost(accountID: accountID, post: model)
    }
    
    public func unlike(post: PostModelProtocol) {
        let model = PostNetworkModel(userID: post.userID,
                                     textContent: post.textContent,
                                     urlImage: post.urlImage,
                                     imageHeight: post.imageHeight,
                                     imageWidth: post.imageWidth)
        postsService.unlikePost(accountID: accountID, post: model)
    }
    
}

private extension PostsManager {
    func handle(models: [PostNetworkModelProtocol],
                completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        let group = DispatchGroup()
        var posts = [PostModelProtocol]()
        var dict = [String: [PostNetworkModelProtocol]]()
        let ownersIDs = Set(models.map { $0.userID })
        for userID in ownersIDs {
            group.enter()
            dict[userID] = models.filter { $0.userID == userID }
            self.profilesService.getProfileInfo(userID: userID) { result in
                defer { group.leave() }
                switch result {
                case .success(let profile):
                    guard let models = dict[userID] else { return }
                    posts = models.compactMap {
                        guard !profile.removed else { return nil }
                        return PostModel(model: $0, owner: profile)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        group.notify(queue: .main) {
            completion(.success(posts))
        }
    }

}


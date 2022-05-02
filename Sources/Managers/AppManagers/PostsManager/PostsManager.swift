//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 02.05.2022.
//

import Foundation
import NetworkServices

public protocol PostsManagerProtocol: AnyObject {
    func create(post: PostModelProtocol, completion: @escaping (Result<Void, Error>) -> Void)
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
    private let accountID: String
    
    init(accountID: String, postsService: PostsServiceProtocol) {
        self.accountID = accountID
        self.postsService = postsService
    }
}

extension PostsManager: PostsManagerProtocol {
    public func create(post: PostModelProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        let requestModel = PostNetworkModelProtocol
        postsService.createPost(post: <#T##PostNetworkModelProtocol#>, completion: <#T##(Result<Void, Error>) -> Void#>)
    }
    
    public func getAllFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func getAllNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func getFirstPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func getNextPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func getCurrentUserFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func getCurrentUserNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        <#code#>
    }
    
    public func removePost(post: PostModelProtocol) {
        <#code#>
    }
    
    public func like(post: PostModelProtocol) {
        <#code#>
    }
    
    public func unlike(post: PostModelProtocol) {
        <#code#>
    }
    
    
}

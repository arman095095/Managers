//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices
import Services

public final class ChatModel: ChatModelProtocol {
    public var friend: ProfileModelProtocol
    public var friendID: String
    
    public init(friend: ProfileNetworkModelProtocol) {
        self.friend = ProfileModel(profile: friend)
        self.friendID = friend.id
    }
    
    public init(friend: ProfileModelProtocol) {
        self.friend = friend
        self.friendID = friend.id
    }
    
    public init?(chat: Chat?) {
        guard let chat = chat,
              let friendID = chat.friendID,
              let friend = chat.friend,
              let profile = ProfileModel(profile: friend) else { return nil }
        self.friendID = friendID
        self.friend = profile
    }
}

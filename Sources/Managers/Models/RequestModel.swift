//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices


public final class RequestModel: RequestModelProtocol {
    public var sender: ProfileModelProtocol
    public var senderID: String
    
    public init(sender: ProfileNetworkModelProtocol) {
        self.sender = ProfileModel(profile: sender)
        self.senderID = sender.id
    }
    
    public init?(request: Request?) {
        guard let request = request,
              let senderID = request.senderID,
              let sender = request.sender,
              let profile = ProfileModel(profile: sender) else { return nil }
        self.senderID = senderID
        self.sender = profile
    }
}

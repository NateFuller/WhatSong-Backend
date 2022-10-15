//
//  UserResponse.swift
//  
//
//  Created by Nathan Fuller on 10/14/22.
//

import Foundation
import Vapor

struct UserResponse {
    struct Basic: Content {
        var createdAt: Date?
        var id: UUID?
        var username: String?
        
        init(user: User) {
            self.createdAt = user.createdAt
            self.id = user.id
            self.username = user.username
        }
    }
    
    struct UsernameUpdated: Content {
        var id: UUID?
        var username: String?
        var usernameLastModifiedAt: Date?
        
        init(user: User) {
            self.id = user.id
            self.username = user.username
            self.usernameLastModifiedAt = user.usernameLastModified
        }
    }
}

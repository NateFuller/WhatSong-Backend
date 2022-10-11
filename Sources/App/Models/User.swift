//
//  User.swift
//  
//
//  Created by Nathan Fuller on 9/22/22.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?
    
    @OptionalField(key: "profileImageURL")
    var profileImageURL: String?

    @OptionalField(key: "username")
    var username: String?
    
    @Field(key: "email")
    var email: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    // MARK: - Relations
    
    @Children(for: \.$user)
    var posts: [Post]
    
    @Children(for: \.$user)
    var comments: [Comment]
    
    @Siblings(through: CommentLike.self, from: \.$user, to: \.$comment)
    public var likedComments: [Comment]
    
    // TODO: FollowedUsers
    
    // MARK: - Initializers

    init() { }

    init(id: UUID? = nil,
         createdAt: Date? = nil,
         email: String,
         profileImageURL: String? = nil,
         username: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.email = email
        self.profileImageURL = profileImageURL
        self.username = username
    }
}

extension User {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("createdAt", .datetime)
                .field("email", .string, .required)
                .field("profileImageURL", .string)
                .field("username", .string)
                .field("comments", .array(of: .uuid))
                .field("posts", .array(of: .uuid))
                .field("likedComments", .array(of: .uuid))
                .unique(on: "username")
                .unique(on: "email")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}

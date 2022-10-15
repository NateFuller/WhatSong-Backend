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
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Field(key: "email")
    var email: String

    @Field(key: "password")
    var password: String
    
    @OptionalField(key: "profileImageURL")
    var profileImageURL: String?
    
    @OptionalField(key: "username")
    var username: String?
    
    @OptionalField(key: "usernameLastModified")
    var usernameLastModified: Date?
    
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
         password: String,
         profileImageURL: String? = nil,
         username: String? = nil,
         usernameLastModified: Date? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.email = email
        self.password = password
        self.profileImageURL = profileImageURL
        self.username = username
        self.usernameLastModified = usernameLastModified
    }
}

extension User {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("comments", .array(of: .uuid))
                .field("createdAt", .datetime)
                .field("email", .string, .required)
                .field("likedComments", .array(of: .uuid))
                .field("password", .string)
                .field("posts", .array(of: .uuid))
                .field("profileImageURL", .string)
                .field("username", .string)
                .field("usernameLastModified", .datetime)
                .unique(on: "username")
                .unique(on: "email")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        guard let wrapped = wrapped else {
            return true
        }
        
        return wrapped.isEmpty
    }
}

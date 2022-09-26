//
//  Post.swift
//  
//
//  Created by Nathan Fuller on 9/25/22.
//

import Fluent
import Vapor

final class Post: Model, Content {
    static let schema = "posts"
    
    // MARK: - Fields
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalField(key: "contentURL")
    var contentURL: String?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    // TODO PostLike (just like CommentLike)
    
    // MARK: - Relations
    
    @Parent(key: "userID")
    var user: User
    
    @Children(for: \.$post)
    var comments: [Comment]
    
    init() { }
    
    init(id: UUID? = nil, userID: User.IDValue, contenURL: String?, createdAt: Date?) {
        self.id = id
        self.$user.id = userID
        self.createdAt = createdAt
    }
}

extension Post {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Post.schema)
                .id()
                .field("contentURL", .string)
                .field("createdAt", .datetime)
                .field("userID", .uuid, .required, .references(User.schema, "id"))
                .field("comments", .array(of: .uuid))
                .create()
        }
        
        func revert(on database: FluentKit.Database) async throws {
            try await database.schema(Post.schema).delete()
        }
    }
}

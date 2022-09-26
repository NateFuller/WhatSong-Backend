//
//  Comment.swift
//  
//
//  Created by Nathan Fuller on 9/22/22.
//

import Fluent
import Vapor

final class Comment: Model, Content {
    static let schema = "comments"
    
    // MARK: - Fields
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    // MARK: - Relations
    
    @Parent(key: "userID")
    var user: User
    
    @Parent(key: "postID")
    var post: Post
    
    @Siblings(through: CommentLike.self, from: \.$comment, to: \.$user)
    var likes: [User]
    
    // MARK: - Initializers
    
    init() { }
    
    init(id: UUID? = nil, userID: User.IDValue, content: String, createdAt: Date?) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

extension Comment {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("comments")
                .id()
                .field("content", .string)
                .field("createdAt", .datetime)
                .field("userID", .uuid, .required, .references("users", "id"))
                .field("postID", .uuid, .required, .references("posts", "id"))
                .field("likes", .array(of: .uuid))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("comments").delete()
        }
    }
}

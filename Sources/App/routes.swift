import FluentSQL
import Vapor

func routes(_ app: Application) throws {
    // MARK: - Comment
    
    // MARK: GET /comments
    
    app.get("comments") { req async throws in
        try await Comment.query(on: req.db).all()
    }
    
    // MARK: POST /comment
    
    app.group(NewCommentMiddleware()) {
        $0.post("comment") { req async throws -> Comment in
            let comment = try req.content.decode(Comment.self)
            try await comment.create(on: req.db)
            return comment
        }
    }
    
    // MARK: DELETE /comments (Dev)
    
    app.delete("comments") { req async throws -> String in
        guard app.environment == .development else {
            throw Abort(.notFound)
        }
        
        if let sql = req.db as? SQLDatabase {
            try sql.delete(from: "comments")
                .run().wait()
            
            return "⚠️ Deleted all comments! ⚠️"
        } else {
            throw Abort(.internalServerError)
        }
    }
    
    // MARK: - User
    
    // MARK: POST /user/create
    
    app.group(NewUserMiddleware()) {
        $0.post("user", "create") { req async throws -> User in
            let user = try req.content.decode(User.self)
            
            guard try await User.query(on: req.db).filter(\.$email == user.email).first() == nil else {
                throw Abort(.notFound, reason: "An account with that email address already exists.")
            }
            
            try await user.create(on: req.db)
            return user
        }
    }
    
    // MARK: GET /user/:username
    
    app.get("user", ":username") { req async throws -> User in
        let username = req.parameters.get("username")!
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user
    }
    
    // MARK: GET /user/:id
    
    app.get("user", "id", ":id") { req async throws -> User in
        let idString = req.parameters.get("id")!
        guard let userUUID = UUID(uuidString: idString) else {
            throw Abort(.notFound)
        }
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userUUID)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user
    }
    
    // MARK: GET /user/id/:id/posts
    
    app.get("user", "id", ":id", "posts") { req async throws -> [Post] in
        let idString = req.parameters.get("id")!
        guard let userUUID = UUID(uuidString: idString) else {
            throw Abort(.notFound)
        }
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userUUID)
            .with(\.$posts)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user.posts
    }
    
    // TODO: POST /user
    /// Update user with ID to
    
    // TODO: PUT /user/:username
    
    // MARK: - Post
    
    // MARK: POST /post/create
    
    app.post("post", "create") { req async throws -> Post in
        let post = try req.content.decode(Post.self)
        try await post.create(on: req.db)
        
        return post
    }
}



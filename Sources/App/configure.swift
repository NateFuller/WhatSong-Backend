import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
//    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite) // use file for db
    app.databases.use(.sqlite(.memory), as: .sqlite) // use memory for db
    
    app.migrations.add(User.Migration())
    app.migrations.add(Comment.Migration())
    app.migrations.add(CommentLike.Migration())
    app.migrations.add(Post.Migration())
    try await app.autoMigrate() // when using memory for db

    // register routes
    try routes(app)
}

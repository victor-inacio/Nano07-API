import Vapor
import Fluent
import FluentMySQLDriver
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    
    //Checks enviroment to log on different DBs
    if (app.environment == .testing) {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    } else {
        app.databases.use(.mysql(
            hostname: "localhost",
            username: "root",
            password: "mysqlPW",
            database: "bookDB",
            tlsConfiguration: tls
        ),as: .mysql)
    }
    
    //Add migrations to the application
    app.migrations.add(CreateUser())
    app.migrations.add(CreateBook())
    
    //Runs the migrate function
    try app.autoMigrate().wait()
    
    
    //Register routes
    try routes(app)
}

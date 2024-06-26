@testable import App
import XCTVapor



final class AppTests: XCTestCase {
    var app: Application!
    
    override func setUpWithError() throws {
        self.app = Application(.testing)
        
        try configure(app)
        
        try self.app.autoRevert().wait()
        try? self.app.autoMigrate().wait()
    }
    
    override func tearDownWithError() throws {
        
        
        self.app.shutdown()
        self.app = nil
    }
    
    func testFailsWhenNotAuthenticated() throws {
        
        struct ProtecRoute {
            let route: String
            let method: HTTPMethod
        }
        
        let protectedRoutes: [ProtecRoute] = [
            .init(route: "books", method: .GET),
            .init(route: "books/123", method: .GET),
            .init(route: "books", method: .POST),
            .init(route: "books/123", method: .PUT),
            .init(route: "books/123", method: .DELETE)
        ]
        
        for route in protectedRoutes {
            try app.test(route.method, route.route) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
        }
        
    }
    
    //Test index endpoint funcrion
    func testIndexEndpoint() throws {
        let book: Book = .init(name: "Foo_Book", author: "Foo_Author")
        
        try book.save(on: app.db).wait()
        
        try app.test(.GET, "/books", beforeRequest: {
            req in
            
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            
        }) { res in
            XCTAssertEqual(res.status, .ok)
            
            
            
            let returned_books = try res.content.decode([Book].self)
            let retBook = returned_books[0]
            
            XCTAssertEqual(returned_books.count, 1)
            
            XCTAssertNotNil(retBook.id)
            XCTAssertEqual("Foo_Book", retBook.name)
            XCTAssertEqual("Foo_Author", retBook.author)
        }
    }
    
    //Test create endpoint fucntion
    func testCreateBookEndpoint() throws {
        
        let name = "Test_Name"
        let author = "Test_Author"
    
        
        try app.test(.POST, "books", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            
            try req.content.encode([
                "name": name,
                "author": author
            ])
        }) { res in
            
            XCTAssertEqual(res.status, .ok)
            
            let returnedBook = try res.content.decode(Book.self)
            
            XCTAssertNotNil(returnedBook.id)
            XCTAssertEqual(returnedBook.name, name)
            XCTAssertEqual(returnedBook.author, author)
        }
        
    }
    
    func testCreateBookFailWhenBookNameMissing() throws {
        
        let author = "Test_Author"
        
        try app.test(.POST, "books", beforeRequest: {
            req in
            
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            try req.content.encode([
                "author": author
            ])
        }) { res in
            
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertTrue(try res.content.get(at: "error"))

        }
        
    }
    
    func testCreateBookFailWhenBookAuthorMissing() throws {
        
        let name = "Test_Name"
        
        try app.test(.POST, "books", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            try req.content.encode([
                "name": name
            ])
        }) { res in
            
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertTrue(try res.content.get(at: "error"))
        }
        
    }
    
    func testCreateBookFailWhenNoContent() throws {
        
        
        try app.test(.POST, "books", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
        }) { res in
            
            XCTAssertNotEqual(res.status, .ok)
            
        }
        
    }
    
    func testDeleteBookUsingValidID() throws {
        
        let book = Book(name: "Test_Name", author: "Test_Author")
        try book.save(on: app.db).wait()
        
        try app.test(.DELETE, "books/\(book.id!)", beforeRequest: {
            req in
            
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
        }) { res in
            
            XCTAssertEqual(res.status, .ok)
            
        }
        
    }
    
    func testDeleteBookUsingInvalidID() throws {
        
        try app.test(.DELETE, "books/123565453453", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
        }) { res in
            
            XCTAssertEqual(res.status, .notFound)
            
        }
        
    }
    
    // test update endpoint function
    
    func testUpdateBookUsingValidParams() throws {
        
        let name = "Test_Name"
        let author = "Test_Author"
        
        
        let book = Book(name: name, author: author)
        
        try book.save(on: app.db).wait()
        
        let bookID = book.id!
        
        try app.test(.PUT, "books/\(bookID)", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            try req.content.encode([
                "name": "newName",
                "author": "newAuthor",
            ])
            
        }, afterResponse: { res in
            
            let updated = try res.content.decode(Book.self)
            
            XCTAssertEqual(updated.id, bookID)
            XCTAssertEqual(updated.name, "newName")
            XCTAssertEqual(updated.author, "newAuthor")
        })

        
    }
    
    func testUpdateBookUsingInvalidID() throws {
        
        try app.test(.PUT, "books/123542", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
            try req.content.encode([
                "name": "newName",
                "author": "newAuthor",
            ])
            
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testGetBookByIDUsingValidParams() throws {
        
        let book = Book(name: "Test_Book", author: "Test_Authors")
        
        try book.save(on: app.db).wait()
        
        let bookID = book.id!
        
        try app.test(.GET, "books/\(bookID)", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
        }) { res in
            
            XCTAssertEqual(res.status, .ok)
            
            
            let returnedBook = try res.content.decode(Book.self)
            
            XCTAssertEqual(returnedBook.id, bookID)
            
            XCTAssertEqual(returnedBook.name, book.name)
            XCTAssertEqual(returnedBook.author, book.author)
        }
        
    }
    
    func testGetBookByIDUsingInvalidID() throws {
        try app.test(.GET, "book/13123213", beforeRequest: {
            req in
            req.headers.basicAuthorization = .init(username: "user@gmail.com", password: "123")
        }) { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}

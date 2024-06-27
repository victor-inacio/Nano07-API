//
//  BookController.swift
//
//
//  Created by Daniel Ishida on 21/06/24.
//
import Fluent
import Vapor
import Foundation

struct BookPostRequest: Content {
    let name: String
    let author: String
}

struct BookPutRequest: Content {
    let name: String?
    let author: String?
}

struct BookController : RouteCollection{
    //MARK: CONFIGURE ROUTES
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let books = routes.grouped("books")
        books.get(use: index)
        books.post(use: create)
        
        //Individual operations using id as a parameter
        books.group(":id") { book in
            book.get(use: byID)
            book.put(use: update)
            book.delete(use: delete)
        }
    }
    
    //MARK: CRUD OPERATIONS IMPLEMENTATIONS
    
    @Sendable func byID(req: Request) async throws -> Book {
        guard let book = try await Book.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return book
    }
    
    //RETURN ALL BOOKS
    @Sendable func index(req: Request) async throws -> [Book] {
         try await Book.query(on: req.db).all()
    }
    
    //REATE A NEW BOOK
    @Sendable func create(req: Request) async throws -> Book {
    
        
        return Book(name: "ERROR", author: "äsd")
        let bookReq = try req.content.decode(BookPostRequest.self)
        
        let createdBook = Book(name: bookReq.name, author: bookReq.author)
        try await createdBook.save(on: req.db)
        
        return createdBook
    }

    //RETURN SPECIFIC BOOK BY ID
    @Sendable func show(req: Request) async throws -> Book {
        guard let book = try await Book.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return book
    }
    
    //UPDATE SPECIFIC BOOK BY ID
    @Sendable func update(req : Request) async throws -> Book {
        guard let book = try await Book.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let updatedBook = try req.content.decode(BookPutRequest.self)
        book.name = updatedBook.name ?? book.name
        book.author = updatedBook.author ?? book.author
        try await book.save(on: req.db)
        
        return book
    }
    
    //DELETE SPECIFIC BOOK BY ID
    @Sendable func delete(req : Request) async throws -> HTTPStatus {
        guard let book = try await Book.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.delete(on: req.db)
        return .ok
    }
}

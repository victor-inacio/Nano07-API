//
//  UserModel.swift
//
//
//  Created by Daniel Ishida on 26/06/24.
//

import Foundation
import Vapor
import Fluent

final class User : Model, Content, @unchecked Sendable{
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
     
    @Field(key: "email")
    var email: String
     
    @Field(key: "password")
    var password: String
     
    init() { }
     
    init(id: UUID? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}

//
//  UserError.swift
//  
//
//  Created by Nathan Fuller on 10/14/22.
//

import Foundation

import Vapor

enum UserError {
    case invalidEmail(String)
    case invalidPassword
    case userRenameCooldown(Date, Date)
}

extension UserError: AbortError {
    var reason: String {
        switch self {
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        case .invalidPassword:
            return "Password is not valid. Please choose a password at least 8 characters in length."
        case .userRenameCooldown(let date, let timeRemaining):
            return "This username was last updated at \(date.timeOnDate). You must wait until \(timeRemaining.timeOnDate) before updating again."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .invalidEmail:
            return .badRequest
        case .invalidPassword:
            return .badRequest
        case .userRenameCooldown:
            return .forbidden
        }
    }
}

extension Date {
    var timeOnDate: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, YYYY"
        
        return "\(timeFormatter.string(from: self)) on \(dateFormatter.string(from: self))"
    }
}

//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class User: Equatable, Assertable {

    public let userID: UserID
    public private(set) var password: String = ""

    public enum Error: Swift.Error, Hashable {
        case emptyPassword
        case passwordTooShort
        case passwordTooLong
        case passwordMissingCapitalLetter
        case passwordMissingDigit
    }

    init(id: UserID, password: String) throws {
        userID = id
        try changePassword(old: "", new: password)
    }

    func changePassword(old: String, new password: String) throws {
        try User.assertArgument(!password.isEmpty, Error.emptyPassword)
        try User.assertArgument(password.count >= 6, Error.passwordTooShort)
        try User.assertArgument(password.count <= 100, Error.passwordTooLong)
        try User.assertArgument(password.hasUppercaseLetter, Error.passwordMissingCapitalLetter)
        try User.assertArgument(password.hasDecimalDigit, Error.passwordMissingDigit)
        self.password = password
    }

    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.userID == rhs.userID
    }
}

public struct UserID: Hashable, Assertable {

    public var id: String

    public enum Error: Swift.Error {
        case invalidID
    }

    public init(_ id: String) throws {
        self.id = id
        try UserID.assertArgument(id.count == 36, Error.invalidID)
    }

}

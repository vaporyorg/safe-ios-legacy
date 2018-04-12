//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import safe
import IdentityAccessApplication

class MockAuthenticationService: AuthenticationApplicationService {

    private var userRegistered = false
    private var shouldThrowDuringRegistration = false
    private(set) var didRequestUserRegistration = false
    private var userAuthenticated = false
    private var authenticationAllowed = false
    private(set) var didRequestBiometricAuthentication = false
    private(set) var didRequestPasswordAuthentication = false
    private var biometricAuthenticationPossible = true
    private var enabledAuthenticationMethods = Set<AuthenticationMethod>([AuthenticationMethod.password])
    private var authenticationBlocked = false

    enum Error: Swift.Error { case error }

    func unregisterUser() {
        userRegistered = false
    }

    func prepareToThrowWhenRegisteringUser() {
        shouldThrowDuringRegistration = true
    }

    override var isUserRegistered: Bool {
        return userRegistered
    }

    override func registerUser(password: String, completion: (() -> Void)? = nil) throws {
        didRequestUserRegistration = true
        if shouldThrowDuringRegistration {
            throw Error.error
        }
        userRegistered = true
        completion?()
    }

    func invalidateAuthentication() {
        authenticationAllowed = false
        userAuthenticated = false
    }

    func allowAuthentication() {
        authenticationAllowed = true
    }

    override var isUserAuthenticated: Bool {
        return isUserRegistered && userAuthenticated && !isAuthenticationBlocked
    }

    override func authenticateUser(password: String?, completion: ((Bool) -> Void)? = nil) {
        didRequestBiometricAuthentication = password == nil
        didRequestPasswordAuthentication = !didRequestBiometricAuthentication
        userAuthenticated = authenticationAllowed && !authenticationBlocked
        completion?(userAuthenticated)
    }

    func makeBiometricAuthenticationImpossible() {
        biometricAuthenticationPossible = false
    }

    override var isBiometricAuthenticationPossible: Bool {
        return biometricAuthenticationPossible
    }

    func enableFaceIDSupport() {
        enabledAuthenticationMethods.insert(.faceID)
    }

    override func isAuthenticationMethodSupported(_ method: AuthenticationMethod) -> Bool {
        return enabledAuthenticationMethods.contains(method)
    }

    func blockAuthentication() {
        authenticationBlocked = true
        makeBiometricAuthenticationImpossible()
    }

    override var isAuthenticationBlocked: Bool {
        return authenticationBlocked
    }
}

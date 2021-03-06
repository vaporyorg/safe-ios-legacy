//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import IdentityAccessApplication
import IdentityAccessDomainModel
import IdentityAccessImplementations

/// Base class for all unit tests in this module.
class ApplicationServiceTestCase: XCTestCase {

    let authenticationService = AuthenticationApplicationService()
    let userRepository: SingleUserRepository = InMemoryUserRepository()
    let biometricService = MockBiometricService()
    let encryptionService = MockEncryptionService()
    let gatekeeperRepository = InMemoryGatekeeperRepository()
    let identityDomainService = IdentityService()
    var clockService = MockClockService()

    override func setUp() {
        super.setUp()
        configureIdentityServiceDependencies()
        configureAuthenticationServiceDependencies()
    }

    private func configureIdentityServiceDependencies() {
        ApplicationServiceRegistry.put(service: clockService, for: Clock.self)
    }

    private func configureAuthenticationServiceDependencies() {
        ApplicationServiceRegistry.put(service: authenticationService,
                                       for: AuthenticationApplicationService.self)
        DomainRegistry.put(service: userRepository, for: SingleUserRepository.self)
        DomainRegistry.put(service: biometricService, for: BiometricAuthenticationService.self)
        DomainRegistry.put(service: encryptionService, for: EncryptionService.self)
        DomainRegistry.put(service: identityDomainService, for: IdentityService.self)
        DomainRegistry.put(service: gatekeeperRepository, for: SingleGatekeeperRepository.self)
        DomainRegistry.put(service: clockService, for: Clock.self)

        XCTAssertNoThrow(try DomainRegistry.identityService.createGatekeeper(sessionDuration: 2,
                                                                             maxFailedAttempts: 2,
                                                                             blockDuration: 1))
    }

}

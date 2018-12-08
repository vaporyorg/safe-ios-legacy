//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common
import BigInt

public class WalletID: BaseID {}

public class Wallet: IdentifiableEntity<WalletID> {

    public enum Error: String, LocalizedError, Hashable {
        case ownerNotFound
        case invalidState
    }

    // FIXME: encapsulate
    public var state: WalletState!

    public private(set) var newDraftState: WalletState!
    public private(set) var deployingState: WalletState!
    public private(set) var notEnoughFundsState: WalletState!
    public private(set) var creationStartedState: WalletState!
    public private(set) var finalizingDeploymentState: WalletState!
    public private(set) var readyToUseState: WalletState!
    public private(set) var recoveryDraftState: WalletState!

    public private(set) var address: Address?
    public private(set) var creationTransactionHash: String?
    public private(set) var minimumDeploymentTransactionAmount: TokenInt?
    public private(set) var confirmationCount: Int = 1
    public private(set) var deploymentFee: BigInt?
    public private(set) var owners = OwnerList()

    public var isDeployable: Bool {
        return state.isDeployable
    }

    public var isReadyToUse: Bool {
        return state.isReadyToUse
    }

    public var isCreationInProgress: Bool {
        return state.isCreationInProgress
    }

    public convenience init(id: WalletID,
                            state: WalletState.State,
                            owners: OwnerList,
                            address: Address?,
                            minimumDeploymentTransactionAmount: TokenInt?,
                            creationTransactionHash: String?,
                            confirmationCount: Int = 1) {
        self.init(id: id)
        initStates()
        self.state = newDraftState
        owners.forEach { addOwner($0) }
        self.state = self.state(from: state)
        self.address = address
        self.minimumDeploymentTransactionAmount = minimumDeploymentTransactionAmount
        self.creationTransactionHash = creationTransactionHash
        self.confirmationCount = confirmationCount
    }

    private func state(from walletState: WalletState.State) -> WalletState {
        switch walletState {
        case .draft: return newDraftState
        case .deploying: return deployingState
        case .notEnoughFunds: return notEnoughFundsState
        case .creationStarted: return creationStartedState
        case .finalizingDeployment: return finalizingDeploymentState
        case .readyToUse: return readyToUseState
        case .recoveryDraft: return recoveryDraftState
        }
    }

    public convenience init(id: WalletID, owner: Address) {
        self.init(id: id)
        initStates()
        state = newDraftState
        addOwner(Owner(address: owner, role: .thisDevice))
    }

    private func initStates() {
        newDraftState = DraftState(wallet: self)
        deployingState = DeployingState(wallet: self)
        notEnoughFundsState = NotEnoughFundsState(wallet: self)
        creationStartedState = CreationStartedState(wallet: self)
        finalizingDeploymentState = FinalizingDeploymentState(wallet: self)
        readyToUseState = ReadyToUseState(wallet: self)
        recoveryDraftState = RecoveryDraftState(wallet: self)
    }

    public func prepareForRecovery() {
        guard state !== recoveryDraftState else { return }
        state = recoveryDraftState
        owners.removeAll { $0.role != .thisDevice }
        confirmationCount = 1
    }

    public func prepareForCreation() {
        guard state !== newDraftState else { return }
        state = newDraftState
        owners.removeAll { $0.role != .thisDevice }
        confirmationCount = 1
    }

    public func owner(role: OwnerRole) -> Owner? {
        return owners.first(with: role)
    }

    public func allOwners() -> [Owner] {
        return owners.sortedOwners()
    }

    public static func createOwner(address: String, role: OwnerRole) -> Owner {
        return Owner(address: Address(address), role: role)
    }

    public func addOwner(_ owner: Owner) {
        assertCanChangeOwners()
        if owner.role == .unknown {
            owners.append(owner)
        } else {
            owners.remove(with: owner.role)
            owners.append(owner)
        }
    }

    private func assertCanChangeOwners() {
        try! assertTrue(state.canChangeOwners, Error.invalidState)
    }

    public func contains(owner: Owner) -> Bool {
        return owners.contains(owner)
    }

    public func removeOwner(role: OwnerRole) {
        assertCanChangeOwners()
        assertOwnerExists(role)
        owners.remove(with: role)
    }

    public func assignCreationTransaction(hash: String?) {
        try! assertTrue(state.canChangeTransactionHash, Error.invalidState)
        creationTransactionHash = hash
    }

    public func changeAddress(_ address: Address?) {
        try! assertTrue(state.canChangeAddress, Error.invalidState)
        self.address = address
    }

    public func changeConfirmationCount(_ newValue: Int) {
        // TODO: guard for state
        confirmationCount = newValue
    }

    private func assertOwnerExists(_ role: OwnerRole) {
        try! assertNotNil(owner(role: role), Error.ownerNotFound)
    }

    public func updateMinimumTransactionAmount(_ newValue: TokenInt) {
        try! assertTrue(state.canChangeAddress, Error.invalidState)
        minimumDeploymentTransactionAmount = newValue
    }

    public func resume() {
        state.resume()
    }

    public func proceed() {
        state.proceed()
    }

    public func cancel() {
        state.cancel()
    }

    func reset() {
        creationTransactionHash = nil
        address = nil
        minimumDeploymentTransactionAmount = nil
    }
}

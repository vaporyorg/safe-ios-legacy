//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Represents collection of externally owned accounts
public protocol ExternallyOwnedAccountRepository {

    /// Persists account
    ///
    /// - Parameter account: account to save
    func save(_ account: ExternallyOwnedAccount)

    /// Removes account with address from the colleciton
    ///
    /// - Parameter address: address of an account to remove
    func remove(address: Address)

    /// Searches for an account by its address.
    ///
    /// - Parameter address: address of an externally owned account
    /// - Returns: account if found, nil if not found, or if underlying database or item in it is not available
    ///            for example, during the device locked phase.
    func find(by address: Address) -> ExternallyOwnedAccount?

}

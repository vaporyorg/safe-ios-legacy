//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// secp256k1 signature components used for Ethereum signatures.
public struct EthSignature: Codable, Equatable {

    public var r: String
    public var s: String
    public var v: Int

    public init(r: String, s: String, v: Int) {
        self.r = r
        self.s = s
        self.v = v
    }

}

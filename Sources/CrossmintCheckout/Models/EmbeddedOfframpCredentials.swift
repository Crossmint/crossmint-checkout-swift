//
//  EmbeddedOfframpCredentials.swift
//  CrossmintCheckout
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation

/// The credentials of one offramp session.
///
/// Create the session on your server with Create Offramp Session, then pass the `sessionId` and
/// `clientSecret` of the response. You can also decode the credentials from that response.
public struct EmbeddedOfframpCredentials: Codable, Sendable, Equatable {
    /// The identifier of the offramp session.
    public let sessionId: String
    let clientSecret: String

    /// Creates the credentials of an offramp session.
    public init(sessionId: String, clientSecret: String) {
        self.sessionId = sessionId
        self.clientSecret = clientSecret
    }
}

extension EmbeddedOfframpCredentials: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "EmbeddedOfframpCredentials(sessionId: \(sessionId))" }

    public var debugDescription: String { description }
}

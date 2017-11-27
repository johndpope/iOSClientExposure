//
//  ExposureAnalyticsProvider.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-10-26.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import Player

/// Extends the `Player` built in protocol defining analytics events with *Exposure* specific analytics
public protocol ExposureStreamingAnalyticsProvider: AnalyticsProvider {
    init(environment: Environment, sessionToken: SessionToken)
    
    /// Exposure environment used for the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var environment: Environment { get }
    
    /// Token identifying the active session.
    ///
    /// - Important: should match the `environment` used to authenticate the user.
    var sessionToken: SessionToken { get }
    
    /// Sent when the player is about to make an entitlement request
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter request: The type of asset request
    func onEntitlementRequested<Tech>(tech: Tech, request: AssetIdentifier) where Tech: PlaybackTech
    
    /// Sent when the entitlement has been granted, right after loading of media sources has been initiated.
    ///
    /// - parameter tech: `PlaybackTech` to be used for playback
    /// - parameter source: `MediaSource` used to load the request,
    /// - parameter request: The type of asset request
    func onHandshakeStarted<Tech, Source>(tech: Tech, source: Source, request: AssetIdentifier) where Tech: PlaybackTech, Source: MediaSource
    
    /// Should prepare and configure the remaining parts of the Analytics environment.
    /// This step is required because we are dependant on the response from Exposure with regards to the playSessionId.
    ///
    /// Once this is called, a Dispatcher should be associated with the session.
    ///
    /// - parameter playSessionId: Unique identifier for the current playback session.
    /// - parameter asset: *EMP* asset identifiers.
    /// - parameter entitlement: The entitlement this session concerns
    /// - parameter heartbeatsProvider: Will deliver heartbeats metadata during the session
    func finalizePreparation(for playSessionId: String, asset: AssetIdentifier, with entitlement: PlaybackEntitlement, heartbeatsProvider: HeartbeatsProvider)
}


//
//  ChannelSourceSpec+StartTime.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player

@testable import Exposure

class ChannelSourceStartTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        let segmentLength:Int64 = 6000
        describe("ChannelSource") {
            let environment = Environment(baseUrl: "url", customer: "customer", businessUnit: "businessUnit")
            let sessionToken = SessionToken(value: "token")
            let tech = HLSNative<ExposureContext>()
            
            context(".defaultBehaviour") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .defaultBehaviour)
                    it("should use default behavior with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .defaultBehaviour)
                    it("should use default behavior with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".beginning") {
                
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .beginning)
                    it("should start from segmentLength with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from segmentLength with lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from segmentLength with no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .beginning)
                    it("should rely on vod manifest to start from 0 with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".bookmark") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .bookmark)
                    it("should pick up lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(100))
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .bookmark)
                    it("should pick up lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(100))
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".custom") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .custom(offset: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .custom(offset: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ChannelSource(entitlement: entitlement, assetId: "assetId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                }
            }
        }
        
        func buildEntitlement(pipe: String = "http://www.example.com/.isml", lastViewedOffset: Int? = nil, lastViewedTime: Int? = nil) -> PlaybackEntitlement {
            return PlaybackEntitlement(playTokenExpiration: "playTokenExpiration", mediaLocator: URL(string: pipe)!, playSessionId: "playSessionId", live: false, ffEnabled: false, timeshiftEnabled: false, rwEnabled: false, airplayBlocked: false, playToken: nil, fairplay: nil, licenseExpiration: nil, licenseExpirationReason: nil, licenseActivation: nil, entitlementType: nil, minBitrate: nil, maxBitrate: nil, maxResHeight: nil, mdnRequestRouterUrl: nil, lastViewedOffset: lastViewedOffset, lastViewedTime: lastViewedTime, liveTime: nil, productId: nil)
        }
    }
}

//
//  AnonymousSpec.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-04-20.
//  Copyright © 2017 emp. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

@testable import Exposure

class AnonymousSpec: QuickSpec {
    var endpointStub: Stub?
    
    override func spec() {
        super.spec()
        
        let base = "https://exposure.empps.ebsd.ericsson.net"
        let customer = "BlixtGroup"
        let businessUnit = "Blixt"
        let env = Environment(baseUrl: base, customer: customer, businessUnit: businessUnit)
        
        let anonymous = Authenticate(environment: env)
            .anonymous()
        
        let expectedSessionToken = "sessionToken"
        let expectedCrmToken = "crmToken"
        let expectedAccountId = "accountId"
        let date = Date()
        let expectedExpirationDate = Date.utcFormatter().string(from: date)
        let expectedAccountStatus = "accountStatus"
        
        let expectedJson: [String: Any] = [
            "sessionToken":expectedSessionToken,
            "crmToken":expectedCrmToken,
            "accountId":expectedAccountId,
            "expirationDateTime":expectedExpirationDate,
            "accountStatus":expectedAccountStatus
        ]
        
        describe("Anonymous") {
            it("should have no headers") {
                expect(anonymous.headers).to(beNil())
            }
            
            it("should generate a correct endpoint url") {
                let endpoint = "/auth/anonymous"
                expect(anonymous.endpointUrl).to(equal(env.apiUrl+endpoint))
            }
        }
        
        describe("Anonymous Login Response") {
            // http://httpbin.org/
            
            var request: URLRequest?
            var response: URLResponse?
            var data: Data?
            var token: SessionToken?
            var error: ExposureError?
            
            beforeEach {
                request = nil
                response = nil
                data = nil
                token = nil
                error = nil
            }
            
            context("Success") {
                beforeEach {
                    self.stub(uri(anonymous.endpointUrl), json(expectedJson))
                    
                    anonymous
                        .request()
                        .response{
                            request = $0.request
                            response = $0.response
                            data = $0.data
                            token = $0.value
                            error = $0.error
                    }
                }
                
                it("should eventually return a response") {
                    
                    expect(request).toEventuallyNot(beNil())
                    expect(response).toEventuallyNot(beNil())
                    expect(data).toEventuallyNot(beNil())
                    expect(token).toEventuallyNot(beNil())
                    expect(error).toEventually(beNil())
                    
                    expect(token!.value).toEventually(equal(expectedSessionToken))
                }
            }
            
            let invalidAnonymous = Authenticate(environment: env).anonymous()
            
            let errorJson: [String: Any] = [
                "httpCode":404,
                "message":"UNKNOWN_BUSINESS_UNIT"
            ]
            context("Failure with invalid environment") {
                var httpCode: Int?
                var message: String?
                beforeEach {
                    self.stub(uri(invalidAnonymous.endpointUrl), json(errorJson, status: 404))
                    
                    invalidAnonymous
                        .request()
                        .response{
                            request = $0.request
                            response = $0.response
                            data = $0.data
                            token = $0.value
                            error = $0.error
                            
                            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                                as? [String: Any] ?? [:] {
                                    httpCode = json["httpCode"] as? Int
                                    message = json["message"] as? String
                            }
                    }
                }
                
                it("should throw an objectSerialization error without validate()") {
                    expect(data).toEventuallyNot(beNil())
                    expect(httpCode).toEventuallyNot(beNil())
                    expect(message).toEventuallyNot(beNil())
                    
                    expect(token).toEventually(beNil())
                    expect(error).toEventuallyNot(beNil())
                    let expectedError = ExposureError.serialization(reason: ExposureError.SerializationFailureReason.objectSerialization(reason: "Unable to serialize object", json: errorJson))
                    expect(error).toEventually(matchError(expectedError))
                    
                    expect(httpCode).toEventually(equal(404))
                    expect(message).toEventually(equal("UNKNOWN_BUSINESS_UNIT"))
                }
            }
            
            /*context("Failure with invalid status code in response using validate()") {
                let exposureResponse = ExposureResponseMessage(json: errorJson)!
                beforeEach {
                    self.stub(uri(invalidAnonymous.endpointUrl), json(errorJson, status: 404))
                    
                    invalidAnonymous
                        .request()
                        .validate()
                        .response{ (exposureResponse: ExposureResponse<SessionToken>) in
                            request = exposureResponse.request
                            response = exposureResponse.response
                            data = exposureResponse.data
                            token = exposureResponse.value
                            error = exposureResponse.error
                    }
                }
                
                it("should throw an exposureResponse error when using validate()") {
                    expect(data).toEventuallyNot(beNil())
                    expect(token).toEventually(beNil())
                    expect(error).toEventuallyNot(beNil())
                    let expectedError = ExposureError.exposureResponse(reason: exposureResponse)
                    expect(error).toEventually(matchError(expectedError))
                    expect(error!.localizedDescription).toEventually(equal(expectedError.localizedDescription))
                }
            }
            
            context("Failure with invalid status code in response using validate statusCode: 200..<299") {
                let exposureResponse = ExposureResponseMessage(json: errorJson)!
                beforeEach {
                    self.stub(uri(invalidAnonymous.endpointUrl), json(errorJson, status: 404))
                    
                    invalidAnonymous
                        .request()
                        .validate(statusCode: 200..<299)
                        .response{ (exposureResponse: ExposureResponse<SessionToken>) in
                            request = exposureResponse.request
                            response = exposureResponse.response
                            data = exposureResponse.data
                            token = exposureResponse.value
                            error = exposureResponse.error
                    }
                }
                
                it("should throw an exposureResponse error when using validate statusCode: 200..<299") {
                    expect(data).toEventuallyNot(beNil())
                    expect(token).toEventually(beNil())
                    expect(error).toEventuallyNot(beNil())
                    expect(error).toEventually(matchError(ExposureError.exposureResponse(reason: exposureResponse)))
                }
            }*/
            
            context("Success with valid status code in response using validate(statusCode: 403..<405)") {
                beforeEach {
                    self.stub(uri(invalidAnonymous.endpointUrl), json(errorJson, status: 404))
                    
                    invalidAnonymous
                        .request()
                        .validate(statusCode: 403..<405)
                        .response{
                            request = $0.request
                            response = $0.response
                            data = $0.data
                            token = $0.value
                            error = $0.error
                    }
                }
                
                it("should throw an serialization error with valid status code") {
                    expect(data).toEventuallyNot(beNil())
                    expect(token).toEventually(beNil())
                    expect(error).toEventuallyNot(beNil())
                    expect(error).toEventually(matchError(ExposureError.serialization(reason: .objectSerialization(reason: "Unable to serialize object", json: errorJson))))
                }
            }
        }
    }
}

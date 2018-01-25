//
//  USPFairPlayRequester.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-25.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import AVFoundation
import Player
import Alamofire

internal class USPFairPlayRequester: NSObject, ExposureFairplayRequester, FairplayRequester {
    
    init(entitlement: PlaybackEntitlement) {
        self.entitlement = entitlement
    }
    
    internal let entitlement: PlaybackEntitlement
    internal let resourceLoadingRequestQueue = DispatchQueue(label: "com.emp.exposure.streaming.fairplay.requests")
    internal let customScheme = "skd"
    internal let resourceLoadingRequestOptions: [String : AnyObject]? = nil
    
    internal func onSuccessfulRetrieval(of ckc: Data, for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Data {
        return ckc
    }
    
    /// Streaming requests normally always contact the remote for license and certificates.
    internal func shouldContactRemote(for resourceLoadingRequest: AVAssetResourceLoadingRequest) throws -> Bool {
        return true
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension USPFairPlayRequester {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return canHandle(resourceLoadingRequest: loadingRequest)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return canHandle(resourceLoadingRequest: renewalRequest)
    }
}

extension USPFairPlayRequester {
    /// Starting point for the *Fairplay* validation chain. Note that returning `false` from this method does not automatically mean *Fairplay* validation failed.
    ///
    /// - parameter resourceLoadingRequest: loading request to handle
    /// - returns: ´true` if the requester can handle the request, `false` otherwise.
    internal func canHandle(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        //EMPFairplayRequester only should handle FPS Content Key requests.
        if url.scheme != customScheme {
            return false
        }
        
        resourceLoadingRequestQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            do {
                if try weakSelf.shouldContactRemote(for: resourceLoadingRequest) {
                    weakSelf.handle(resourceLoadingRequest: resourceLoadingRequest)
                }
            }
            catch {
                resourceLoadingRequest.finishLoading(with: error)
            }
        }
        
        return true
    }
}

extension USPFairPlayRequester {
    /// Handling a *Fairplay* validation request is a process in several parts:
    ///
    /// * Fetch and parse the *Application Certificate*
    /// * Request a *Server Playback Context*, `SPC`, for the specified asset using the *Application Certificate*
    /// * Request a *Content Key Context*, `CKC`, for the validated `SPC`.
    ///
    /// If this process fails, the `resourceLoadingRequest` will call `resourceLoadingRequest.finishLoading(with: someError`.
    ///
    /// For more information regarding *Fairplay* validation, please see Apple's documentation regarding *Fairplay Streaming*.
    fileprivate func handle(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let url = resourceLoadingRequest.request.url,
            let assetIDString = url.host,
            let contentIdentifier = assetIDString.data(using: String.Encoding.utf8) else {
                resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .invalidContentIdentifier))
                return
        }
        
        
        
        print(url, " - ",assetIDString)
        
        fetchApplicationCertificate{ [unowned self] certificate, certificateError in
            print("fetchApplicationCertificate")
            if let certificateError = certificateError {
                print("fetchApplicationCertificate ",certificateError.localizedDescription)
                resourceLoadingRequest.finishLoading(with: certificateError)
                return
            }
            
            if let certificate = certificate {
                print("prepare SPC")
                do {
                    let spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: certificate, contentIdentifier: contentIdentifier, options: self.resourceLoadingRequestOptions)
                    
                    // Content Key Context fetch from licenseUrl requires base64 encoded data
                    let spcBase64 = spcData//.base64EncodedData(options: Data.Base64EncodingOptions.endLineWithLineFeed)
                    
                    self.fetchContentKeyContext(spc: spcBase64) { ckcBase64, ckcError in
                        print("fetchContentKeyContext")
                        if let ckcError = ckcError {
                            print("CKC Error",ckcError.localizedDescription)
                            resourceLoadingRequest.finishLoading(with: ckcError)
                            return
                        }
                        
                        guard let dataRequest = resourceLoadingRequest.dataRequest else {
                            print("dataRequest Error",ExposureError.fairplay(reason: .missingDataRequest).localizedDescription)
                            resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .missingDataRequest))
                            return
                        }
                        
                        guard let ckcBase64 = ckcBase64 else {
                            print("ckcBase64 Error",ExposureError.fairplay(reason: .missingContentKeyContext).localizedDescription)
                            resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .missingContentKeyContext))
                            return
                        }
                        
                        do {
                            // Allow implementation specific handling of the returned `CKC`
                            let contentKey = try self.onSuccessfulRetrieval(of: ckcBase64, for: resourceLoadingRequest)
                            
                            // Provide data to the loading request.
                            dataRequest.respond(with: contentKey)
                            resourceLoadingRequest.finishLoading() // Treat the processing of the request as complete.
                        }
                        catch {
                            print("onSuccessfulRetrieval Error",error)
                            resourceLoadingRequest.finishLoading(with: error)
                        }
                    }
                }
                catch {
                    //                    -42656 Lease duration has expired.
                    //                    -42668 The CKC passed in for processing is not valid.
                    //                    -42672 A certificate is not supplied when creating SPC.
                    //                    -42673 assetId is not supplied when creating an SPC.
                    //                    -42674 Version list is not supplied when creating an SPC.
                    //                    -42675 The assetID supplied to SPC creation is not valid.
                    //                    -42676 An error occurred during SPC creation.
                    //                    -42679 The certificate supplied for SPC creation is not valid.
                    //                    -42681 The version list supplied to SPC creation is not valid.
                    //                    -42783 The certificate supplied for SPC is not valid and is possibly revoked.
                    print("SPC - ",error.localizedDescription)
                    print("SPC - ",error)
                    resourceLoadingRequest.finishLoading(with: ExposureError.fairplay(reason: .serverPlaybackContext(error: error)))
                    return
                }
            }
        }
    }
}

// MARK: - Application Certificate
extension USPFairPlayRequester {
    /// The *Application Certificate* is fetched from a server specified by a `certificateUrl` delivered in the *entitlement* obtained through *Exposure*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Application Certificate* from an *MRR specific* format.
    /// - parameter callback: fires when the certificate is fetched or when an `error` occurs.
    fileprivate func fetchApplicationCertificate(callback: @escaping (Data?, ExposureError?) -> Void) {
        guard let url = certificateUrl else {
            callback(nil, .fairplay(reason: .missingApplicationCertificateUrl))
            return
        }
        
        Alamofire
            .request(url, method: .get)
            .responseData{ [weak self] response in
                
                if let error = response.error {
                    callback(nil, .fairplay(reason: .networking(error: error)))
                    return
                }
                
                if let success = response.value {
                    do {
                        let certificate = try self?.parseApplicationCertificate(response: success)
                        callback(certificate, nil)
                    }
                    catch {
                        // parseApplicationCertificate will only throw PlayerError
                        callback(nil, error as? ExposureError)
                    }
                }
        }
    }
    
    /// Retrieve the `certificateUrl` by parsing the *entitlement*.
    fileprivate var certificateUrl: URL? {
        return URL(string: "http://psempfairplayserver.northeurope.cloudapp.azure.com:8080/fps/BlixtGroup/Blixt/")
        //        guard let urlString = entitlement.fairplay?.certificateUrl else { return nil }
        //        return URL(string: urlString)
    }
    
    fileprivate func parseApplicationCertificate(response data: Data) throws -> Data {
        let cert = try JSONDecoder().decode(TempCert.self, from: data)
        guard let base64 = Data(base64Encoded: cert.certificate, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
            throw ExposureError.fairplay(reason: .applicationCertificateDataFormatInvalid)
        }
        return base64
    }
    
}

struct TempCert: Decodable {
    let certificate: String
}

struct TempCKC: Decodable {
    let ckc: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print(container.allKeys, container.contains(.ckc))
        ckc = try container.decode(String.self, forKey: .ckc)
    }
    
    enum CodingKeys: CodingKey {
        case ckc
    }
}

// MARK: - Content Key Context
extension USPFairPlayRequester {
    /// Fetching a *Content Key Context*, `CKC`, requires a valid *Server Playback Context*.
    ///
    /// - note: This method uses a specialized function for parsing the retrieved *Content Key Context* from an *MRR specific* format.
    ///
    /// - parameter spc: *Server Playback Context*
    /// - parameter callback: fires when `CKC` is fetched or when an `error` occurs.
    fileprivate func fetchContentKeyContext(spc: Data, callback: @escaping (Data?, ExposureError?) -> Void) {
        guard let url = licenseUrl else {
            callback(nil, .fairplay(reason: .missingContentKeyContextUrl))
            return
        }
        let spcString = spc.base64EncodedString()
        let params = [
            "mediaId":"",
            "spc":spcString
        ]
        print("spcString",spcString)
        
        Alamofire
            .request(url,
                     method: .post,
                     parameters: params,
                     encoding: JSONEncoding.default)
            .responseData{ response in
                if let error = response.error {
                    callback(nil, .fairplay(reason:.networking(error: error)))
                    return
                }
                
                if let success = response.value {
                    do {
                        print(success)
                        let json = try JSONSerialization.jsonObject(with: success, options: JSONSerialization.ReadingOptions.allowFragments)
                        print(json)
                        let ckc = try JSONDecoder().decode(TempCKC.self,
                                                           from: success)
                        guard let base64 = Data(base64Encoded: ckc.ckc, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) else {
                            callback(nil,ExposureError.fairplay(reason: .contentKeyContextDataFormatInvalid))
                            return
                        }
                        callback(base64,nil)
                    }
                    catch {
                        callback(nil,ExposureError.generalError(error: error))
                    }
                }
        }

    }
    
    /// Retrieve the `licenseUrl` by parsing the *entitlement*.
    fileprivate var licenseUrl: URL? {
        return certificateUrl
        //        guard let urlString = entitlement.fairplay?.licenseAcquisitionUrl else { return nil }
        //        return URL(string: urlString)
    }
}
//
//  FetchEpgList.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2017-06-14.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public struct FetchEpgList: Exposure, SortedResponse, PageableResponse, FilteredPublish {
    public typealias Response = [ChannelEpg]
    
    public var endpointUrl: String {
        return environment.apiUrl + "/content/asset"
    }
    
    public var parameters: [String: Any] {
        return queryParams
    }
    
    public var headers: [String: String]? {
        return nil
    }
    
    
    public var sortDescription: SortDescription
    public var pageFilter: PageFilter
    public var publishFilter: PublishFilter
    
    public let environment: Environment
    
    internal init(environment: Environment) {
        self.environment = environment
        self.sortDescription = SortDescription()
        self.pageFilter = PageFilter()
        self.publishFilter = PublishFilter()
    }
    
    internal enum Keys: String {
        case onlyPublished = "onlyPublished"
        case pageSize = "pageSize"
        case pageNumber = "pageNumber"
        case sort = "sort"
    }
    
    internal var queryParams: [String: Any] {
        var params:[String: Any] = [
            Keys.onlyPublished.rawValue: publishFilter.onlyPublished,
            Keys.pageNumber.rawValue: pageFilter.page,
            Keys.pageSize.rawValue: pageFilter.size
        ]
        
        if let sort = sortDescription.descriptors {
            // Query string is keys separated by ",".
            // Any descending key should include a "-" sign as a prefix.
            params[Keys.sort.rawValue] = sort
                .map{ $0.ascending ? "" : "-" + $0.key }
                .joined(separator: ",")
        }
        
        return params
    }
}

// MARK: - Request
extension FetchEpgList {
    public func request() -> ExposureRequest {
        return request(.get, encoding: ExposureURLEncoding.default)
    }
}

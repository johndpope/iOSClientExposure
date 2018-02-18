//
//  Request.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-02-06.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
}

/// Types adopting the `URLConvertible` protocol can be used to construct URLs, which are then used to construct
/// URL requests.
public protocol URLConvertible {
    /// Returns a URL that conforms to RFC 2396 or throws an `Error`.
    ///
    /// - throws: An `Error` if the type cannot be converted to a `URL`.
    ///
    /// - returns: A URL or throws an `Error`.
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /// Returns a URL if `self` represents a valid URL string that conforms to RFC 2396 or throws an `AFError`.
    ///
    /// - throws: An `AFError.invalidURL` if `self` is not a valid URL string.
    ///
    /// - returns: A URL or throws an `AFError`.
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw Request.Networking.invalidUrl(url: self) }
        return url
    }
}

extension URL: URLConvertible {
    /// Returns self.
    public func asURL() throws -> URL { return self }
}

extension URLComponents: URLConvertible {
    /// Returns a URL if `url` is not nil, otherise throws an `Error`.
    ///
    /// - throws: An `AFError.invalidURL` if `url` is `nil`.
    ///
    /// - returns: A URL or throws an `AFError`.
    public func asURL() throws -> URL {
        guard let url = url else { throw Request.Networking.invalidUrl(url: self) }
        return url
    }
}



public class Request {
    
    /// The delegate for the underlying task.
    public internal(set) var delegate: TaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }
    
    /// The underlying task.
    public var task: URLSessionTask? { return delegate.task }
    
    /// The session belonging to the underlying task.
    public let session: URLSession
    
    /// The request sent or to be sent to the server.
    public var request: URLRequest? { return task?.originalRequest }
    
    /// The response received from the server, if any.
    public var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }
    
    
    var validations: [() -> Void] = []
    
    private var taskDelegate: TaskDelegate
    private var taskDelegateLock = NSLock()
    
    // MARK: Lifecycle
    
    init(session: URLSession, requestTask: URLSessionTask?, error: Error? = nil) {
        self.session = session
        taskDelegate = TaskDelegate(task: requestTask)
        
        delegate.error = error
    }
    
    // MARK: State
    
    /// Resumes the request.
    public func resume() {
        guard let task = task else { delegate.queue.isSuspended = false ; return }
        
        task.resume()
    }
    
    /// Suspends the request.
    public func suspend() {
        guard let task = task else { return }
        
        task.suspend()
    }
    
    /// Cancels the request.
    public func cancel() {
        guard let task = task else { return }
        
        task.cancel()
    }
}

extension Request {
    /// Used to represent whether validation was successful or encountered an error resulting in a failure.
    ///
    /// - success: The validation was successful.
    /// - failure: The validation failed encountering the provided error.
    public enum ValidationResult {
        case success
        case failure(Error)
    }
    
    // MARK: Properties
    
    fileprivate var acceptableStatusCodes: [Int] { return Array(200..<300) }
    
    
    // MARK: Status Code
    
    fileprivate func validate<S: Sequence>(
        statusCode acceptableStatusCodes: S,
        response: HTTPURLResponse)
        -> ValidationResult
        where S.Iterator.Element == Int
    {
        if acceptableStatusCodes.contains(response.statusCode) {
            return .success
        } else {
            let reason = Networking.unacceptableStatusCode(code: response.statusCode)
            return .failure(reason)
        }
    }
    
    /// Validates the request, using the specified closure.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - parameter validation: A closure to validate the request.
    ///
    /// - returns: The request.
    @discardableResult
    public func validate(_ validation: @escaping (URLRequest?, HTTPURLResponse, Data?) -> ValidationResult) -> Self {
        let validationExecution: () -> Void = { [unowned self] in
            if
                let response = self.response,
                self.delegate.error == nil,
                case let .failure(error) = validation(self.request, response, self.delegate.data)
            {
                self.delegate.error = error
            }
        }
        
        validations.append(validationExecution)
        
        return self
    }
    
    /// Validates that the response has a status code in the specified sequence.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - parameter range: The range of acceptable status codes.
    ///
    /// - returns: The request.
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        return validate { _, response, _ in
            if acceptableStatusCodes.contains(response.statusCode) {
                return .success
            } else {
                let reason =  Networking.unacceptableStatusCode(code: response.statusCode)
                return .failure(reason)
            }
        }
    }
    /// Validates that the response has a status code in the default acceptable range of 200...299, and that the content
    /// type matches any specified in the Accept HTTP header field.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - returns: The request.
    @discardableResult
    public func validate() -> Self {
        return validate(statusCode: self.acceptableStatusCodes)
    }
}

public enum Result<Value> {
    case success(value: Value)
    case failure(error: Error)
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

extension Request {
    
    public enum Networking: Error {
        case invalidUrl(url: URLConvertible)
        case unacceptableStatusCode(code: Int)
        case noResponseData
        case parameterEncodingFailedMissingUrl
        
        public var message: String {
            switch self {
            case .invalidUrl(url: let url): return "Invalid URL in URLConvertible \(url)"
            case .unacceptableStatusCode(code: let code): return "Unacceptable status code \(code) in http response"
            case .noResponseData: return "Response data was null"
            case .parameterEncodingFailedMissingUrl: return "URLRequest is missing an url to encode parameters onto"
            }
        }
    }
    
    
    @discardableResult
    public func response<Object: Decodable>(queue: DispatchQueue? = nil, responseSerializer: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Object>, completionHandler: @escaping (Response<Object>) -> Void) -> Self {
        delegate.queue.addOperation {
            let result = responseSerializer(self.request,
                                            self.response,
                                            self.delegate.data,
                                            self.delegate.error)
            
            
            let dataResponse = Response(request: self.request,
                                        response: self.response,
                                        data: self.delegate.data,
                                        result: result)
            (queue ?? DispatchQueue.main).async {
                completionHandler(dataResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func response<Object: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (Response<Object>) -> Void) -> Self {
        let responseSerializer: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Object> = { request, response, data, error in
            guard error == nil, let jsonData = data else {
                return .failure(error: error!)
            }
            
            do {
                let object = try JSONDecoder().decode(Object.self, from: jsonData)
                return .success(value: object)
            }
            catch (let e) {
                return .failure(error: e)
            }
        }
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    @discardableResult
    public func emptyResponse(queue: DispatchQueue? = nil, completionHandler: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                completionHandler(self.request, self.response, self.delegate.data, self.delegate.error)
            }
        }
        return self
    }
}


//
//  EproEndpoint.swift
//  watch-lib-tester WatchKit Extension
//
//  Created by Nathaniel Jacobs on 10/18/19.
//  Copyright © 2019 Nathaniel Jacobs. All rights reserved.
//

import Foundation

extension String: Error {}


/// API Manager that handles  API calls to epro backend
public enum EproEndpoint {
    
    /// Type of error while making an API call
    public enum ErrorType: Error {
        /// An HTTP URL error occured while executing the request
        case urlError(error: URLError.NormalizedError)
        
        /// response error
        case serverError(error: ResponseError)
    }
    
    
    /// Response error
    public enum ResponseError: Error {
        /// Response was completed, but failed to contain any data
        case noResponseData
        
        /// Response data was found, but did not contain expected JSON
        case couldNotDecodeJSON
        
        /// Response json was found, but failed to be decoded
        case couldNotDecodeValue(error: DecodingError)
        
        case serverError(serverError: ServerError)
    }
    
    public enum ServerError: Int, Error {
        /// Credentials are invalid
        case forbidden = 401
        
        case notFound = 404
    }
    
    /// Retrieves a list of studies a given user has access to
    public static func executeIngestionRequest(medistranoStage: MedistranoStage, user: String, password: String, subjectUuid: String, data: Data, filename: String, completionHandler: @escaping AWSS3TransferUtilityUploadCompletionHandlerBlock) {
        
        guard var components = URLComponents(url: medistranoStage.eproURL, resolvingAgainstBaseURL: false) else { return }
        
        components.path = "/api/v2/ingestion_endpoints"
        components.queryItems = [URLQueryItem(name: "subject_uuid", value: subjectUuid)]

        let requestURL = components.url!

        var request = URLRequest(url: requestURL)
        request.setBasicAuth(user: user, password: password)
        
        EproEndpoint.executeRequest(request: request) { (result) in
            switch result {
            case .success(let jsonObject):
                do {
                    let json = jsonObject as? [String: Any]
                    let endpoint_array = json!["ingestion_endpoints"] as? Array<Any>
                    let endpoint_json = endpoint_array!.first as? [String: Any]
                    let secret_access_key = endpoint_json!["secret_access_key"] as? String
                    let expiration = endpoint_json!["expiration"] as? String
                    let access_key_id = endpoint_json!["access_key_id"] as? String
                    let session_token = endpoint_json!["session_token"] as? String
                    let aws_region = endpoint_json!["aws_region"] as? String
                    let bucket_name = endpoint_json!["bucket_name"] as? String
                    let object_key_prefix = endpoint_json!["object_key_prefix"] as? String

                    return uploadtoSignedUrl(access_key_id: access_key_id!, secret_access_key:secret_access_key!, session_token:session_token!, expirationDateString: expiration!, file_path:object_key_prefix!, bucket_name: bucket_name!, aws_region: aws_region!, content_data: data, filename: filename, completionHandler: completionHandler)

                    }
            case .failure(let error):
                Logger.error(error.localizedDescription)
                completionHandler(AWSS3TransferUtilityUploadTask(),error)
            }
        }
    }
    
    public static func uploadtoSignedUrl(access_key_id:String,
                                             secret_access_key:String,
                                             session_token:String,
                                             expirationDateString:String,
                                             file_path: String,
                                             bucket_name:String,
                                             aws_region:String,
                                             content_data:Data,
                                             filename:String,
                                             completionHandler: @escaping AWSS3TransferUtilityUploadCompletionHandlerBlock) {

        let full_file_path = file_path + "/" + filename
                
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        
        let tokenExpirationDate = dateFormatter.date(from:expirationDateString)!
        
        let region = AWSRegionType.USEast1  //we currently only support us-east
        let credentialsProvider = AWSSTSCredentialsProvider(accessKey: access_key_id, secretKey: secret_access_key, sessionKey: session_token, expirationDate: tokenExpirationDate)
        let configuration = AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        let transferUtility = AWSS3TransferUtility.default()
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.setValue("AES256", forRequestHeader: "x-amz-server-side-encryption")

        transferUtility.uploadData(content_data, bucket: bucket_name, key: full_file_path, contentType: "text/plain", expression: expression, completionHandler: completionHandler).continueWith  { (task : AWSTask) -> AnyObject? in
                       if let error = task.error{
                        Logger.error("upload error!")
                        completionHandler(AWSS3TransferUtilityUploadTask(),error)
                       }else if let uploadTask = task.result{
                        Logger.info("Upload started...")
                       }
                       return nil
               }
    }
    
    /// URL Session used to make requests
    public static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        return URLSession(configuration: configuration)
    }()
    
    /// Authorization HTTP Header field value using an access token session
    public static var authorizationHeaderValue: String?
    
    /// API Version HTTP Header field value
    static let versionHeaderValue = "1.6.0"
    
    /// Authorization HTTP Header field key
    static let authorizationHeaderKey = "X-Authorization"
    
    /// Executes the URL request and calls the callback when finished
    private static func executeRequest(request: URLRequest, callback: @escaping ((Result<Any, EproEndpoint.ErrorType>) -> Void)) {
        if let url = request.url {
            Logger.info("[API]: \(url)")
        } else {
            Logger.info("[API]: --")
        }
        
        EproEndpoint.session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), let dataString = String(data: data, encoding: .utf8) {
                            Logger.info("[Response]: \(dataString)")
                          
                            callback(.success(json))
                        } else {
                            Logger.info("[Response]: nil")
                        }
                    } catch {
                        if data.isEmpty {
                            Logger.error("Expected to receive JSON, instead received 0 bytes of data")
                            callback(.failure(.serverError(error: .noResponseData)))
                        } else if let malformedJSONString = String(data: data, encoding: .utf8) {
                            Logger.error("Expected to receive JSON, instead received this:\n\n\(malformedJSONString)")
                            
                            callback(.failure(.serverError(error: .couldNotDecodeJSON)))
                        } else {
                            callback(.failure(.serverError(error: .couldNotDecodeJSON)))
                        }
                    }
                } else if let error = error {
                    Logger.error("[ErrorMessage]: \(error.localizedDescription)")
                    callback(.failure(.serverError(error: .noResponseData)))
                } else {
                    callback(.failure(.serverError(error: .noResponseData)))
                }
            }
        }).resume()
    }
}

extension URLRequest {
    /// Sets the 'Authorization' http header field using basic auth
    fileprivate mutating func setBasicAuth(user: String, password: String) {
        guard let basicAuthData = "\(user):\(password)".data(using: .utf8)?.base64EncodedString() else { return }
        setValue("Basic \(basicAuthData)", forHTTPHeaderField: "Authorization")
    }
}

extension URLError {
    /// Normalized type of error that can occur
    public enum NormalizedError: Error {
        /// No network connection found
        case noInternetConnection
        
        /// Server could not be found and does not exist
        case serverDoesNotExist
        
        /// An unknown error occurred
        case unknownError
    }
    
    /// `NormalizedError` and human readable description
    var errorInfo: (code: NormalizedError, description: String) {
        let statusCode: NormalizedError
        let description: String
        switch code {
        case .cancelled:
            description = "An asynchronous load has been canceled."
            statusCode = .unknownError
        case .badURL:
            description = "A malformed URL prevented a URL request from being initiated."
            statusCode = .unknownError
        case .timedOut:
            description = "An asynchronous operation timed out. URLSession sends this error to its delegate when the timeoutInterval of an NSURLRequest expires before a load can complete."
            statusCode = .noInternetConnection
        case .cannotFindHost:
            description = "The host name for a URL couldn’t be resolved."
            statusCode = .serverDoesNotExist
        case .cannotConnectToHost:
            description = "An attempt to connect to a host failed. This can occur when a host name resolves, but the host is down or may not be accepting connections on a certain port."
            statusCode = .unknownError
        case .networkConnectionLost:
            description = "A client or server connection was severed in the middle of an in-progress load."
            statusCode = .noInternetConnection
        case .httpTooManyRedirects:
            description = "A redirect loop was detected or the threshold for number of allowable redirects was exceeded."
            statusCode = .unknownError
        case .resourceUnavailable:
            description = "A requested resource couldn’t be retrieved. This error can indicate a file-not-found situation, or decoding problems that prevent data from being processed correctly."
            statusCode = .unknownError
        case .notConnectedToInternet:
            description = "A network resource was requested, but an internet connection has not been established and can’t be established automatically. This error occurs when the connection can’t be established a lack of connectivity or because the user chooses not to make a network connection automatically."
            statusCode = .noInternetConnection
        case .redirectToNonExistentLocation:
            description = "A redirect was specified by way of server response code, but the server didn’t accompany this code with a redirect URL."
            statusCode = .unknownError
        case .badServerResponse:
            description = "The URL Loading System received bad data from the server. This is equivalent to the “500 Server Error” message sent by HTTP servers."
            statusCode = .unknownError
        case .zeroByteResource:
            description = "A server reported that a URL has a non-zero content length, but terminated the network connection gracefully without sending any data."
            statusCode = .unknownError
        case .cannotDecodeRawData:
            description = "Content data received during a connection request couldn’t be decoded for a known content encoding."
            statusCode = .unknownError
        case .cannotDecodeContentData:
            description = "Content data received during a connection request had an unknown content encoding."
            statusCode = .unknownError
        case .cannotParseResponse:
            description = "A response to a connection request couldn’t be parsed."
            statusCode = .unknownError
        case .fileDoesNotExist:
            description = "The specified file doesn’t exist."
            statusCode = .unknownError
        case .noPermissionsToReadFile:
            description = "A resource couldn’t be read because of insufficient permissions."
            statusCode = .unknownError
        case .dataLengthExceedsMaximum:
            description = "The length of the resource data exceeded the maximum allowed."
            statusCode = .unknownError
        default:
            description = "Unknown error code '\(code)' encountered"
            statusCode = .unknownError
        }
        return (statusCode, description)
    }
}

//
//  NetworkManager.swift
//  WeatherForecast
//
//  Created by 김준건 on 2021/09/29.
//

import Foundation

struct NetworkManager {
    private var networkable: Networkable
    
    init(networkable: Networkable = NetworkModule()) {
        self.networkable = networkable
    }
    
    mutating func request<T: Decodable>(type: T,
                                        with route: Route,
                          queryItems: [URLQueryItem]?,
                          header: [String: String]? = nil,
                          bodyParameters: [String: Any]? = nil,
                          httpMethod: HTTPMethod,
                          requestType: URLRequestTask,
                          completionHandler: @escaping (Result<T, Error>) -> Void)
    {
        
        guard let urlRequest = requestType.buildRequest(route: route,
                                                        queryItems: queryItems,
                                                        header: header,
                                                        bodyParameters: bodyParameters,
                                                        httpMethod: httpMethod)
        else {
            completionHandler(.failure(NetworkError.invalidURL))
            return
        }
        networkable.runDataTask(type: type, request: urlRequest, completionHandler: completionHandler)
    }
}

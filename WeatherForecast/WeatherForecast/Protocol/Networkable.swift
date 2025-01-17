//
//  Networkable.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/01.
//

import Foundation

protocol Networkable {
    mutating func runDataTask(request: URLRequest, completionHandler: @escaping (Result<Data,Error>) -> Void)
}

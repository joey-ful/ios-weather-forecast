//
//  CommonWeatherForecast.swift
//  WeatherForecast
//
//  Created by 김준건 on 2021/09/28.
//

import Foundation

struct Weather: Decodable {
    let icon: String
}

struct Main: Decodable {
    let temperature: Double
    let minTemperature: Double
    let maxTemperature: Double
    
    enum CodingKeys: String, CodingKey {
        case temperature = "temp"
        case minTemperature = "temp_min"
        case maxTemperature = "temp_max"
    }
}


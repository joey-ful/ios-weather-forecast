//
//  FiveDayWeather.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/09/28.
//

import Foundation
import UIKit

struct FiveDayWeather: Decodable {
    let list: [List]
    let city: City
    
    struct List: Hashable, Decodable {
        let UnixForecastTime: Int
        let main: Main
        let weather: [Weather]
        let clouds: Clouds
        let wind: Wind
        let rain: Rain?
        let sys: Sys
        let ISOForecastTime: String
        
        enum CodingKeys: String, CodingKey {
            case main, weather, clouds, wind, rain, sys
            case UnixForecastTime = "dt"
            case ISOForecastTime = "dt_txt"
        }
        
        static func == (lhs: FiveDayWeather.List, rhs: FiveDayWeather.List) -> Bool {
            lhs.UnixForecastTime == rhs.UnixForecastTime
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(UnixForecastTime)
        }
        
    }
    
    struct City: Decodable {
        let id: Int
        let name: String
        let coordinates: Coordinates
        let country: String
        
        enum CodingKeys: String, CodingKey {
            case id, name, country
            case coordinates = "coord"
        }
    }
    
    struct Rain: Decodable {
        let threeHoursVolume: Double
        
        enum CodingKeys: String, CodingKey {
            case threeHoursVolume = "3h"
        }
    }
    
    struct Sys: Decodable {
        let partOfDay: String
        
        enum CodingKeys: String, CodingKey {
            case partOfDay = "pod"
        }
    }
    
    struct Coordinates: Decodable {
        let longitude: Double
        let latitude: Double
        
        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitude = "lat"
        }
    }
    
    struct Clouds: Decodable {
        let all: Int
    }
    
    struct Wind: Decodable {
        let speed: Double
        let degree: Double
        let gust: Double?
        
        enum CodingKeys: String, CodingKey {
            case speed, gust
            case degree = "deg"
        }
    }
    
    struct Weather: Decodable {
        let icon: String
    }
    
    struct Main: Decodable {
        let temperature: Double
        let minTemperature: Double
        let maxTemperature: Double
        let pressure: Int
        let humidity: Int
        let seaLevel: Int?
        let groundLevel: Int?
        
        enum CodingKeys: String, CodingKey {
            case pressure, humidity, seaLevel
            case temperature = "temp"
            case minTemperature = "temp_min"
            case maxTemperature = "temp_max"
            case groundLevel = "grnd_level"
        }
    }
    
    
}



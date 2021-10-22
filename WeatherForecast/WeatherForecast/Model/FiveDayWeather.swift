//
//  FiveDayWeather.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/09/28.
//

import Foundation

struct FiveDayWeather: Decodable, WeatherModel {
    let list: [List]
    
    struct List: Hashable, Decodable {
        let UnixForecastTime: Int
        let main: Main
        let weather: [Weather]
        
        enum CodingKeys: String, CodingKey {
            case main, weather
            case UnixForecastTime = "dt"
        }
        
        static func == (lhs: FiveDayWeather.List, rhs: FiveDayWeather.List) -> Bool {
            lhs.UnixForecastTime == rhs.UnixForecastTime
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(UnixForecastTime)
        }
    }
}



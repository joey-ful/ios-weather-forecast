//
//  CurrentWeather.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/09/28.
//

import Foundation

struct CurrentWeather: Decodable, WeatherModel {
    let weather: [Weather]
    let main: Main
}

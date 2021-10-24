//
//  WeatherHeader.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/14.
//

import Foundation
import UIKit.UIImage

struct WeatherHeader: Hashable {
    let address: String
    let maxTemperature: Double?
    let minTemperature: Double?
    let temperature: Double?
    let image: UIImage?
    
    init(address: String,
         minTemperature: Double,
         maxTemperature: Double,
         temperature: Double,
         weatherIcon: UIImage)
    {
        self.address = address
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.temperature = temperature
        self.image = weatherIcon
    }
    
    init() {
        self.address = " "
        self.maxTemperature = nil
        self.minTemperature = nil
        self.temperature = nil
        self.image = nil
    }
}

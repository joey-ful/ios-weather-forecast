//
//  WeatherForecast - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

protocol WeatherModel: Decodable {}
extension CurrentWeather: WeatherModel {}
extension FiveDayWeather: WeatherModel {}

class ViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var currentWeather: CurrentWeather?
    private var fiveDayWeather: FiveDayWeather?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        // Do any additional setup after loading the view.
    }

    private func initData() {
        guard let location = locationManager.getGeographicCoordinates() else {
            return
        }
        
        let address = getAddress(of: location)
//        getWeatherData(of: location, route: .current)
//        getWeatherData(of: location, route: .fiveDay)
//        getWeatherData(type: CurrentWeather, of: location, route: .current)
//        getWeatherData(type: FiveDayWeather, of: location, route: .fiveDay)
    }
    
    private func getAddress(of location: CLLocation?) -> [Address: String] {
        var address = [Address: String]()
        locationManager.getAddress(of: location) { result in
            switch result {
            case .success(let addressElements):
                address = addressElements
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
        return address
    }
    
//    private func getWeatherData(of location: CLLocation, route: WeatherForecastRoute) {
//        let queryItems = WeatherForecastRoute.createParameters(latitude: location.coordinate.latitude,
//                                                               longitude: location.coordinate.longitude)
//
//        networkManager.request(with: route,
//                               queryItems: queryItems,
//                               httpMethod: .get,
//                               requestType: .requestWithQueryItems) { result in
//            switch result {
//            case .success(let data):
//                self.extract(data: data, period: route)
//            case .failure(let networkError):
//                assertionFailure(networkError.localizedDescription)
//            }
//        }
//    }
//
//    private func extract(data: Data, period: WeatherForecastRoute) {
//        switch period {
//        case .current:
//            let parsedData = data.parse(to: CurrentWeather.self)
//            switch parsedData {
//            case .success(let currentWeatherData):
//                self.currentWeather = currentWeatherData
//            case .failure(let parsingError):
//                assertionFailure(parsingError.localizedDescription)
//            }
//        case .fiveDay:
//            let parsedData = data.parse(to: FiveDayWeather.self)
//            switch parsedData {
//            case .success(let fiveDayWeatherData):
//                self.fiveDayWeather = fiveDayWeatherData
//            case .failure(let parsingError):
//                assertionFailure(parsingError.localizedDescription)
//            }
//        }
//    }
    
    private func getWeatherData<WeatherModel: Decodable>(type: WeatherModel, of location: CLLocation, route: WeatherForecastRoute) {
        let queryItems = WeatherForecastRoute.createParameters(latitude: location.coordinate.latitude,
                                                               longitude: location.coordinate.longitude)

        networkManager.request(type: type,
                               with: route,
                               queryItems: queryItems,
                               httpMethod: .get,
                               requestType: .requestWithQueryItems) { (result: Result<WeatherModel, Error>) in
            switch result {
            case .success(let data):
                if let weatherData = data as? CurrentWeather {
                    self.currentWeather = weatherData
                } else if let weatherData = data as? FiveDayWeather {
                    self.fiveDayWeather = weatherData
                }
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
 
}

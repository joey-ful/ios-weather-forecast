//
//  URLAlertController+Extension.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/15.
//

import UIKit

extension UIAlertController {
    static func makeValidLocationAlert() -> UIAlertController {
        
        let alert = UIAlertController(title: WeatherConstants.changeLocation.text,
                                      message: "Please enter the coordinates".localized(),
                                      preferredStyle: .alert)
        
        alert.addTextField { textfiled in
            textfiled.keyboardType = .numbersAndPunctuation
            textfiled.placeholder = WeatherConstants.latitude.text
        }
        alert.addTextField { textfiled in
            textfiled.keyboardType = .numbersAndPunctuation
            textfiled.placeholder = WeatherConstants.longitude.text
        }
        
        let changeAction = UIAlertAction(title: WeatherConstants.change.text,
                                         style: .default) { [weak alert] _ in
            guard let longitude = alert?.textFields?[1].text, let latitude = alert?.textFields?[0].text else {
                return
            }
            
            let newLocation = Coordinates(latitude: Double(latitude), longitude: Double(longitude))
            NotificationCenter.default.post(name: .changeLocationNotification,
                                            object: nil,
                                            userInfo: ["newLocation" : newLocation])
        }
        
        let resetToCurrentLocationAction = UIAlertAction(title: "Reset to Current Location".localized(),
                                                         style: .default) { _ in
            let newLocation = Coordinates(latitude: nil, longitude: nil)
            NotificationCenter.default.post(name: .changeLocationNotification,
                                            object: nil,
                                            userInfo: ["newLocation" : newLocation])
        }
        
        let cancelAction = UIAlertAction(title: WeatherConstants.cancel.text, style: .cancel)
        
        let actions = [changeAction, resetToCurrentLocationAction, cancelAction]
        for action in actions {
            alert.addAction(action)
        }
        
        return alert
    }
    
    static func makeInvalidLocationAlert() -> UIAlertController {
        
        let alert = UIAlertController(
            title: WeatherConstants.changeLocation.text,
            message: "Please enter the coordinates of where you would like to get the weather of."
                .localized(),
            preferredStyle: .alert
        )
        
        alert.addTextField { textfiled in
            textfiled.keyboardType = .numbersAndPunctuation
            textfiled.placeholder = WeatherConstants.latitude.text
        }
        
        alert.addTextField { textfiled in
            textfiled.keyboardType = .numbersAndPunctuation
            textfiled.placeholder = WeatherConstants.longitude.text
        }
        
        let changeAction = UIAlertAction(title: WeatherConstants.change.text,
                                         style: .default) { [weak alert] _ in
            
            guard let longitude = alert?.textFields?[1].text,
                  let latitude = alert?.textFields?[0].text,
                  let longitudeNumber = Double(longitude),
                  let latitudeNumber = Double(latitude) else {
                return
            }
            
            let newLocation = Coordinates(latitude: latitudeNumber, longitude: longitudeNumber)
    
            NotificationCenter.default.post(name: .changeLocationNotification,
                                            object: nil,
                                            userInfo: ["newLocation" : newLocation])
        }
        
        let cancelAction = UIAlertAction(title: WeatherConstants.cancel.text, style: .cancel)
        
        let actions = [cancelAction, changeAction]
        actions.forEach { alert.addAction($0) }
        
        return alert
    }
}

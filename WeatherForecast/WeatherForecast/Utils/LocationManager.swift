//
//  LocationManager.swift
//  WeatherForecast
//
//  Created by 김준건 on 2021/10/05.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
    }
    
    func getGeographicCoordinates() -> CLLocation? {
        var status: CLAuthorizationStatus
        status = manager.authorizationStatus
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
            guard let location = manager.location else { return nil }
            return location
        default:
            return nil
        }
    }
    
    func getAddress(of location: CLLocation?,
                    completionHandler: @escaping (Result<Address, Error>) -> Void)
    {
        guard let validLocation = location else { return }
        
        let converter = CLGeocoder()
        converter.reverseGeocodeLocation(validLocation, preferredLocale: Locale.current)
        { (placemarks, error) in
            
            if let error = error {
                completionHandler(.failure(error))
            }
            
            guard let placemark = placemarks?.first,
                  let city = placemark.administrativeArea,
                  let street1 = placemark.locality
            else {
                completionHandler(.success(Address()))
                return
            }
            
            let address = Address(city: city, stree1: street1)
            
            completionHandler(.success(address))
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        return

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

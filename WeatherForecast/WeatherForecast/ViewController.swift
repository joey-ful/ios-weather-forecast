//
//  WeatherForecast - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

class ViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var currentWeather: CurrentWeather?
    private var fiveDayWeather: FiveDayWeather?
    
    private var collecionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private let fiveDayWeatherCellIdentifier = "fiveDay"
    private var dataSource: UICollectionViewDiffableDataSource<Section, FiveDayWeather.List>?
    private var snapshot: NSDiffableDataSourceSnapshot<Section, FiveDayWeather.List>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initData()
        makeDataSource()
        makeSnapshot()
        setupCollectionView()
    }

    private func initData() {
        guard let location = locationManager.getGeographicCoordinates() else {
            return
        }
        
        let address = getAddress(of: location)
        getWeatherData(of: location, route: .current)
        getWeatherData(of: location, route: .fiveDay)
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
    
    private func getWeatherData(of location: CLLocation, route: WeatherForecastRoute) {
        let queryItems = WeatherForecastRoute.createParameters(latitude: location.coordinate.latitude,
                                                               longitude: location.coordinate.longitude)
        
        networkManager.request(with: route,
                               queryItems: queryItems,
                               httpMethod: .get,
                               requestType: .requestWithQueryItems) { result in
            switch result {
            case .success(let data):
                self.extract(data: data, period: route)
            case .failure(let networkError):
                assertionFailure(networkError.localizedDescription)
            }
        }
    }
    
    private func extract(data: Data, period: WeatherForecastRoute) {
        switch period {
        case .current:
            let parsedData = data.parse(to: CurrentWeather.self)
            switch parsedData {
            case .success(let currentWeatherData):
                self.currentWeather = currentWeatherData
            case .failure(let parsingError):
                assertionFailure(parsingError.localizedDescription)
            }
        case .fiveDay:
            let parsedData = data.parse(to: FiveDayWeather.self)
            switch parsedData {
            case .success(let fiveDayWeatherData):
                self.fiveDayWeather = fiveDayWeatherData
            case .failure(let parsingError):
                assertionFailure(parsingError.localizedDescription)
            }
        }
    }
    
    private func makeDataSource() {
        let dataSource = UICollectionViewDiffableDataSource<Section, FiveDayWeather.List>(collectionView: collecionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.fiveDayWeatherCellIdentifier, for: indexPath)
            return cell
        }
        self.dataSource = dataSource
    }

    private func makeSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FiveDayWeather.List>()
        snapshot.appendSections([.fiveDayWeather])
        guard let data = fiveDayWeather?.list else { return }
        snapshot.appendItems(data, toSection: .fiveDayWeather)
        self.snapshot = snapshot
        dataSource?.apply(snapshot)
    }
    
    private func setupCollectionView() {
        collecionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collecionView)
        NSLayoutConstraint.activate([
            collecionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collecionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collecionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collecionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        
        if #available(iOS 14.0, *) {
            let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            collecionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: configuration)
        } else {
            let layout = UICollectionViewFlowLayout()
            let contentWidth = collecionView.bounds.width
            let cellWidth = contentWidth
            let cellHeight:CGFloat = 70
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            collecionView.collectionViewLayout = layout
        }
    }
}

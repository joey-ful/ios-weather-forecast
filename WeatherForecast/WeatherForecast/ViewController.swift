//
//  WeatherForecast - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

typealias DataSource = UICollectionViewDiffableDataSource<WeatherHeader, FiveDayWeather.List>

class ViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var imageManager = ImageManager()
    private var address = Address()
    private var currentWeatherHeader = WeatherHeader()
    private var fiveDayWeathers: [FiveDayWeather.List] = []
    private var collecionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    
    private var dataSource: DataSource?
    private var snapshot: NSDiffableDataSourceSnapshot<WeatherHeader, FiveDayWeather.List>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        collecionView.backgroundColor = .white
        setupCollectionView()
        initData()
        configureRefreshControl()
    }
    
    private func initData() {
        guard let location = locationManager.getGeographicCoordinates() else {
            return
        }
        
        getAddress(of: location) { address in
            self.address = address
            self.getWeatherData(of: location, route: .current)
            self.getWeatherData(of: location, route: .fiveDay)
        }
    }
    
    private func getAddress(of location: CLLocation?, completionHandler: @escaping (Address) -> Void) {
        locationManager.getAddress(of: location) { result in
            switch result {
            case .success(let addressElements):
                completionHandler(addressElements)
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
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
            filter(parsedData: parsedData)
        case .fiveDay:
            let parsedData = data.parse(to: FiveDayWeather.self)
            filter(parsedData: parsedData)
        }
    }
    
    func filter<T: WeatherModel>(parsedData: Result<T, ParsingError>) {
        switch parsedData {
        case .success(let data):
            if let currentWeatherData = data as? CurrentWeather {
                imageManager.loadImage(with: imageURL(of: currentWeatherData.weather[0].icon)) { result in
                    switch result {
                    case .success(let image):
                        self.currentWeatherHeader = WeatherHeader(
                            address: self.address.combined,
                            minTemperature: currentWeatherData.main.minTemperature.description,
                            maxTemperature: currentWeatherData.main.maxTemperature.description,
                            temperature: currentWeatherData.main.temperature.description,
                            weatherIcon: image
                        )
                    case .failure(let error):
                        assertionFailure(error.localizedDescription)
                    }
                }
            } else if let fiveDayWeatherData = data as? FiveDayWeather {
                self.fiveDayWeathers = fiveDayWeatherData.list
                makeSnapshot()
            }
        case .failure(let parsingError):
            assertionFailure(parsingError.localizedDescription)
        }
    }
    
    private func imageURL(of icon: String) -> String {
        return "https://openweathermap.org/img/w/\(icon).png"
    }
}

extension ViewController {
    
    private func makeSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<WeatherHeader, FiveDayWeather.List>()
        snapshot.appendSections([currentWeatherHeader])
        snapshot.appendItems(fiveDayWeathers, toSection: currentWeatherHeader)
        self.snapshot = snapshot
        dataSource?.apply(snapshot)
    }
    
    private func setupCollectionView() {
        setCollectionViewLayoutConfiguration()
        setAutoLayoutCollectionView()
        registerCell()
        registerHeader()
    }
    
    private func setCollectionViewLayoutConfiguration() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collecionView.collectionViewLayout = layout
    }
    
    private func setAutoLayoutCollectionView() {
        collecionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collecionView)
        NSLayoutConstraint.activate([
            collecionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collecionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collecionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collecionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func registerCell() {
        let cellRegistration = UICollectionView.CellRegistration
        <WeatherForecastCustomCell, FiveDayWeather.List> { (cell, indexPath, fiveDayWeatherItem) in
            let iconID = fiveDayWeatherItem.weather[0].icon
            let currentImageURL = self.imageURL(of: iconID)
            cell.urlString = currentImageURL
            self.imageManager.loadImage(with: currentImageURL) { result in
                if currentImageURL == cell.urlString {
                    switch result {
                    case .success(let image):
                        cell.configure(image: image)
                    case .failure:
                        cell.configure(image: UIImage(systemName: "photo"))
                    }
                }
            }
            cell.configure(date: fiveDayWeatherItem.UnixForecastTime,
                           temparature: fiveDayWeatherItem.main.temperature)
        }
        
        dataSource = DataSource(collectionView: collecionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: itemIdentifier)
        }
    }
    
    private func registerHeader() {
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <WeatherHeaderView>(elementKind: UICollectionView.elementKindSectionHeader)
        { headerView, elementKind, indexPath in
            let headerItem = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section]
            headerView.configureContents(from: headerItem)
        }
        
        dataSource?.supplementaryViewProvider = { (collecionView, elementKind, indexpath) in
            return collecionView.dequeueConfiguredReusableSupplementary(using: headerRegistration,
                                                                              for: indexpath)
        }
    }
}

extension ViewController {
    private func configureRefreshControl() {
        collecionView.refreshControl = UIRefreshControl()
        collecionView.refreshControl?.tintColor = .systemRed
        collecionView.refreshControl?.addTarget(self,
                                                action: #selector(handleRefreshControl),
                                                for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        initData()
        self.collecionView.refreshControl?.endRefreshing()
    }
}


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
    private var address: [Address: String] = [:]
    private var fiveDayWeather = WeatherHeader(address: "주소", minTemperature: "최저기온", maxTemperature: "최고기온", temperature: "온도", weatherIcon: UIImage(systemName: "photo")!)
    
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
        
        address = getAddress(of: location)
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
                imageManager.loadImage(with: "https://openweathermap.org/img/w/\(currentWeatherData.weather[0].icon).png") { result in
                    switch result {
                    case .success(let image):
                        self.fiveDayWeather = WeatherHeader(address: "주소", minTemperature: currentWeatherData.main.minTemperature.description, maxTemperature: currentWeatherData.main.maxTemperature.description, temperature: currentWeatherData.main.temperature.description, weatherIcon: image)
                    case .failure(let error):
                        assertionFailure(error.localizedDescription)
                    }
                }
                
            case .failure(let parsingError):
                assertionFailure(parsingError.localizedDescription)
            }
        case .fiveDay:
            let parsedData = data.parse(to: FiveDayWeather.self)
            switch parsedData {
            case .success(let fiveDayWeatherData):
                self.fiveDayWeather.weathers = fiveDayWeatherData.list
                makeSnapshot()
            case .failure(let parsingError):
                assertionFailure(parsingError.localizedDescription)
            }
        }
    }
    
    private func makeSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<WeatherHeader, FiveDayWeather.List>()
        snapshot.appendSections([fiveDayWeather])
        snapshot.appendItems(fiveDayWeather.weathers, toSection: fiveDayWeather)
        self.snapshot = snapshot
        dataSource?.apply(snapshot)
    }
    
    private func setupCollectionView() {
        configureCollectionViewLayout()
        layoutCollecionView()
        registerCell()
//        registerHeader()
    }
    
    private func configureCollectionViewLayout() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collecionView.collectionViewLayout = layout
    }
    
    private func layoutCollecionView() {
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
        let cellRegistration = UICollectionView.CellRegistration<WeatherForecastCustomCell, FiveDayWeather.List> { (cell, indexPath, fiveDayWeatherItem) in
            let dataTask = self.imageManager.loadImage(with: "https://openweathermap.org/img/w/\(fiveDayWeatherItem.weather[0].icon).png") { result in
                switch result {
                case .success(let image):
                    cell.configure(image: image)
                case .failure:
                    cell.configure(image: UIImage(systemName: "photo"))
                }
            }
            cell.configure(date: fiveDayWeatherItem.UnixForecastTime, temparature: fiveDayWeatherItem.main.temperature, dataTask: dataTask)
        }
        let dataSource = DataSource(collectionView: collecionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<WeatherHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { headerView, elementKind, indexPath in
            let headerItem = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section]
            headerView.configureContents(from: headerItem)
        }
        dataSource.supplementaryViewProvider = { (collecionView, elementKind, indexpath) in
            let header = collecionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexpath)
            print(header)
            return header
        }
        self.dataSource = dataSource
    }
    
    private func registerHeader() {
        let headerRegistration = UICollectionView.SupplementaryRegistration<WeatherHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { headerView, elementKind, indexPath in
            let headerItem = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section]
            headerView.configureContents(from: headerItem)
        }
        dataSource?.supplementaryViewProvider = { (collecionView, elementKind, indexpath) in
            let header = collecionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexpath)
            print(header)
            return header
        }
    }
    
    func configureRefreshControl() {
        collecionView.refreshControl = UIRefreshControl()
        collecionView.refreshControl?.tintColor = .systemRed
        collecionView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        initData()
        self.collecionView.refreshControl?.endRefreshing()
    }
}

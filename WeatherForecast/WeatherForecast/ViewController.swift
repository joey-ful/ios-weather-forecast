//
//  WeatherForecast - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

typealias DataSource = UICollectionViewDiffableDataSource<HeaderItem, FiveDayWeather.List>

class ViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var imageManager = ImageManager()
    private var currentWeather: CurrentWeather?
    private var fiveDayWeather: HeaderItem = HeaderItem(address: "서울시 어쩌구",
                                                        minTemperature: "최저기온",
                                                        maxTemperature: "최고기온",
                                                        temperature: "온도" ,
                                                        weatherIcon: UIImage(systemName: "photo")!,
                                                        weathers: [])
    
    private var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    
    private var dataSource: DataSource?
    private var snapshot: NSDiffableDataSourceSnapshot<HeaderItem, FiveDayWeather.List>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        view.backgroundColor = .white
        setupCollectionView()
        registerCellAndHeader()
        initData()
        configureRefreshControl()
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
                self.fiveDayWeather.weathers = fiveDayWeatherData.list
                makeSnapshot()
            case .failure(let parsingError):
                assertionFailure(parsingError.localizedDescription)
            }
        }
    }
}

extension ViewController {
    private func makeSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<HeaderItem, FiveDayWeather.List>()
        snapshot.appendSections([fiveDayWeather])
        snapshot.appendItems(fiveDayWeather.weathers, toSection: fiveDayWeather)
        self.dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func setupCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = .supplementary

        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func registerCellAndHeader() {
        let cellRegistration = UICollectionView.CellRegistration
        <WeatherForecastCustomCell, FiveDayWeather.List> { (cell, indexPath, weatherItem) in
            cell.dateLabel.text = weatherItem.UnixForecastTime.description + "날씨"
            cell.temperatureLabel.text = weatherItem.main.temperature.description + "온도"
            
            self.imageManager.loadImage(with: "https://openweathermap.org/img/w/\(weatherItem.weather[0].icon).png", completionHandler: { (result) in
                switch result {
                case .success(let image):
                    cell.weatherImage.image = image
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                }
            })
        }

        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, weatherItem in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: weatherItem)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <WeatherHeaderView>(elementKind: UICollectionView.elementKindSectionHeader)
        { [unowned self] (headerView, elementKind, indexPath) in
            let headerItem = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section]
            headerView.addressLabel.text = headerItem?.address
            headerView.maxTemperatureLabel.text = headerItem?.maxTemperature
            headerView.minTemperatureLabel.text = headerItem?.minTemperature
            headerView.temperatureLabel.text = headerItem?.temperature
            headerView.weatherIcon.image = headerItem?.image
        }
        
        dataSource.supplementaryViewProvider = { (collectionView, elementKind, indexPath) in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration,
                                                                         for: indexPath)
        }
        
        self.dataSource = dataSource
    }
}

extension ViewController {
    func configureRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.tintColor = .systemRed
        collectionView.refreshControl?.addTarget(self,
                                                action: #selector(handleRefreshControl),
                                                for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        initData()
        self.collectionView.refreshControl?.endRefreshing()
    }
}

struct HeaderItem: Hashable {
    let address: String
    let maxTemperature: String
    let minTemperature: String
    let temperature: String
    let image: UIImage
    var weathers: [FiveDayWeather.List]
    
    init(address: String,
         minTemperature: String,
         maxTemperature: String,
         temperature: String,
         weatherIcon: UIImage,
         weathers: [FiveDayWeather.List] = [])
    {
        self.address = address
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.temperature = temperature
        self.image = weatherIcon
        self.weathers = weathers
    }
}

//
//  WeatherForecast - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

typealias DataSource = UICollectionViewDiffableDataSource<WeatherHeader, FiveDayWeather.List>

final class WeatherForecastViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var imageManager = ImageManager()
    private var address = Address()
    private var currentWeatherHeader = WeatherHeader()
    private var fiveDayWeathers: [FiveDayWeather.List] = []
    private var collecionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private lazy var alert = initAlert()
    private let downloadDataGroup = DispatchGroup()
    private var dataSource: DataSource?
    private var snapshot: NSDiffableDataSourceSnapshot<WeatherHeader, FiveDayWeather.List>?
    private var longitude: Double?
    private var latitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackgroundImage()
        setupCollectionView()
        initData()
        configureRefreshControl()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLocation),
                                               name: .changeLocationNotification, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        view.subviews[0].frame.size = CGSize(width: size.width, height: size.height)
    }
    
    private func setBackgroundImage() {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        if let image = UIImage(named: "dark") {
            backgroundImage.image = image
        }
        backgroundImage.contentMode = UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImage, at: 0)
    }
    
    private func initAlert() -> UIAlertController {
        if address.combined == " " {
            return UIAlertController.makeInvalidLocationAlert()
        } else {
            return UIAlertController.makeValidLocationAlert()
        }
    }
    
    @objc private func initData() {
        var currentLocation: CLLocation?
        
        if let latitude = latitude, let longitude = longitude {
            currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        } else {
            currentLocation = locationManager.getGeographicCoordinates()
        }
        
        guard let location = currentLocation else {
            currentWeatherHeader = WeatherHeader()
            fiveDayWeathers = []
            address = Address()
            makeSnapshot()
            return
        }
        
        getAddress(of: location) { address in
            self.address = address
            self.alert = self.initAlert()
            self.getWeatherData(of: location, route: .current)
            self.getWeatherData(of: location, route: .fiveDay)
            self.downloadDataGroup.notify(queue: DispatchQueue.main) {
                self.makeSnapshot()
            }
        }
    }
    
    @objc private func updateLocation(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String:Coordinates],
              let newLocation = userInfo["newLocation"] else {
            return
        }
        latitude = newLocation.latitude
        longitude = newLocation.longitude
        initData()
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
        
        DispatchQueue.global().async {
            self.downloadDataGroup.enter()
            self.networkManager.request(with: route,
                                        queryItems: queryItems,
                                        httpMethod: .get,
                                        requestType: .requestWithQueryItems) { result in
                switch result {
                case .success(let data):
                    self.extract(data: data, period: route)
                case .failure(let networkError):
                    if networkError.localizedDescription != "cancelled" {
                        assertionFailure(networkError.localizedDescription)
                    }
                }
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
    
    private func filter<T: WeatherModel>(parsedData: Result<T, ParsingError>) {
        switch parsedData {
        case .success(let data):
            if let currentWeatherData = data as? CurrentWeather {
                imageManager.loadImage(with: imageURL(of: currentWeatherData.weather[0].icon)) { result in
                    switch result {
                    case .success(let image):
                        self.currentWeatherHeader = WeatherHeader(
                            address: self.address.combined,
                            minTemperature: currentWeatherData.main.minTemperature,
                            maxTemperature: currentWeatherData.main.maxTemperature,
                            temperature: currentWeatherData.main.temperature,
                            weatherIcon: image
                        )
                    case .failure(let error):
                        assertionFailure(error.localizedDescription)
                    }
                    self.downloadDataGroup.leave()
                }
            } else if let fiveDayWeatherData = data as? FiveDayWeather {
                self.fiveDayWeathers = fiveDayWeatherData.list
                downloadDataGroup.leave()
            }
        case .failure(let parsingError):
            assertionFailure(parsingError.localizedDescription)
        }
    }
    
    private func imageURL(of icon: String) -> String {
        return "https://openweathermap.org/img/w/\(icon).png"
    }
}

extension WeatherForecastViewController {
    
    private func makeSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<WeatherHeader, FiveDayWeather.List>()
        snapshot.appendSections([currentWeatherHeader])
        snapshot.appendItems(fiveDayWeathers, toSection: currentWeatherHeader)
        self.snapshot = snapshot
        dataSource?.apply(snapshot)
    }
    
    private func setupCollectionView() {
        collecionView.backgroundColor = .clear
        setCollectionViewLayoutConfiguration()
        setAutoLayoutCollectionView()
        registerCell()
        registerHeader()
    }
    
    private func setCollectionViewLayoutConfiguration() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = .clear
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
        <WeatherForecastCustomCell, FiveDayWeather.List> { [weak self] (cell, indexPath, fiveDayWeatherItem) in
            let iconID = fiveDayWeatherItem.weather[0].icon
            
            if let currentImageURL = self?.imageURL(of: iconID) {
                cell.urlString = currentImageURL
                self?.imageManager.loadImage(with: currentImageURL) { result in
                    if currentImageURL == cell.urlString {
                        switch result {
                        case .success(let image):
                            cell.configure(image: image)
                        case .failure:
                            cell.configure(image: UIImage(systemName: "photo"))
                        }
                    }
                }
            }
            
            cell.configure(date: fiveDayWeatherItem.UnixForecastTime,
                           temperature: fiveDayWeatherItem.main.temperature)
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
        { [weak self] headerView, elementKind, indexPath in
            let headerItem = self?.dataSource?.snapshot().sectionIdentifiers[indexPath.section]
            
            let buttonType: LocationSelectButtonType = self?.address.combined == " " ? .invalid : .valid
            headerView.configureLocationSelectButton(button: buttonType) {
                guard let alert = self?.alert else { return }
                self?.present(alert, animated: true, completion: nil)
            }
            headerView.configureContents(from: headerItem)
        }
        
        dataSource?.supplementaryViewProvider = { (collecionView, elementKind, indexpath) in
            return collecionView.dequeueConfiguredReusableSupplementary(using: headerRegistration,
                                                                        for: indexpath)
        }
    }
}

extension WeatherForecastViewController {
    private func configureRefreshControl() {
        collecionView.refreshControl = UIRefreshControl()
        collecionView.refreshControl?.tintColor = .systemRed
        collecionView.refreshControl?.addTarget(self,
                                                action: #selector(handleRefreshControl),
                                                for: .valueChanged)
    }
    
    @objc private func handleRefreshControl() {
        initData()
        self.collecionView.refreshControl?.endRefreshing()
    }
}


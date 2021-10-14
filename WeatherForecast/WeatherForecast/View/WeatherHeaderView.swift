//
//  WeatherHeaderView.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/14.
//

import UIKit

class WeatherHeaderView: UICollectionReusableView {
    var addressLabel = UILabel()
    var maxTemperatureLabel = UILabel()
    var minTemperatureLabel = UILabel()
    var temperatureLabel = UILabel()
    var weatherIcon = UIImageView()
    
    lazy var maxMinStackView: UIStackView = {
        var maxMinStackView = UIStackView(arrangedSubviews: [minTemperatureLabel, maxTemperatureLabel])
        maxMinStackView.translatesAutoresizingMaskIntoConstraints = false
        maxMinStackView.alignment = .fill
        maxMinStackView.distribution = .fill
        maxMinStackView.axis = .horizontal
        maxMinStackView.spacing = 5
        return maxMinStackView
    }()

    lazy var infoStackView: UIStackView = {
        var infoStackView = UIStackView(arrangedSubviews: [addressLabel, maxMinStackView, temperatureLabel])
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.alignment = .leading
        infoStackView.distribution = .fill
        infoStackView.axis = .vertical
        infoStackView.spacing = 5
        return infoStackView
    }()
    
    lazy var currentWeatherStackView: UIStackView = {
        var currentWeatherStackView = UIStackView(arrangedSubviews: [weatherIcon, infoStackView])
        currentWeatherStackView.translatesAutoresizingMaskIntoConstraints = false
        currentWeatherStackView.alignment = .center
        currentWeatherStackView.distribution = .fillProportionally
        currentWeatherStackView.axis = .horizontal
        currentWeatherStackView.spacing = 5
        addSubview(currentWeatherStackView)
        return currentWeatherStackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayoutForCurrentWeatherStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayoutForCurrentWeatherStackView() {
//        NSLayoutConstraint.activate([
//            currentWeatherStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 5),
//            currentWeatherStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
//            currentWeatherStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
//            currentWeatherStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
//        ])
        addSubview(temperatureLabel)
        NSLayoutConstraint.activate([
            temperatureLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 5),
            temperatureLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            temperatureLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            temperatureLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
    }
    
    private func makeLabel(text: String?, font: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: font)
        
        return label
    }
    
    func configureContents(from currentWeather: WeatherHeader?) {
        addressLabel = makeLabel(text: currentWeather?.address, font: .title3)
        maxTemperatureLabel = makeLabel(text: currentWeather?.maxTemperature, font: .title3)
        minTemperatureLabel = makeLabel(text: currentWeather?.minTemperature, font: .title3)
        temperatureLabel = makeLabel(text: currentWeather?.temperature, font: .title2)
        weatherIcon = UIImageView(image: currentWeather?.image)
    }
}

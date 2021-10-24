//
//  WeatherHeaderView.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/14.
//

import UIKit

final class WeatherHeaderView: UICollectionReusableView {
    private lazy var addressLabel: UILabel = {
        let adressLabel = UILabel.makeLabel(font: .subheadline)
        addSubview(adressLabel)
        NSLayoutConstraint.activate([
            adressLabel.leadingAnchor.constraint(equalTo: infoStackView.leadingAnchor),
            adressLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5)
        ])
        return adressLabel
    }()
    private var maxTemperatureLabel = UILabel.makeLabel(font: .callout)
    private var minTemperatureLabel = UILabel.makeLabel(font: .callout)
    private var temperatureLabel = UILabel.makeLabel(font: .title1)
    private var presentLocationSelector: (()-> Void)?
    private lazy var locationSelectButton: UIButton = {
        let locationSelectButton = UIButton()
        locationSelectButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        locationSelectButton.setTitleColor(.systemGray6, for: .normal)
        locationSelectButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        locationSelectButton.addAction(UIAction(handler: { [weak self] _ in
            self?.presentLocationSelector?()
        }), for: .touchUpInside)
        
        addSubview(locationSelectButton)
        locationSelectButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationSelectButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                           constant: -5),
            locationSelectButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        ])
        
        return locationSelectButton
    }()
    
    private var weatherIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        return imageView
    }()
    
    private lazy var maxMinStackView: UIStackView = {
        var maxMinStackView = UIStackView(arrangedSubviews: [minTemperatureLabel, maxTemperatureLabel])
        maxMinStackView.translatesAutoresizingMaskIntoConstraints = false
        maxMinStackView.alignment = .fill
        maxMinStackView.distribution = .fill
        maxMinStackView.axis = .horizontal
        maxMinStackView.spacing = 5
        return maxMinStackView
    }()
    
    private lazy var infoStackView: UIStackView = {
        var infoStackView = UIStackView(arrangedSubviews: [maxMinStackView, temperatureLabel])
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.alignment = .leading
        infoStackView.distribution = .fill
        infoStackView.axis = .vertical
        infoStackView.spacing = 5
        return infoStackView
    }()
    
    private lazy var currentWeatherStackView: UIStackView = {
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
        super.init(coder: coder)
        assertionFailure(WeatherConstants.initFailure.text)
    }
    
    private func setLayoutForCurrentWeatherStackView() {
        NSLayoutConstraint.activate([
            currentWeatherStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                             constant: 5),
            currentWeatherStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                              constant: 5),
            currentWeatherStackView.topAnchor.constraint(equalTo: addressLabel.bottomAnchor),
            currentWeatherStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    func configureContents(from currentWeather: WeatherHeader?) {
        if let address = currentWeather?.address, address != " " {
            addressLabel.text = address
        } else {
            addressLabel.text = "-"
        }
        if let maxTemperature = currentWeather?.maxTemperature {
            maxTemperatureLabel.text = "Max ".localized() + TemperatureManager.convert(kelvinValue: maxTemperature,
                                                                                       fractionalCount: 1)
        }
        if let minTemperature = currentWeather?.minTemperature {
            minTemperatureLabel.text = "Min ".localized() + TemperatureManager.convert(kelvinValue: minTemperature,
                                                                                       fractionalCount: 1)
        }
        if let temperature = currentWeather?.temperature {
            temperatureLabel.text = TemperatureManager.convert(kelvinValue: temperature, fractionalCount: 1)
        }
        
        weatherIcon.image = currentWeather?.image
    }
    
    func configureLocationSelectButton(button: LocationSelectButtonType, action: @escaping ()->Void) {
        locationSelectButton.setTitle(button.text, for: .normal)
        presentLocationSelector = action
    }
    
    override func prepareForReuse() {
        addressLabel.text = "-"
        maxTemperatureLabel.text = "-"
        minTemperatureLabel.text = "-"
        temperatureLabel.text = "-"
        weatherIcon.image = nil
    }
}

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
    var weatherIcon: UIImageView = {
        let image = UIImageView()
        return image
    }()
    var maxMinStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 5
        return stackView
    }()
    
//    var maxMinStackView = UIStackView()
    
    var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 5
        return stackView
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension WeatherHeaderView {
    
    func configure() {
        addressLabel = makeLabel(text: "주소", font: .caption1)
        maxTemperatureLabel = makeLabel(text: "최고", font: .callout)
        minTemperatureLabel = makeLabel(text: "최저", font: .callout)
        temperatureLabel = makeLabel(text: "온도", font: .title1)
        weatherIcon.image = UIImage(systemName: "photo")
        
        maxMinStackView.addArrangedSubview(minTemperatureLabel)
        maxMinStackView.addArrangedSubview(maxTemperatureLabel)
        verticalStackView.addArrangedSubview(addressLabel)
        verticalStackView.addArrangedSubview(maxMinStackView)
        verticalStackView.addArrangedSubview(temperatureLabel)
        horizontalStackView.addArrangedSubview(weatherIcon)
        horizontalStackView.addArrangedSubview(verticalStackView)

//        maxMinStackView = makeStackView(axis: .horizontal, alignment: .fill, distribution: .fill, subViews: [minTemperatureLabel, maxTemperatureLabel])
//        addSubview(maxMinStackView)

        
//        verticalStackView = makeStackView(axis: .vertical, alignment: .leading, distribution: .fillProportionally, subViews: [addressLabel, maxMinStackView, temperatureLabel])
//        horizontalStackView = makeStackView(axis: .horizontal, alignment: .center, distribution: .fill, subViews: [weatherIcon, verticalStackView])
//        addSubview(horizontalStackView)
//        NSLayoutConstraint.activate([
//            horizontalStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 15),
//            horizontalStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -15),
//            horizontalStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
//            horizontalStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
//        ])
    }

    func makeLabel(text: String, font: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: font)

        return label
    }

    func makeStackView(axis: NSLayoutConstraint.Axis, alignment: UIStackView.Alignment, distribution: UIStackView.Distribution, subViews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = axis
        stackView.alignment = alignment
        stackView.distribution = distribution

        return stackView
    }
}

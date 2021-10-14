//
//  WeatherForecastCustomCell.swift
//  WeatherForecast
//
//  Created by 홍정아 on 2021/10/12.
//

import UIKit

class WeatherForecastCustomCell: UICollectionViewCell {
    static let identifier = "fiveDay"
    private var imageDataTask: URLSessionDataTask?
    
    let dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        dateLabel.textColor = .systemGray
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.text = "날씨/시간"
        return dateLabel
    }()
    
    let temperatureLabel: UILabel = {
        let temperatureLabel = UILabel()
        temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
        temperatureLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        temperatureLabel.textColor = .white
        temperatureLabel.adjustsFontForContentSizeCategory = true
        return temperatureLabel
    }()
    
    let weatherImage: UIImageView = {
        let weatherImage = UIImageView()
        weatherImage.translatesAutoresizingMaskIntoConstraints = false
        return weatherImage
    }()
    
    lazy var horizontalStackView: UIStackView = {
        var horizontalStackView = UIStackView(arrangedSubviews: [dateLabel, temperatureLabel])
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fill
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.spacing = 10
        horizontalStackView.axis = .horizontal
        contentView.addSubview(horizontalStackView)
        return horizontalStackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayoutForStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageDataTask?.cancel()
        imageDataTask = nil
    }
    
    func setLayoutForStackView() {
        NSLayoutConstraint.activate([
            horizontalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            horizontalStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(image: UIImage?) {
        if let image = image {
            weatherImage.image = image
        }
    }
    
    func configure(date: Int, temparature: Double, dataTask: URLSessionDataTask?) {
        resetContents()
        
        dateLabel.text = date.description
        imageDataTask = dataTask
        temperatureLabel.text = temparature.description + "°"
    }
    
    func resetContents() {
        dateLabel.text = nil
        temperatureLabel.text = nil
        weatherImage.image = nil
    }
}



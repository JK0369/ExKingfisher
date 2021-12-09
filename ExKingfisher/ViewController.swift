//
//  ViewController.swift
//  ExKingfisher
//
//  Created by Jake.K on 2021/12/09.
//

import UIKit
import Kingfisher
import Then

class ViewController: UIViewController {
  
  let myImageView = UIImageView()
  let downloadButton = UIButton().then {
    $0.setTitle("다운로드", for: .normal)
    $0.setTitleColor(.systemBlue, for: .normal)
    $0.setTitleColor(.blue, for: .highlighted)
  }
  let removeCacheButton = UIButton().then {
    $0.setTitle("캐시삭제", for: .normal)
    $0.setTitleColor(.systemBlue, for: .normal)
    $0.setTitleColor(.blue, for: .highlighted)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupLayout()
    loadImage()
    addTarget()
  }
  
  private func setupLayout() {
    self.view.addSubview(self.myImageView)
    self.view.addSubview(self.downloadButton)
    self.view.addSubview(self.removeCacheButton)
    
    self.myImageView.translatesAutoresizingMaskIntoConstraints = false
    self.myImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    self.myImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    
    self.downloadButton.translatesAutoresizingMaskIntoConstraints = false
    self.downloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    self.downloadButton.topAnchor.constraint(equalTo: myImageView.bottomAnchor, constant: 16).isActive = true
    
    self.removeCacheButton.translatesAutoresizingMaskIntoConstraints = false
    self.removeCacheButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    self.removeCacheButton.topAnchor.constraint(equalTo: downloadButton.bottomAnchor, constant: 16).isActive = true
  }
  
  private func loadImage() {
    guard let url = URL(string: "https://live.staticflickr.com/65535/51734305911_f4541d7629_m.jpg") else { return }
    
    let retryStrategy = DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(3))
    let cornerImageProcessor = RoundCornerImageProcessor(cornerRadius: 30)
    myImageView.kf.setImage(
      with: url,
      placeholder: nil,
      options: [
        .retryStrategy(retryStrategy),
        .transition(.fade(1.2)),
        .forceTransition,
        .processor(cornerImageProcessor)
      ],
      progressBlock: { receivedSize, totalSize in
        let percentage = (Float(receivedSize) / Float(totalSize)) * 100.0
        print(percentage)
      },
      completionHandler: nil
    )
  }
  
  private func addTarget() {
    downloadButton.addTarget(self, action: #selector(didTapDownloadButton), for: .touchUpInside)
    removeCacheButton.addTarget(self, action: #selector(didTapRemoveCacheButton), for: .touchUpInside)
  }
  
  @objc private func didTapDownloadButton() {
    downloadImage(with: "https://live.staticflickr.com/65535/51734305911_f4541d7629_m.jpg")
  }
  
  // MARK: Downlaod image
  private func downloadImage(with urlString: String) {
    guard let url = URL(string: urlString) else { return }
    let resource = ImageResource(downloadURL: url)
    KingfisherManager.shared.retrieveImage(with: resource,
                                           options: nil,
                                           progressBlock: nil) { result in
      switch result {
      case .success(let value):
        print(value.image)
      case .failure(let error):
        print("Error: \(error)")
      }
    }
  }
  
  @objc private func didTapRemoveCacheButton() {
    checkCurrentCacheSize()
    removeCache()
  }
  
  private func checkCurrentCacheSize() {
    //현재 캐시 크기 확인
    ImageCache.default.calculateDiskStorageSize { result in
      switch result {
      case .success(let size):
        print("disk cache size = \(Double(size) / 1024 / 1024)")
      case .failure(let error):
        print(error)
      }
    }
  }
  
  private func removeCache() {
    //모든 캐시 삭제
    ImageCache.default.clearMemoryCache()
    ImageCache.default.clearDiskCache { print("done clearDiskCache") }
    
    //만료된 캐시만 삭제
    ImageCache.default.cleanExpiredMemoryCache()
    ImageCache.default.cleanExpiredDiskCache { print("done cleanExpiredDiskCache") }
  }
}

// 캐시처리
extension UIImageView {
  func setImage(with urlString: String) {
    ImageCache.default.retrieveImage(forKey: urlString, options: nil) { result in
      switch result {
      case .success(let value):
        if let image = value.image {
          //캐시가 존재하는 경우
          self.image = image
        } else {
          //캐시가 존재하지 않는 경우
          guard let url = URL(string: urlString) else { return }
          let resource = ImageResource(downloadURL: url, cacheKey: urlString)
          self.kf.setImage(with: resource)
        }
      case .failure(let error):
        print(error)
      }
    }
  }
}

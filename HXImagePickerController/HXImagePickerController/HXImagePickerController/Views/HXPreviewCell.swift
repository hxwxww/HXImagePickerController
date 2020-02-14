//
//  HXPreviewCell.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/14.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXPreviewCell: UICollectionViewCell {
    
    ///  数据源
    var imageModel: HXImageModel? {
        didSet {
            guard let imageModel = imageModel else { return }
            imageView.image = imageModel.thumbImage
            if imageModel.editedImage == nil {
                activityView.startAnimating()
                HXPhotoImageManager.requestPreviewImage(for: imageModel.phAsset) { [weak self] (image, finished) in
                    guard let `self` = self else { return }
                    self.imageView.image = image
                    self.activityView.stopAnimating()
                    self.resizeImageView()
                }
            }
            resizeImageView()
        }
    }
    
    var singleTapCallback: ((HXPreviewCell) -> ())?
    
    // MARK: -  懒加载
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var activityView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(style: .whiteLarge)
        activityView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        return activityView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: bounds)
        scrollView.bouncesZoom = true
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()
    
    // MARK: -  Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(activityView)
        /// 添加手势
        addGestures()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addGestures() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(tapGesture:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(tapGesture:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func resizeImageView() {
        scrollView.setZoomScale(1, animated: false)
        imageView.frame = calculateContainerFrame(imageView.image)
        scrollView.contentSize = CGSize(width: bounds.width, height: max(imageView.frame.height, scrollView.bounds.height))
        scrollView.scrollRectToVisible(scrollView.bounds, animated: false)
    }
    
    @objc func singleTap(tapGesture: UITapGestureRecognizer) {
        singleTapCallback?(self)
    }
    
    @objc func doubleTap(tapGesture: UITapGestureRecognizer) {
        if (scrollView.zoomScale > 1.0) {
            // 状态还原
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let touchPoint = tapGesture.location(in: imageView)
            let newZoomScale = scrollView.maximumZoomScale
            let width = frame.width / newZoomScale
            let height = frame.height / newZoomScale
            scrollView.zoom(to: CGRect(x: touchPoint.x - width / 2, y: touchPoint.y - height / 2, width: width, height: height), animated: true)
        }
    }
    
    private func calculateContainerFrame(_ image: UIImage?) -> CGRect {
        guard let image = image else { return .zero }
        var containerFrame = UIScreen.main.bounds
        let height = floor(image.size.height / image.size.width * containerFrame.width)
        containerFrame.size.height = height
        /// 如果不是长图，居中显示
        if image.size.height / image.size.width < scrollView.frame.height / containerFrame.width {
            containerFrame.origin.y = (bounds.height - height) / 2
        }
        return containerFrame
    }
    
}

// MARK: -  UIScrollViewDelegate
extension HXPreviewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) / 2 : 0.0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) / 2 : 0.0;
        imageView.center = CGPoint(x: scrollView.contentSize.width / 2 + offsetX, y: scrollView.contentSize.height / 2 + offsetY);
    }
    
}

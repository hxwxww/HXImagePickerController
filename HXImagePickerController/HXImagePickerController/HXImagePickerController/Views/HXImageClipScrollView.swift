//
//  HXImageClipScrollView.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/19.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXImageClipScrollView: UIView {

    // MARK: -  回调
    
    /// 是否能够还原的回调
    var canRecoveryClosure: HXImageClipResizeClosure? {
        didSet {
            clipResizeView?.canRecoveryClosure = canRecoveryClosure
        }
    }
    
    /// 是否正在缩放的回调
    var prepareToScaleClosure: HXImageClipResizeClosure? {
        didSet {
            clipResizeView?.prepareToScaleClosure = prepareToScaleClosure
        }
    }
    
    /// 需要裁剪的图片
    private var image: UIImage?
    
    /// 裁剪区域距离边缘大小
    private var margin: CGFloat = 0
    
    /// 内容缩进
    private var contentInset: UIEdgeInsets = .zero
    
    /// 内容尺寸大小
    private var contentSize: CGSize = .zero
    
    /// 负责处理裁剪框大小
    private var clipResizeView: HXImageClipResizeView?
    
    // MARK: -  lazy loading
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bouncesZoom = true
        scrollView.maximumZoomScale = CGFloat.greatestFiniteMagnitude
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.clipsToBounds = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    init(frame: CGRect, image: UIImage, margin: CGFloat, contentInset: UIEdgeInsets) {
        super.init(frame: frame)
        self.image = image
        self.margin = margin
        self.contentInset = contentInset
        let contentWidth = bounds.width - contentInset.left - contentInset.right
        let contentHeight = bounds.height - contentInset.top - contentInset.bottom
        contentSize = CGSize(width: contentWidth, height: contentHeight)
        setupUI()
        setupSubviewsLayout()
        setupClipResizeView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: -  Private Methods
extension HXImageClipScrollView {
    
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = .black
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        imageView.image = image
    }
    
    private func setupSubviewsLayout() {
        scrollView.frame = calculateScrollViewFrame()
        imageView.frame = calculateImageViewFrame()
        let vInset = (scrollView.bounds.height - imageView.frame.height) / 2
        let hInset = (scrollView.bounds.width - imageView.frame.width) / 2
        scrollView.contentSize = imageView.frame.size
        scrollView.contentInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
        scrollView.contentOffset = CGPoint(x: -hInset, y: -vInset)
    }
    
    private func setupClipResizeView() {
        let clipResizeView = HXImageClipResizeView(frame: scrollView.frame, contentSize: contentSize, margin: margin, scrollView: scrollView, imageView: imageView)
        clipResizeView.canRecoveryClosure = canRecoveryClosure
        clipResizeView.prepareToScaleClosure = prepareToScaleClosure
        addSubview(clipResizeView)
        self.clipResizeView = clipResizeView
    }
    
    private func calculateScrollViewFrame() -> CGRect {
        let h = contentSize.height
        let w = h * h / contentSize.width
        let x = contentInset.left + (bounds.width - w) / 2
        let y = contentInset.top
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func calculateImageViewFrame() -> CGRect {
        guard let image = imageView.image else { return .zero }
        let maxW = contentSize.width - 2 * margin
        let maxH = contentSize.height - 2 * margin
        let whScale = image.size.width / image.size.height
        var w = maxW
        var h = w / whScale
        if h > maxH {
            h = maxH
            w = h * whScale
        }
        return CGRect(x: 0, y: 0, width: w, height: h)
    }
    
}

// MARK: -  UIScrollViewDelegate
extension HXImageClipScrollView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        clipResizeView?.startImageResize()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        clipResizeView?.endIamgeResize()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        clipResizeView?.startImageResize()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        clipResizeView?.endIamgeResize()
    }
    
}

// MARK: -  Public Methods
extension HXImageClipScrollView {
    
    func recovery() {
        guard let clipResizeView = clipResizeView else { return }
        guard clipResizeView.isCanRecovery else { return }
        clipResizeView.willRecovery()
        UIView.animate(withDuration: clipResizeView.animateDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.clipResizeView?.recoveryWithAnimate(true)
        }) { (finished) in
            self.clipResizeView?.doneRecovery()
        }
    }
    
    /// 裁剪图片
    ///
    /// - Parameters:
    ///   - isOriginImageSize: 是否基于原图大小裁剪
    ///   - referenceWidth: 基于指定宽度裁剪
    ///   - completion: 回调
    func clipImage(isOriginImageSize: Bool = true, referenceWidth: CGFloat = 0, _ completion: @escaping (UIImage?) -> ()) {
        guard !(clipResizeView?.isPrepareToScale ?? false) else { return }
        clipResizeView?.clipImage(isOriginImageSize: isOriginImageSize, referenceWidth: referenceWidth, completion: completion)
    }
    
}

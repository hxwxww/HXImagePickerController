//
//  HXImageClipResizeView.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/19.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

enum HXImageClipResizeCornerType {
    case leftTop
    case rightTop
    case leftBottom
    case rightBottom
    case leftMid
    case topMid
    case rightMid
    case bottomMid
    case none
}

enum HXImageClipResizeLinePosition {
    case hTop
    case hBottom
    case vLeft
    case vRight
}

typealias HXImageClipResizeClosure = (HXImageClipResizeView, Bool) -> ()

// MARK: -  负责处理裁剪框大小操作的view
class HXImageClipResizeView: UIView {
    
    // MARK: -  回调
    /// 是否能够还原的回调
    var canRecoveryClosure: HXImageClipResizeClosure?
    /// 是否正在缩放的回调
    var prepareToScaleClosure: HXImageClipResizeClosure?
    
    // MARK: -  CAShapeLayers
    private lazy var bgLayer: CAShapeLayer = {
        let bgLayer = generateSublayerWithLineWidth(0)
        bgLayer.fillColor = UIColor(white: 0, alpha: 0.5).cgColor
        bgLayer.fillRule = .evenOdd
        return bgLayer
    }()
    
    private lazy var clipLayer: CAShapeLayer = {
        let clipLayer = generateSublayerWithLineWidth(borderLineWidth)
        return clipLayer
    }()
    
    private lazy var leftTopLayer: CAShapeLayer = {
        let leftTopLayer = generateSublayerWithLineWidth(cornerLineWidth)
        return leftTopLayer
    }()
    
    private lazy var rightTopLayer: CAShapeLayer = {
        let rightTopLayer = generateSublayerWithLineWidth(cornerLineWidth)
        return rightTopLayer
    }()
    
    private lazy var leftBottomLayer: CAShapeLayer = {
        let leftBottomLayer = generateSublayerWithLineWidth(cornerLineWidth)
        return leftBottomLayer
    }()
    
    private lazy var rightBottomLayer: CAShapeLayer = {
        let rightBottomLayer = generateSublayerWithLineWidth(cornerLineWidth)
        return rightBottomLayer
    }()
    
    private lazy var hTopLineLayer: CAShapeLayer = {
        let hTopLineLayer = generateSublayerWithLineWidth(normalLineWidth)
        return hTopLineLayer
    }()
    
    private lazy var hBottomLineLayer: CAShapeLayer = {
        let hBottomLineLayer = generateSublayerWithLineWidth(normalLineWidth)
        return hBottomLineLayer
    }()
    
    private lazy var vLeftLineLayer: CAShapeLayer = {
        let vLeftLineLayer = generateSublayerWithLineWidth(normalLineWidth)
        return vLeftLineLayer
    }()
    
    private lazy var vRightLineLayer: CAShapeLayer = {
        let vRightLineLayer = generateSublayerWithLineWidth(normalLineWidth)
        return vRightLineLayer
    }()
    
    // MARK: - 变量
    private var timer: Timer?
    private var maxResizeFrame: CGRect = .zero
    private var resizeFrame: CGRect = .zero
    private var originFrame: CGRect = .zero
    private var contentSize: CGSize = .zero
    private var margin: CGFloat = 0
    private weak var scrollView: UIScrollView?
    private weak var imageView: UIImageView?
    private var baseImageW: CGFloat = 0
    private var baseImageH: CGFloat = 0
    
    private (set) var isPrepareToScale: Bool = false {
        didSet {
            prepareToScaleClosure?(self, isPrepareToScale)
        }
    }
    private (set) var isCanRecovery: Bool = false {
        didSet {
            canRecoveryClosure?(self, isCanRecovery)
        }
    }

    /// 处理手势
    private var cornerType: HXImageClipResizeCornerType = .none
    private var diagonalPoint: CGPoint = .zero
    private var startResizeW: CGFloat = 0
    private var startResizeH: CGFloat = 0
    
    // MARK: -  常量
    let animateDuration: TimeInterval = 0.25
    private let cornerLineLength: CGFloat = 20
    private let cornerLineWidth: CGFloat = 2.5
    private let normalLineWidth: CGFloat = 0.5
    private let borderLineWidth: CGFloat = 1
    private let handlePanScopeWH: CGFloat = 50
    private let minImageWH: CGFloat = 70
    private let bgPathFrame = CGRect(x: -800, y: -800, width: hxip_screenWidth + 1600, height: hxip_screenHeight + 1600)

    // MARK: -  Life Cycle
    init(frame: CGRect, contentSize: CGSize, margin: CGFloat, scrollView: UIScrollView, imageView: UIImageView) {
        super.init(frame: frame)
        backgroundColor = .clear
        self.contentSize = contentSize
        self.margin = margin
        self.scrollView = scrollView
        self.imageView = imageView
        calculateResizeFrames()
        addSublayers()
        addGestures()
        updateResizeFrame(originFrame, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeTimer()
        HXLog("HXImageClipResizeView deinit")
    }
}

// MARK: -  Private Methods
extension HXImageClipResizeView {
    
    private func addSublayers() {
        layer.addSublayer(bgLayer)
        layer.addSublayer(clipLayer)
        layer.addSublayer(leftTopLayer)
        layer.addSublayer(leftBottomLayer)
        layer.addSublayer(rightTopLayer)
        layer.addSublayer(rightBottomLayer)
        layer.addSublayer(vLeftLineLayer)
        layer.addSublayer(vRightLineLayer)
        layer.addSublayer(hTopLineLayer)
        layer.addSublayer(hBottomLineLayer)
    }
    
    private func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureAction(panGesture:)))
        addGestureRecognizer(panGesture)
    }
    
    private func updateResizeFrame(_ resizeFrame: CGRect, animated: Bool) {
        self.resizeFrame = resizeFrame
        let leftTopPath = cornerPathWithPosition(CGPoint(x: resizeFrame.minX, y: resizeFrame.minY), cornerType: .leftTop)
        let leftBottomPath = cornerPathWithPosition(CGPoint(x: resizeFrame.minX, y: resizeFrame.maxY), cornerType: .leftBottom)
        let rightTopPath = cornerPathWithPosition(CGPoint(x: resizeFrame.maxX, y: resizeFrame.minY), cornerType: .rightTop)
        let rightBottomPath = cornerPathWithPosition(CGPoint(x: resizeFrame.maxX, y: resizeFrame.maxY), cornerType: .rightBottom)
        let hTopLinePath = linePathWithPosition(CGPoint(x: resizeFrame.minX, y: resizeFrame.minY + resizeFrame.height / 3), length: resizeFrame.width, linePosition: .hTop)
        let hBottomLinePath = linePathWithPosition(CGPoint(x: resizeFrame.minX, y: resizeFrame.minY + resizeFrame.height / 3 * 2), length: resizeFrame.width, linePosition: .hBottom)
        let vLeftLinePath = linePathWithPosition(CGPoint(x: resizeFrame.minX + resizeFrame.width / 3, y: resizeFrame.minY), length: resizeFrame.height, linePosition: .vLeft)
        let vRightLinePath = linePathWithPosition(CGPoint(x: resizeFrame.minX + resizeFrame.width / 3 * 2, y: resizeFrame.minY), length: resizeFrame.height, linePosition: .vRight)
        let clipPath = UIBezierPath(rect: resizeFrame)
        let bgPath = UIBezierPath(rect: bgPathFrame)
        bgPath.append(clipPath.reversing())
        if animated {
            func animateLayer(layer: CAShapeLayer, path: UIBezierPath) {
                let animate = CABasicAnimation(keyPath: "path")
                animate.fillMode = .backwards
                animate.fromValue = layer.path
                animate.toValue = path
                animate.duration = animateDuration
                animate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(animate, forKey: "path")
            }
            animateLayer(layer: leftTopLayer, path: leftTopPath)
            animateLayer(layer: rightTopLayer, path: rightTopPath)
            animateLayer(layer: leftBottomLayer, path: leftBottomPath)
            animateLayer(layer: rightBottomLayer, path: rightBottomPath)
            animateLayer(layer: vLeftLineLayer, path: vLeftLinePath)
            animateLayer(layer: vRightLineLayer, path: vRightLinePath)
            animateLayer(layer: hTopLineLayer, path: hTopLinePath)
            animateLayer(layer: hBottomLineLayer, path: hBottomLinePath)
            animateLayer(layer: bgLayer, path: bgPath)
            animateLayer(layer: clipLayer, path: clipPath)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        leftTopLayer.path = leftTopPath.cgPath
        leftBottomLayer.path = leftBottomPath.cgPath
        rightTopLayer.path = rightTopPath.cgPath
        rightBottomLayer.path = rightBottomPath.cgPath
        hTopLineLayer.path = hTopLinePath.cgPath
        hBottomLineLayer.path = hBottomLinePath.cgPath
        vLeftLineLayer.path = vLeftLinePath.cgPath
        vRightLineLayer.path = vRightLinePath.cgPath
        bgLayer.path = bgPath.cgPath
        clipLayer.path = clipPath.cgPath
        CATransaction.commit()
    }
    
    private func updateResizeFrameWithAnimate(_ animated: Bool) {
        guard let scrollView = scrollView else { return }
        let adjustResizeFrame = calculateAdjustResizeFrame()
        let contentInset = contentInsetWithNewResizeFrame(adjustResizeFrame)
        var contentOffset = CGPoint.zero
        let convertPoint = convert(resizeFrame.origin, to: imageView)
        contentOffset.x = -contentInset.left + convertPoint.x * scrollView.zoomScale
        contentOffset.y = -contentInset.top + convertPoint.y * scrollView.zoomScale
        scrollView.minimumZoomScale = minZoomScaleWithResizeSize(adjustResizeFrame.size)
        
        let convertScale = resizeFrame.width / adjustResizeFrame.width
        let diffXSpace = adjustResizeFrame.minX * convertScale
        let diffYSpace = adjustResizeFrame.minY * convertScale
        let convertW = resizeFrame.width + 2 * diffXSpace
        let convertH = resizeFrame.height + 2 * diffYSpace
        let convertX = resizeFrame.minX - diffXSpace
        let convertY = resizeFrame.minY - diffYSpace
        let zoomFrame = convert(CGRect(x: convertX, y: convertY, width: convertW, height: convertH), to: imageView)

        let zoomClosure = { [weak self] in
            guard let `self` = self else { return }
            self.scrollView?.contentInset = contentInset
            self.scrollView?.setContentOffset(contentOffset, animated: false)
            self.scrollView?.zoom(to: zoomFrame, animated: false)
        }
        let completeClosure = { [weak self] (finished: Bool) in
            guard let `self` = self else { return }
            self.isPrepareToScale = false
            self.checkIsCanRecovery()
            self.superview?.isUserInteractionEnabled = true
        }
        superview?.isUserInteractionEnabled = false
        updateResizeFrame(adjustResizeFrame, animated: animated)
        if animated {
            UIView.animate(withDuration: animateDuration, delay: 0, options: .curveEaseInOut, animations: zoomClosure, completion: completeClosure)
        } else {
            zoomClosure()
            completeClosure(true)
        }
    }
    
}

// MARK: -  Assist Methods
extension HXImageClipResizeView {
 
    private func calculateResizeFrames() {
        guard let imageView = imageView else { return }
        baseImageW = imageView.bounds.width
        baseImageH = imageView.bounds.height
        let w = imageView.bounds.width
        let h = imageView.bounds.height
        let x = (bounds.width - w) / 2
        let y = (bounds.height - h) / 2
        originFrame = CGRect(x: x, y: y, width: w, height: h)
        let diffHalfWidth = (bounds.width - contentSize.width) / 2
        let maxX = diffHalfWidth + margin
        let maxY = margin
        let maxW = bounds.width - 2 * maxX
        let maxH = bounds.height - 2 * maxY
        maxResizeFrame = CGRect(x: maxX, y: maxY, width: maxW, height: maxH)
    }
    
    private func contentInsetWithNewResizeFrame(_ newResizeFrame: CGRect) -> UIEdgeInsets {
        let top = newResizeFrame.minY
        let bottom = bounds.height - newResizeFrame.maxY
        let left = newResizeFrame.minX
        let right = bounds.width - newResizeFrame.maxX
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    private func minZoomScaleWithResizeSize(_ resizeSize: CGSize) -> CGFloat {
        var minZoomScale: CGFloat = 1
        if resizeSize.width >= resizeSize.height {
            minZoomScale = resizeSize.width / baseImageW
            let imageH = baseImageH * minZoomScale
            if imageH < resizeSize.height {
                minZoomScale *= (resizeSize.height / imageH)
            }
        } else {
            minZoomScale = resizeSize.height / baseImageH
            let imageW = baseImageW * minZoomScale
            if imageW < resizeSize.width {
                minZoomScale *= (resizeSize.width / imageW)
            }
        }
        return minZoomScale
    }
    
    private func calculateAdjustResizeFrame() -> CGRect {
        let resizeWHScale = resizeFrame.width / resizeFrame.height
        var adjustResizeW: CGFloat = 0
        var adjustResizeH: CGFloat = 0
        if resizeWHScale >= 1 {
            adjustResizeW = maxResizeFrame.width
            adjustResizeH = adjustResizeW / resizeWHScale
            if adjustResizeH > maxResizeFrame.height {
                adjustResizeH = maxResizeFrame.height
                adjustResizeW = adjustResizeH * resizeWHScale
            }
        } else {
            adjustResizeH = maxResizeFrame.height
            adjustResizeW = adjustResizeH * resizeWHScale
            if adjustResizeW > maxResizeFrame.width {
                adjustResizeW = maxResizeFrame.width
                adjustResizeH = adjustResizeW / resizeWHScale
            }
        }
        let adjustResizeX = maxResizeFrame.minX + (maxResizeFrame.width - adjustResizeW) / 2
        let adjustResizeY = maxResizeFrame.minY + (maxResizeFrame.height - adjustResizeH) / 2
        return CGRect(x: adjustResizeX, y: adjustResizeY, width: adjustResizeW, height: adjustResizeH)
    }
    
    private func checkIsCanRecovery() {
        guard let imageView = imageView else { return }
        let convertCenter = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: imageView)
        let imageViewCenter = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        let isSameCenter = (labs(Int(convertCenter.x - imageViewCenter.x)) <= 1 && labs(Int(convertCenter.y - imageViewCenter.y)) <= 1)
        let isOriginFrame = labs(Int(resizeFrame.width - imageView.bounds.width)) <= 1 && labs(Int(resizeFrame.height - imageView.bounds.height)) <= 1
        isCanRecovery = !isOriginFrame || !isSameCenter
    }
    
    private func generateSublayerWithLineWidth(_ lineWidth: CGFloat) -> CAShapeLayer {
        let cornerLayer = CAShapeLayer()
        cornerLayer.frame = bounds
        cornerLayer.strokeColor = UIColor.white.cgColor
        cornerLayer.fillColor = UIColor.clear.cgColor
        cornerLayer.lineWidth = lineWidth
        return cornerLayer
    }
    
    private func cornerPathWithPosition(_ position: CGPoint, cornerType: HXImageClipResizeCornerType) -> UIBezierPath {
        let path = UIBezierPath()
        let halfCornerLineWidth = cornerLineWidth / 2
        var point1 = CGPoint.zero
        var point2 = CGPoint.zero
        var point3 = CGPoint.zero
        switch cornerType {
        case .leftTop:
            point2 = CGPoint(x: position.x - halfCornerLineWidth, y: position.y - halfCornerLineWidth)
            point1 = CGPoint(x: point2.x, y: point2.y + cornerLineLength)
            point3 = CGPoint(x: point2.x + cornerLineLength, y: point2.y)
        case .leftBottom:
            point2 = CGPoint(x: position.x - halfCornerLineWidth, y: position.y + halfCornerLineWidth)
            point1 = CGPoint(x: point2.x, y: point2.y - cornerLineLength)
            point3 = CGPoint(x: point2.x + cornerLineLength, y: point2.y)
        case .rightTop:
            point2 = CGPoint(x: position.x + halfCornerLineWidth, y: position.y - halfCornerLineWidth)
            point1 = CGPoint(x: point2.x - cornerLineLength, y: point2.y)
            point3 = CGPoint(x: point2.x, y: point2.y + cornerLineLength)
        case .rightBottom:
            point2 = CGPoint(x: position.x + halfCornerLineWidth, y: position.y + halfCornerLineWidth)
            point1 = CGPoint(x: point2.x - cornerLineLength, y: point2.y)
            point3 = CGPoint(x: point2.x, y: point2.y - cornerLineLength)
        default:
            point1 = position
            point2 = position
            point3 = position
        }
        path.move(to: point1)
        path.addLine(to: point2)
        path.addLine(to: point3)
        return path
    }
    
    private func linePathWithPosition(_ position: CGPoint, length: CGFloat, linePosition: HXImageClipResizeLinePosition) -> UIBezierPath {
        let path = UIBezierPath()
        var point = CGPoint.zero
        switch linePosition {
        case .hBottom, .hTop:
            point = CGPoint(x: position.x + length, y: position.y)
        case .vLeft, .vRight:
            point = CGPoint(x: position.x, y: position.y + length)
        }
        path.move(to: position)
        path.addLine(to: point)
        return path
    }
    
    private func addTimer() {
        removeTimer()
        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func removeTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc private func handleTimer() {
        removeTimer()
        updateResizeFrameWithAnimate(true)
    }
    
}

// MARK: -  UIPanGestureRecognizer
extension HXImageClipResizeView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let halfHandlePanScopeWH = handlePanScopeWH / 2
        let maxFrame = resizeFrame.insetBy(dx: -halfHandlePanScopeWH, dy: -halfHandlePanScopeWH)
        let minFrame = resizeFrame.insetBy(dx: halfHandlePanScopeWH, dy: halfHandlePanScopeWH)
        if maxFrame.contains(point) && !minFrame.contains(point) {
            return true
        }
        return false
    }
    
    @objc private func handlePanGestureAction(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            let point = panGesture.location(in: self)
            beginPanWithPoint(point)
        case .changed:
            let translation = panGesture.translation(in: self)
            panGesture.setTranslation(.zero, in: self)
            changePanWithTranslation(translation)
        case .ended, .cancelled, .failed:
            endIamgeResize()
        default:
            break
        }
    }
    
    private func beginPanWithPoint(_ point: CGPoint) {
        startImageResize()
        let halfHandlePanScopeWH = handlePanScopeWH / 2
        let x = resizeFrame.minX
        let y = resizeFrame.minY
        let w = resizeFrame.width
        let h = resizeFrame.height
        let midX = resizeFrame.midX
        let midY = resizeFrame.midY
        let maxX = resizeFrame.maxX
        let maxY = resizeFrame.maxY
        let leftTopRect = CGRect(x: x - halfHandlePanScopeWH, y: y - halfHandlePanScopeWH, width: handlePanScopeWH, height: handlePanScopeWH)
        let leftBottomRect = CGRect(x: x - halfHandlePanScopeWH, y: maxY - halfHandlePanScopeWH, width: handlePanScopeWH, height: handlePanScopeWH)
        let rightTopRect = CGRect(x: maxX - halfHandlePanScopeWH, y: y, width: handlePanScopeWH, height: handlePanScopeWH)
        let rightBottomRect = CGRect(x: maxX - halfHandlePanScopeWH, y: maxY - halfHandlePanScopeWH, width: handlePanScopeWH, height: handlePanScopeWH)
        let leftMidRect = CGRect(x: x - halfHandlePanScopeWH, y: y + halfHandlePanScopeWH, width: handlePanScopeWH, height: h - handlePanScopeWH)
        let rightMidRect = CGRect(x: maxX - halfHandlePanScopeWH, y: y + halfHandlePanScopeWH, width: handlePanScopeWH, height: h - handlePanScopeWH)
        let topMidRect = CGRect(x: x + halfHandlePanScopeWH, y: y - halfHandlePanScopeWH, width: w - handlePanScopeWH, height: handlePanScopeWH)
        let bottomMidRect = CGRect(x: x + halfHandlePanScopeWH, y: maxY - halfHandlePanScopeWH, width: w - handlePanScopeWH, height: handlePanScopeWH)
        if leftTopRect.contains(point) {
            cornerType = .leftTop
            diagonalPoint = CGPoint(x: maxX, y: maxY)
        } else if leftBottomRect.contains(point) {
            cornerType = .leftBottom
            diagonalPoint = CGPoint(x: maxX, y: y)
        } else if rightTopRect.contains(point) {
            cornerType = .rightTop
            diagonalPoint = CGPoint(x: x, y: maxY)
        } else if rightBottomRect.contains(point) {
            cornerType = .rightBottom
            diagonalPoint = CGPoint(x: x, y: y)
        } else if leftMidRect.contains(point) {
            cornerType = .leftMid
            diagonalPoint = CGPoint(x: maxX, y: midY)
        } else if rightMidRect.contains(point) {
            cornerType = .rightMid
            diagonalPoint = CGPoint(x: x, y: midY)
        } else if topMidRect.contains(point) {
            cornerType = .topMid
            diagonalPoint = CGPoint(x: midX, y: maxY)
        } else if bottomMidRect.contains(point) {
            cornerType = .bottomMid
            diagonalPoint = CGPoint(x: midX, y: y)
        }
        startResizeW = w
        startResizeH = h
    }
 
    private func changePanWithTranslation(_ translation: CGPoint) {
        guard let scrollView = scrollView else { return }
        var x = resizeFrame.minX
        var y = resizeFrame.minY
        var w = resizeFrame.width
        var h = resizeFrame.height
        let maxResizeX = maxResizeFrame.minX
        let maxResizeY = maxResizeFrame.minY
        let maxResizeMaxX = maxResizeFrame.maxX
        let maxResizeMaxY = maxResizeFrame.maxY
        switch cornerType {
        case .leftTop:
            x += translation.x
            y += translation.y
            if x < maxResizeX {
                x = maxResizeX
            }
            if y < maxResizeY {
                y = maxResizeY
            }
            w = diagonalPoint.x - x
            h = diagonalPoint.y - y
            if w < minImageWH {
                w = minImageWH
                x = diagonalPoint.x - w
            }
            if h < minImageWH {
                h = minImageWH;
                y = diagonalPoint.y - h
            }
        case .leftBottom:
            x += translation.x
            h += translation.y
            if x < maxResizeX {
                x = maxResizeX
            }
            if y + h > maxResizeMaxY {
                h = maxResizeMaxY - diagonalPoint.y
            }
            w = diagonalPoint.x - x
            if w < minImageWH {
                w = minImageWH
                x = diagonalPoint.x - w
            }
            if h < minImageWH {
                h = minImageWH
            }
        case .rightTop:
            y += translation.y
            w += translation.x
            if y < maxResizeY {
                y = maxResizeY
            }
            if x + w > maxResizeMaxX {
                w = maxResizeMaxX - diagonalPoint.x
            }
            h = diagonalPoint.y - y
            if w < minImageWH {
                w = minImageWH
            }
            if h < minImageWH {
                h = minImageWH
                y = diagonalPoint.y - h
            }
        case .rightBottom:
            w += translation.x
            h += translation.y
            if x + w > maxResizeMaxX {
                w = maxResizeMaxX - diagonalPoint.x
            }
            if y + h > maxResizeMaxY {
                h = maxResizeMaxY - diagonalPoint.y
            }
            if w < minImageWH {
                w = minImageWH
            }
            if h < minImageWH {
                h = minImageWH
            }
        case .leftMid:
            x += translation.x
            if x < maxResizeX {
                x = maxResizeX
            }
            w = diagonalPoint.x - x
            if w < minImageWH {
                w = minImageWH
                x = diagonalPoint.x - w
            }
        case .rightMid:
            w += translation.x
            if x + w > maxResizeMaxX {
                w = maxResizeMaxX - diagonalPoint.x
            }
            if w < minImageWH {
                w = minImageWH
            }
        case .topMid:
            y += translation.y
            if y < maxResizeY {
                y = maxResizeY
            }
            h = diagonalPoint.y - y
            if h < minImageWH {
                h = minImageWH
                y = diagonalPoint.y - h
            }
        case .bottomMid:
            h += translation.y
            if y + h > maxResizeMaxY {
                h = maxResizeMaxY - diagonalPoint.y
            }
            if h < minImageWH {
                h = minImageWH
            }
        default:
            break
        }
        let newResizeFrame = CGRect(x: x, y: y, width: w, height: h)
        updateResizeFrame(newResizeFrame, animated: false)
        let zoomFrame = convert(newResizeFrame, to: imageView)
        var contentOffset = scrollView.contentOffset
        if zoomFrame.minX < 0 {
            contentOffset.x -= zoomFrame.minX
        } else if zoomFrame.maxX > baseImageW {
            contentOffset.x -= zoomFrame.maxX - baseImageW
        }
        if zoomFrame.minY < 0 {
            contentOffset.y -= zoomFrame.minY
        } else if zoomFrame.maxY > baseImageH {
            contentOffset.y -= zoomFrame.maxY - baseImageH
        }
        scrollView.setContentOffset(contentOffset, animated: false)
        var wZoomScale: CGFloat = 0
        var hZoomScale: CGFloat = 0
        if w > startResizeW {
            wZoomScale = w / baseImageW
        }
        if h > startResizeH {
            hZoomScale = h / baseImageH
        }
        let zoomScale = max(wZoomScale, hZoomScale)
        if zoomScale > scrollView.zoomScale {
            scrollView.setZoomScale(zoomScale, animated: false)
        }
    }
    
}

// MARK: -  Public Methods
extension HXImageClipResizeView {
    
    func startImageResize() {
        isPrepareToScale = true
        removeTimer()
    }
    
    func endIamgeResize() {
        let contentInset = contentInsetWithNewResizeFrame(resizeFrame)
        scrollView?.contentInset = contentInset
        addTimer()
    }
 
    func willRecovery() {
        super.isUserInteractionEnabled = false
        removeTimer()
    }
    
    func recoveryWithAnimate(_ animated: Bool) {
        let contentInset = contentInsetWithNewResizeFrame(originFrame)
        let minZoomScale = minZoomScaleWithResizeSize(originFrame.size)
        let contentOffsetX = -contentInset.left + (baseImageW * minZoomScale - originFrame.width) / 2
        let contentOffsetY = -contentInset.top + (baseImageH * minZoomScale - originFrame.height) / 2
        updateResizeFrame(originFrame, animated: animated)
        scrollView?.minimumZoomScale = minZoomScale
        scrollView?.zoomScale = minZoomScale
        scrollView?.contentInset = contentInset
        scrollView?.contentOffset = CGPoint(x: contentOffsetX, y: contentOffsetY)
    }
    
    func doneRecovery() {
        updateResizeFrameWithAnimate(false)
        super.isUserInteractionEnabled = true
    }
 
    /// 裁剪图片，子线程裁剪，主线程回调
    ///
    /// - Parameters:
    ///   - isOriginImageSize: 是否基于原图大小裁剪
    ///   - referenceWidth: 基于指定宽度裁剪
    ///   - completion: 回调
    func clipImage(isOriginImageSize: Bool, referenceWidth: CGFloat, completion: @escaping (UIImage?) -> ()) {
        guard let imageView = imageView,
            let image = imageView.image,
            let imageRef = image.cgImage else {
            completion(nil)
            return
        }
        let imageScale = image.scale
        let imageWidth = image.size.width * imageScale
        let imageHeight = image.size.height * imageScale
        let scale = imageWidth / imageView.bounds.width
        let deviceScale = UIScreen.main.scale
        let cropFrame = isCanRecovery ? convert(resizeFrame, to: imageView) : imageView.bounds
        var newRefW = referenceWidth
        if (newRefW > 0) {
            let maxWidth = max(imageWidth, imageView.bounds.width)
            let minWidth = min(imageWidth, imageView.bounds.width)
            if newRefW > maxWidth {
                newRefW = maxWidth
            }
            if newRefW < minWidth {
                newRefW = minWidth
            }
        } else {
            newRefW = imageView.bounds.width
        }
        DispatchQueue.global().async {
            var x = cropFrame.minX * scale
            var y = cropFrame.minY * scale
            var w = cropFrame.width * scale
            var h = cropFrame.height * scale
            if x < 0 {
                w -= x
                x = 0
            }
            if y < 0 {
                h -= y
                y = 0
            }
            if w + x > imageWidth {
                w -= (w + x - imageWidth)
            }
            if h + y > imageHeight {
                h -= (h + y - imageHeight)
            }
            let cropRect = CGRect(x: x, y: y, width: w, height: h)
            guard let cropImageRef = imageRef.cropping(to: cropRect) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let cropImage = UIImage(cgImage: cropImageRef)
            if isOriginImageSize {
                DispatchQueue.main.async {
                    completion(cropImage)
                }
                return
            }
            let cropScale = imageWidth / newRefW
            let cropSize = CGSize(width: floor(cropImage.size.width / cropScale), height: floor(cropImage.size.height / cropScale))
            UIGraphicsBeginImageContextWithOptions(cropSize, false, deviceScale)
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: 0, y: cropSize.height)
            context?.scaleBy(x: 1, y: -1)
            context?.draw(cropImageRef, in: CGRect(origin: .zero, size: cropSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                completion(newImage)
            }
        }
    }
}

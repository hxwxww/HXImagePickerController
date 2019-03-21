//
//  HXImagePreviewViewController.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/14.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

private let cellSpacing: CGFloat = 10

class HXImagePreviewViewController: UIViewController {

    /// 图片模型数组
    var imageModels: [HXImageModel] = []
    
    /// 当前的index
    var currentIndex: Int = 0
    
    /// 图片被编辑之后的回调
    var imageDidEditedCallback: ((HXImageModel) -> ())?

    // MARK: -  lazy loading
    
    private lazy var previewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = cellSpacing * 2
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: cellSpacing, bottom: 0, right: cellSpacing)
        layout.itemSize = view.bounds.size
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.hx_registerCell(cellClass: HXPreviewCell.self)
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.frame = collectionView.frame.insetBy(dx: -cellSpacing, dy: 0)
        return collectionView
    }()
    
    private lazy var thumbCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 70, height: 70)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: view.bounds.height - toolBarHeight - 90, width: view.bounds.width, height: 90), collectionViewLayout: layout)
        collectionView.backgroundColor = hxip_toolBarBackgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceHorizontal = true
        collectionView.hx_registerCell(cellClass: HXPreviewThumbCell.self)
        collectionView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(thumbCollectionViewHandleLongPressGesture(gesture:))))
        return collectionView
    }()
    
    /// 底部工具栏
    private lazy var imageToolView: HXImageToolView = {
        let imageToolView = HXImageToolView(frame: CGRect(x: 0, y: hxip_screenHeight - toolBarHeight, width: hxip_screenWidth, height: toolBarHeight), type: .preview)
        imageToolView.mainTintColor = pickerController?.mainTintColor ?? .red
        imageToolView.isOrigin = pickerController?.isOrigin ?? false
        imageToolView.selectedImageCount = pickerController?.selectedImageModels.count ?? 0
        imageToolView.editBtn.addTarget(self, action: #selector(editBtnClicked), for: .touchUpInside)
        imageToolView.originBtn.addTarget(self, action: #selector(originBtnClicked), for: .touchUpInside)
        imageToolView.confirmBtn.addTarget(self, action: #selector(confirmBtnClicked), for: .touchUpInside)
        return imageToolView
    }()
    
    /// 顶部导航栏
    private lazy var imageNavigationView: HXImageNavigationView = {
        let imageNavigationView = HXImageNavigationView(frame: CGRect(x: 0, y: 0, width: hxip_screenWidth, height: hxip_safeTopHeight), contentHeight: 64)
        imageNavigationView.mainTintColor = pickerController?.mainTintColor ?? .red
        imageNavigationView.backBtn.addTarget(self, action: #selector(backBtnClicked), for: .touchUpInside)
        imageNavigationView.selectBtn.addTarget(self, action: #selector(selectBtnClicked), for: .touchUpInside)
        return imageNavigationView
    }()
   
    /// 缩略图当前选中索引
    private var thumbSelectedIndexPath: IndexPath?
    
    /// 长按的手指相对于临时视图的偏移
    private var tmpThumbCenterOffset: CGPoint = .zero
    
    /// 是否显示工具栏
    private var shouldShowToolViews: Bool = true
    
    /// 是否显示导航栏
    private var shouldShouNavigationBarWhenDisappear: Bool = true
    
    /// 所在的导航控制器
    private weak var pickerController: HXImagePickerController? {
        return navigationController as? HXImagePickerController
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldShouNavigationBarWhenDisappear {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        shouldShouNavigationBarWhenDisappear = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(previewCollectionView)
        view.addSubview(imageNavigationView)
        view.addSubview(imageToolView)
        view.addSubview(thumbCollectionView)
        thumbCollectionView.isHidden = pickerController?.selectedImageModels.count == 0
        imageToolView.lineView.isHidden = pickerController?.selectedImageModels.count == 0
        previewCollectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        /// 设置选中按钮状态
        if let selectedIndex = pickerController?.selectedImageModels.index(of: imageModels[currentIndex]) {
            imageNavigationView.selectBtn.setSelectedIndex(selectedIndex)
        }
        /// 添加通知
        NotificationCenter.default.addObserver(self, selector: #selector(selectedImageModelsDidChangeed(_:)), name: .HXImagePickerSelectedImageModelsDidChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .HXImagePickerSelectedImageModelsDidChanged, object: nil)
        HXLog("HXImagePreviewViewController deinit")
    }
    
    // MARK: -  Private Methods
    
    func thumbCollectionViewCellDidSelected(at indexPath: IndexPath) {
        if thumbSelectedIndexPath != nil {
            if let befroreCell = thumbCollectionView.cellForItem(at: thumbSelectedIndexPath!) {
                befroreCell.layer.borderColor = UIColor.clear.cgColor
                befroreCell.layer.borderWidth = 0
            } else {
                thumbCollectionView.reloadData()
            }
        }
        thumbSelectedIndexPath = indexPath
        let cell = thumbCollectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = pickerController?.mainTintColor.cgColor
        cell?.layer.borderWidth = 2
        /// 滚动到正确的位置
        thumbCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    private func toggleToolViewsShow() {
        shouldShowToolViews = !shouldShowToolViews
        let alpha: CGFloat = shouldShowToolViews ? 1 : 0
        UIView.animate(withDuration: 0.15) {
            self.thumbCollectionView.alpha = alpha
            self.imageNavigationView.alpha = alpha
            self.imageToolView.alpha = alpha
        }
    }
    
    // MARK: - Actions
    
    @objc private func editBtnClicked() {
        let clipVC = HXImageClipViewController()
        clipVC.imageModel = imageModels[currentIndex]
        clipVC.clipImageCallback = { [weak self] (imageModel) in
            guard let `self` = self else { return }
            self.imageModels.replaceSubrange(self.currentIndex ..< self.currentIndex + 1, with: [imageModel])
            self.previewCollectionView.reloadData()
            if let selectedIndex = self.pickerController?.selectedImageModels.index(of: imageModel) {
                self.pickerController?.selectedImageModels.replaceSubrange(selectedIndex ..< selectedIndex + 1, with: [imageModel])
                self.thumbCollectionView.reloadData()
            }
            self.imageDidEditedCallback?(imageModel)
        }
        shouldShouNavigationBarWhenDisappear = false
        navigationController?.pushViewController(clipVC, animated: true)
    }
    
    @objc private func originBtnClicked() {
        guard let pickerController = pickerController else { return }
        pickerController.isOrigin = !pickerController.isOrigin
    }
    
    @objc private func confirmBtnClicked() {
        pickerController?.confirmSelectImageModels()
    }
    
    @objc private func backBtnClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func selectBtnClicked() {
        guard let pickerController = pickerController else { return }
        let imageModel = imageModels[currentIndex]
        if imageModel.isSelected {
            imageModel.selectedIndex = -1
            imageNavigationView.selectBtn.setSelectedIndex(-1)
            for (index, selectedModel) in pickerController.selectedImageModels.enumerated() {
                if selectedModel == imageModel {
                    /// 删除
                    pickerController.selectedImageModels.remove(at: index)
                    thumbCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                    break
                }
            }
        } else {
            /// 判断是否能继续选择
            if pickerController.selectedImageModels.count == pickerController.maxSelectCount {
                pickerController.showCanNotSelectAlert()
                return
            }
            imageModel.selectedIndex = 1
            imageNavigationView.selectBtn.setSelectedIndex(pickerController.selectedImageModels.count)
            // 添加
            pickerController.selectedImageModels.append(imageModel)
            let indexPath = IndexPath(item: pickerController.selectedImageModels.count - 1, section: 0)
            thumbCollectionView.insertItems(at: [indexPath])
            /// 滚动到正确的位置
            thumbCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    @objc private func selectedImageModelsDidChangeed(_ notification: Notification) {
        guard let models = notification.object as? [HXImageModel] else { return }
        thumbCollectionView.isHidden = models.count == 0
        imageToolView.lineView.isHidden = models.count == 0
    }
    
    /// 长按拖拽调换位置
    @objc private func thumbCollectionViewHandleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        let locationCenter = gesture.location(in: thumbCollectionView)
        switch gesture.state {
        case .began:
            guard let indexPath = thumbCollectionView.indexPathForItem(at: gesture.location(in: thumbCollectionView)),
                let cell = thumbCollectionView.cellForItem(at: indexPath) as? HXPreviewThumbCell else { return }
            tmpThumbCenterOffset = CGPoint(x: cell.center.x - locationCenter.x, y: cell.center.y - locationCenter.y)
            thumbCollectionView.beginInteractiveMovementForItem(at: indexPath)
        case .changed:
            let targetPosition = locationCenter.applying(CGAffineTransform(translationX: tmpThumbCenterOffset.x, y: tmpThumbCenterOffset.y))
            thumbCollectionView.updateInteractiveMovementTargetPosition(targetPosition)
        case .ended:
            thumbCollectionView.endInteractiveMovement()
        default:
            thumbCollectionView.cancelInteractiveMovement()
        }
    }

}

// MARK: -  UICollectionViewDataSource, UICollectionViewDelegate
extension HXImagePreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == previewCollectionView {
            return imageModels.count
        } else {
            return pickerController?.selectedImageModels.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == previewCollectionView {
            let cell = collectionView.hx_dequeueReusableCell(indexPath: indexPath) as HXPreviewCell
            cell.imageModel = imageModels[indexPath.item]
            cell.singleTapCallback = { [weak self] (previewCell) in
                guard let `self` = self else { return }
                self.toggleToolViewsShow()
            }
            return cell
        } else {
            let cell = collectionView.hx_dequeueReusableCell(indexPath: indexPath) as HXPreviewThumbCell
            cell.imageModel = pickerController?.selectedImageModels[indexPath.item]
            if imageModels[currentIndex] == pickerController?.selectedImageModels[indexPath.item] {
                thumbSelectedIndexPath = indexPath
                cell.layer.borderColor = pickerController?.mainTintColor.cgColor
                cell.layer.borderWidth = 2
            } else {
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.layer.borderWidth = 0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == thumbCollectionView {
            thumbCollectionViewCellDidSelected(at: indexPath)
            guard let imageModel = pickerController?.selectedImageModels[indexPath.item],
                let imageIndex = imageModels.index(of: imageModel) else { return }
            previewCollectionView.scrollToItem(at: IndexPath(item: imageIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == thumbCollectionView {
            if let cell = thumbCollectionView.cellForItem(at: indexPath) {
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.layer.borderWidth = 0
            } else {
                thumbCollectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if collectionView == thumbCollectionView {
            return true
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if collectionView == thumbCollectionView {
            guard let soureImageModel = pickerController?.selectedImageModels[sourceIndexPath.item] else { return }
            pickerController?.selectedImageModels.remove(at: sourceIndexPath.item)
            pickerController?.selectedImageModels.insert(soureImageModel, at: destinationIndexPath.item)
            /// 重置选中按钮状态
            if let selectedIndex = pickerController?.selectedImageModels.index(of: imageModels[currentIndex]) {
                imageNavigationView.selectBtn.setSelectedIndex(selectedIndex)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == previewCollectionView {
            currentIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
            if currentIndex >= imageModels.count {
                currentIndex = imageModels.count - 1
            } else if currentIndex < 0 {
                currentIndex = 0
            }
            if let selectedIndex = pickerController?.selectedImageModels.index(of: imageModels[currentIndex]) {
                imageNavigationView.selectBtn.setSelectedIndex(selectedIndex)
                let selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
                thumbCollectionViewCellDidSelected(at: selectedIndexPath)
            } else {
                if thumbSelectedIndexPath != nil{
                    collectionView(thumbCollectionView, didDeselectItemAt: thumbSelectedIndexPath!)
                }
                imageNavigationView.selectBtn.setSelectedIndex(-1)
            }
        }
    }
    
}

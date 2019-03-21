//
//  HXImageToolView.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

/// 工具栏高度
let toolBarHeight = hxip_safeBottomHeight + hxip_toolBarHeight

class HXImageToolView: UIView {

    enum HXImageToolViewType {
        /// 在列表中
        case list
        /// 在预览中
        case preview
        /// 在裁剪中
        case clip
    }
    
    /// 主题颜色
    var mainTintColor: UIColor = .red {
        didSet {
            originBtn.setImage(hxip_generateOriginBtnImage(mainTintColor), for: .selected)
            if confirmBtn.isEnabled {
                confirmBtn.backgroundColor = mainTintColor
            } else {
                confirmBtn.backgroundColor = mainTintColor.withAlphaComponent(0.5)
            }
        }
    }
    
    var selectedImageCount: Int = 0 {
        didSet {
            if type == .list {
                previewBtn.isEnabled = selectedImageCount > 0
            }
            confirmBtn.isEnabled = selectedImageCount > 0
            confirmBtn.setTitle("完成\(selectedImageCount > 0 ? "(\(selectedImageCount))" : "")", for: .normal)
            if confirmBtn.isEnabled {
                confirmBtn.backgroundColor = mainTintColor
            } else {
                confirmBtn.backgroundColor = mainTintColor.withAlphaComponent(0.5)
            }
        }
    }
    
    var isOrigin: Bool = false {
        didSet {
            originBtn.isSelected = isOrigin
        }
    }
    
    // MARK: -  lazy loading
    
    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = .clear
        return contentView
    }()
        
    lazy var previewBtn: UIButton = {
        let previewBtn = UIButton()
        previewBtn.setTitle("预览", for: .normal)
        previewBtn.setTitleColor(.lightGray, for: .disabled)
        previewBtn.setTitleColor(.white, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        previewBtn.isEnabled = false
        return previewBtn
    }()
    
    lazy var editBtn: UIButton = {
        let previewBtn = UIButton()
        previewBtn.setTitle("编辑", for: .normal)
        previewBtn.setTitleColor(.lightGray, for: .disabled)
        previewBtn.setTitleColor(.white, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return previewBtn
    }()
    
    lazy var originBtn: UIButton = {
        let originBtn = UIButton()
        originBtn.setTitle("原图", for: .normal)
        originBtn.setImage(hxip_generateOriginBtnImage(), for: .normal)
        originBtn.setImage(hxip_generateOriginBtnImage(mainTintColor), for: .selected)
        originBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        originBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        return originBtn
    }()
    
    lazy var confirmBtn: UIButton = {
        let confirmBtn = UIButton()
        confirmBtn.setTitle("完成", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        confirmBtn.backgroundColor = mainTintColor.withAlphaComponent(0.5)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        confirmBtn.layer.cornerRadius = 5
        confirmBtn.isEnabled = false
        return confirmBtn
    }()
    
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setImage(UIImage(named: "HXImagePickerController.bundle/hxip_cancel"), for: .normal)
        return cancelBtn
    }()
    
    lazy var completeBtn: UIButton = {
        let completeBtn = UIButton()
        completeBtn.setImage(UIImage(named: "HXImagePickerController.bundle/hxip_confirm"), for: .normal)
        return completeBtn
    }()
    
    lazy var restoreBtn: UIButton = {
        let restoreBtn = UIButton()
        restoreBtn.setTitle("还原", for: .normal)
        restoreBtn.setTitleColor(.lightGray, for: .disabled)
        restoreBtn.setTitleColor(.white, for: .normal)
        restoreBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        restoreBtn.isEnabled = false
        return restoreBtn
    }()
    
    // 加一条分割线
    lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        lineView.isHidden = true
        return lineView
    }()
    
    private var type: HXImageToolViewType = .list
    
    init(frame: CGRect, type: HXImageToolViewType) {
        super.init(frame: frame)
        self.type = type
        setupUI()
        registerNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeNotifications()
    }
    
    private func setupUI() {
        backgroundColor = hxip_toolBarBackgroundColor
        addSubview(contentView)
        contentView.addSubview(lineView)
        switch type {
        case .list:
            contentView.addSubview(previewBtn)
            contentView.addSubview(originBtn)
            contentView.addSubview(confirmBtn)
        case .preview:
            contentView.addSubview(editBtn)
            contentView.addSubview(originBtn)
            contentView.addSubview(confirmBtn)
        case .clip:
            lineView.isHidden = false
            contentView.addSubview(cancelBtn)
            contentView.addSubview(completeBtn)
            contentView.addSubview(restoreBtn)
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(isOriginDidChangeed(_:)), name: .HXImagePickerIsOriginDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedImageModelsDidChangeed(_:)), name: .HXImagePickerSelectedImageModelsDidChanged, object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .HXImagePickerIsOriginDidChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .HXImagePickerSelectedImageModelsDidChanged, object: nil)
    }
    
    @objc private func isOriginDidChangeed(_ notification: Notification) {
        guard let isOrigin = notification.object as? Bool else { return }
        self.isOrigin = isOrigin
    }
    
    @objc private func selectedImageModelsDidChangeed(_ notification: Notification) {
        guard let models = notification.object as? [HXImageModel] else { return }
        selectedImageCount = models.count
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: hxip_toolBarHeight)
        lineView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 0.5)
        switch type {
        case .list:
            previewBtn.frame = CGRect(x: 0, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            originBtn.frame = CGRect(x: (contentView.bounds.width - 70) / 2, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            confirmBtn.frame = CGRect(x: contentView.bounds.width - 70, y: (contentView.bounds.height - 28) / 2, width: 60, height: 28)
        case .preview:
            editBtn.frame = CGRect(x: 0, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            originBtn.frame = CGRect(x: (contentView.bounds.width - 70) / 2, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            confirmBtn.frame = CGRect(x: contentView.bounds.width - 70, y: (contentView.bounds.height - 28) / 2, width: 60, height: 28)
        case .clip:
            cancelBtn.frame = CGRect(x: 0, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            restoreBtn.frame = CGRect(x: (contentView.bounds.width - 70) / 2, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
            completeBtn.frame = CGRect(x: contentView.bounds.width - 70, y: (contentView.bounds.height - 44) / 2, width: 70, height: 44)
        }
    }
    
}

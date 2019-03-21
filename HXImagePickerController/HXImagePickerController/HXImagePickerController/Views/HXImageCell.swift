//
//  HXImageCell.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXImageCell: UICollectionViewCell {
    
    ///  数据源
    var imageModel: HXImageModel? {
        didSet {
            guard let imageModel = imageModel else { return }
            selectBtn.setSelectedIndex(imageModel.selectedIndex)
            imageView.image = imageModel.thumbImage
            imageModel.requestThumbImage { [weak self] (model, thumbImage) in
                guard let `self` = self, self.imageModel == model else { return }
                self.imageView.image = thumbImage
            }
            if imageModel.mediaType == .video {
                videoView.isHidden = false
                videoDurationLabel.text = hxip_formatVideoDuration(imageModel.phAsset.duration)
            } else {
                videoView.isHidden = true
                videoDurationLabel.text = ""
            }
            videoDurationLabel.sizeToFit()
            editedIconImageView.isHidden = !imageModel.isEdited
            maskForegroundView.isHidden = imageModel.canSelect
        }
    }
    
    /// 选中按钮点击回调
    var selectBtnClickedCallback: ((HXImageCell) -> ())?
    
    /// 主题颜色
    var mainTintColor: UIColor = .red {
        didSet {
            selectBtn.mainTintColor = mainTintColor
        }
    }
    
    // MARK: -  懒加载
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var videoView: UIView = {
        let videoView = UIView()
        videoView.isHidden = true
        return videoView
    }()
    
    lazy var editedIconImageView: UIImageView = {
        let editedIconImageView = UIImageView()
        editedIconImageView.image = UIImage(named: "HXImagePickerController.bundle/hxip_edited")
        editedIconImageView.isHidden = true
        return editedIconImageView
    }()
    
    lazy var videoIconImageView: UIImageView = {
        let videoIconImageView = UIImageView()
        videoIconImageView.image = UIImage(named: "HXImagePickerController.bundle/hxip_video")
        return videoIconImageView
    }()
    
    lazy var videoDurationLabel: UILabel = {
        let videoDurationLabel = UILabel()
        videoDurationLabel.font = UIFont.boldSystemFont(ofSize: 12)
        videoDurationLabel.textColor = .white
        return videoDurationLabel
    }()
    
    lazy var selectBtn: HXSelectButton = {
        let selectBtn = HXSelectButton()
        selectBtn.imageSize = CGSize(width: 24, height: 24)
        selectBtn.addTarget(self, action: #selector(selectBtnClicked), for: .touchUpInside)
        return selectBtn
    }()
    
    lazy var maskForegroundView: UIView = {
        let maskForegroundView = UIView()
        maskForegroundView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        maskForegroundView.isHidden = true
        return maskForegroundView
    }()
    
    // MARK: -  Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(selectBtn)
        addSubview(videoView)
        videoView.addSubview(videoIconImageView)
        videoView.addSubview(videoDurationLabel)
        addSubview(editedIconImageView)
        addSubview(maskForegroundView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        selectBtn.frame = CGRect(x: bounds.width - 40, y: 0, width: 40, height: 40)
        videoView.frame = CGRect(x: 0, y: bounds.height - 20, width: bounds.width, height: 14)
        editedIconImageView.frame = CGRect(x: 8, y: bounds.height - 20, width: 17, height: 13)
        videoIconImageView.frame = CGRect(x: 8, y: 1, width: 18, height: 12)
        videoDurationLabel.sizeToFit()
        videoDurationLabel.frame = CGRect(x: videoIconImageView.frame.maxX + 6, y: 0, width: videoDurationLabel.frame.width, height: 14)
        maskForegroundView.frame = bounds
    }
    
    /// 点击
    @objc private func selectBtnClicked() {
        selectBtnClickedCallback?(self)
    }
    
}

//
//  HXSelectButton.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXSelectButton: UIButton {

    /// 主题颜色
    var mainTintColor: UIColor = .red {
        didSet {
            sortLabel.backgroundColor = mainTintColor
        }
    }
    
    /// 图片size
    var imageSize: CGSize = .zero {
        didSet {
            sortLabel.font = UIFont.systemFont(ofSize: imageSize.width / 2)
            sortLabel.frame = CGRect(origin: .zero, size: imageSize)
            sortLabel.layer.cornerRadius = imageSize.width / 2
            selectImageView.frame = CGRect(origin: .zero, size: imageSize)
            setNeedsLayout()
        }
    }
    
    /// 懒加载顺序label
    private lazy var sortLabel: UILabel = {
        let sortLabel = UILabel(frame: .zero)
        sortLabel.textColor = .white
        sortLabel.textAlignment = .center
        sortLabel.backgroundColor = mainTintColor
        sortLabel.layer.masksToBounds = true
        sortLabel.isHidden = true
        return sortLabel
    }()
    
    /// 懒加载图片
    private lazy var selectImageView: UIImageView = {
        let selectImageView = UIImageView(frame: .zero)
        selectImageView.image = UIImage(named: "HXImagePickerController.bundle/hxip_select")
        return selectImageView
    }()
    
    // MARK: -  Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(sortLabel)
        addSubview(selectImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sortLabel.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        selectImageView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    /// 设置当前为第几个选中的
    ///
    /// - Parameter index: 当前为第几个选中的
    func setSelectedIndex(_ index: Int) {
        selectImageView.isHidden = index >= 0
        sortLabel.isHidden = index < 0
        sortLabel.text = "\(index + 1)"
    }

}

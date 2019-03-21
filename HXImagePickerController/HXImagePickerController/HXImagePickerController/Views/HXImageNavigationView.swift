//
//  HXImageNavigationView.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/3/14.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXImageNavigationView: UIView {

    /// 主题颜色
    var mainTintColor: UIColor = .red {
        didSet {
            selectBtn.mainTintColor = mainTintColor
        }
    }
    
    lazy var selectBtn: HXSelectButton = {
        let selectBtn = HXSelectButton()
        selectBtn.imageSize = CGSize(width: 30, height: 30)
        return selectBtn
    }()
    
    lazy var backBtn: UIButton = {
        let backBtn = UIButton()
        backBtn.setImage(UIImage(named: "HXImagePickerController.bundle/hxip_back"), for: .normal)
        return backBtn
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = .clear
        return contentView
    }()
    
    private var contentHeight: CGFloat = 0
    
    // MARK: -  Life Cycle
    
    init(frame: CGRect, contentHeight: CGFloat) {
        super.init(frame: frame)
        backgroundColor = hxip_toolBarBackgroundColor
        self.contentHeight = contentHeight
        addSubview(contentView)
        contentView.addSubview(selectBtn)
        contentView.addSubview(backBtn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = CGRect(x: 0, y: bounds.height - contentHeight, width: bounds.width, height: contentHeight)
        backBtn.frame = CGRect(x: 0, y: (contentHeight - 44) / 2, width: 44, height: 44)
        selectBtn.frame = CGRect(x: bounds.width - 54, y: (contentHeight - 44) / 2, width: 44, height: 44)
    }

}

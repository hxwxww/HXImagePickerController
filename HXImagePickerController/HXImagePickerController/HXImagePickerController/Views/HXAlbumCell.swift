//
//  HXAlbumCell.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit
import Photos

class HXAlbumCell: UITableViewCell {

    /// 数据源
    var albumModel: HXAlbumModel? {
        didSet {
            guard let albumModel = albumModel else { return }
            nameLabel.text = albumModel.albumName
            countLabel.text = "(\(albumModel.fetchAssets.count))"
            coverImageView.image = albumModel.coverImage
            albumModel.requestCoverImage { [weak self] (model, coverImage) in
                guard let `self` = self, self.albumModel == model else { return }
                self.coverImageView.image = coverImage
            }
            setNeedsLayout()
        }
    }
    
    // MARK: -  懒加载
    
    lazy var coverImageView: UIImageView = {
        let coverImageView = UIImageView()
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        return coverImageView
    }()
    
    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .black
        return nameLabel
    }()
    
    lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.textColor = .lightGray
        return countLabel
    }()
    
    lazy var bottomLineView: UIView = {
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        return bottomLineView
    }()
    
    // MARK: -  Life Cycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        addSubview(coverImageView)
        addSubview(nameLabel)
        addSubview(countLabel)
        addSubview(bottomLineView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageView.frame = CGRect(x: 15, y: 8, width: bounds.height - 16, height: bounds.height - 16)
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: coverImageView.frame.maxX + 8, y: (bounds.height - nameLabel.frame.height) / 2, width: nameLabel.frame.width, height: nameLabel.frame.height)
        countLabel.sizeToFit()
        countLabel.frame = CGRect(x: nameLabel.frame.maxX + 8, y: (bounds.height - countLabel.frame.height) / 2, width: countLabel.frame.width, height: countLabel.frame.height)
        bottomLineView.frame = CGRect(x: 15, y: bounds.height - 0.5, width: bounds.width - 15, height: 0.5)
    }

}

//
//  HXImageModel.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit
import Photos

class HXImageModel: NSObject {
    
    /// 系统资源对象
    private (set) var phAsset: PHAsset
    
    /// 资源id
    var assetId: String {
        return phAsset.localIdentifier
    }
    
    /// 媒体类型
    var mediaType: PHAssetMediaType {
        return phAsset.mediaType
    }
    
    /// 缩略图（将缩略图缓存，占用的内存可以接受）
    private (set) var thumbImage: UIImage?
    
    /// 是否选中
    private (set) var isSelected: Bool = false
    
    /// 当前选中的序号，未选中为-1
    var selectedIndex: Int = -1 {
        didSet {
            isSelected = selectedIndex >= 0
        }
    }
    
    /// 是否可以选择，默认为true
    var canSelect: Bool = true
    
    /// 编辑之后的图片
    var editedImage: UIImage? {
        didSet {
            thumbImage = editedImage
            isEdited = true
        }
    }
    
    /// 是否已经编辑过
    private (set) var isEdited: Bool = false
    
    /// 初始化
    ///
    /// - Parameter assetCollection: 系统资源对象
    init(_ phAsset: PHAsset) {
        self.phAsset = phAsset
    }
    
    /// 加载缩略图
    func requestThumbImage(_ completion: ((_ model: HXImageModel, _ thumbImage: UIImage?) -> ())?) {
        if let thumbImage = thumbImage {
            completion?(self, thumbImage)
        } else {
            HXPhotoImageManager.requestThumbImage(for: phAsset) { [weak self] (image, finished) in
                guard let `self` = self else { return }
                self.thumbImage = image
                completion?(self, image)
            }
        }
    }
    
    // MARK: -  Equatable
    
    static func == (lhs: HXImageModel, rhs: HXImageModel) -> Bool {
        return lhs.assetId == rhs.assetId
    }
    
}

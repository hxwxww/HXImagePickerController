//
//  HXAlbumModel.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import Foundation
import Photos

class HXAlbumModel: NSObject {
    
    /// 系统相册对象
    private (set) var assetCollection: PHAssetCollection
    
    /// 相册名称
    var albumName: String? {
        return assetCollection.localizedTitle
    }
    
    /// 相册id
    var albumId: String {
        return assetCollection.localIdentifier
    }
    
    /// 相册的照片资源
    private (set) var fetchAssets: PHFetchResult<PHAsset>
    
    /// 封面图
    private (set) var coverImage: UIImage?
    
    /// 初始化
    ///
    /// - Parameter assetCollection: 系统相册对象
    init(_ assetCollection: PHAssetCollection, mediaTypes: [PHAssetMediaType] = [.image, .video]) {
        self.assetCollection = assetCollection
        fetchAssets = HXPhotoImageManager.getPhotoAssets(for: assetCollection, with: mediaTypes)
    }
    
    /// 获取封面图
    func requestCoverImage(_ completion: ((_ model: HXAlbumModel, _ coverImage: UIImage?) -> ())?) {
        if let coverImage = coverImage {
            completion?(self, coverImage)
        } else {
            guard let firstAsset = fetchAssets.firstObject else {
                completion?(self, nil)
                return
            }
            HXPhotoImageManager.requestThumbImage(for: firstAsset) { [weak self] (image, finished) in
                guard let `self` = self else { return }
                self.coverImage = image
                completion?(self, image)
            }
        }
    }
    
    // MARK: -  Equatable
    
    static func == (lhs: HXAlbumModel, rhs: HXAlbumModel) -> Bool {
        return lhs.albumId == rhs.albumId
    }
    
}

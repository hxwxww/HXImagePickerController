//
//  HXPhotoImageManager.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import Foundation
import Photos

// MARK: -  自定义相册类型枚举
struct HXPhotoAlbumType: OptionSet {
    
    let rawValue: Int
    
    /// 用户智能相册 PHAssetCollectionType: smartAlbum PHAssetCollectionSubtype: smartAlbumUserLibrary
    static let smartAlbum = HXPhotoAlbumType(rawValue: 1 << 0)
    
    /// 用户创建的相册 fetchTopLevelUserCollections
    static let userAlbum = HXPhotoAlbumType(rawValue: 1 << 1)
    
    /// iPhone中同步的相册 PHAssetCollectionType: album PHAssetCollectionSubtype: albumSyncedAlbum
    static let syncedAlbum = HXPhotoAlbumType(rawValue: 1 << 2)
    
    /// iCloud中同步的相册 PHAssetCollectionType: album PHAssetCollectionSubtype: albumMyPhotoStream
    static let iCloudAlbum = HXPhotoAlbumType(rawValue: 1 << 3)
    
    /// iCloud分享的相册 PHAssetCollectionType: album PHAssetCollectionSubtype: albumCloudShared
    static let iCloudShared = HXPhotoAlbumType(rawValue: 1 << 4)
    
    /// 所有相册
    static let all: HXPhotoAlbumType = [.smartAlbum, .userAlbum, .syncedAlbum, .iCloudAlbum, .iCloudShared]
    
}

// MARK: -  系统相册管理器
class HXPhotoImageManager {
    
    /// 获取相册授权状态
    ///
    /// - Parameter handler: 回调处理闭包，success表示是否已授权
    static func getPhotoLibraryAuthorization(_ handler: @escaping (_ success: Bool) -> ()) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            handler(true)
        case .denied, .restricted:
            handler(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                /// 主线程回调
                DispatchQueue.main.async {
                    handler(newStatus == .authorized)
                }
            }
        }
    }
    
    /// 获取相机授权状态
    ///
    /// - Parameter handler: 回调处理闭包，success表示是否已授权
    static func getCameraAuthorization(_ handler: @escaping (_ success: Bool) -> ()) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            handler(true)
        case .denied, .restricted:
            handler(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (accessed) in
                /// 主线程回调
                DispatchQueue.main.async {
                    handler(accessed)
                }
            }
        }
    }
    
    /// 获取手机中的相册
    ///
    /// - Parameters:
    ///   - albumType: 相册类型，默认为[.smartAlbum, .userAlbum]
    ///   - filterEmpty: 过滤空相册，默认为true
    /// - Returns: 相册集合
    static func getPhotoAlbums(with albumType: HXPhotoAlbumType = [.smartAlbum, .userAlbum], filterEmpty: Bool = true) -> [PHAssetCollection] {
        var albums = [PHAssetCollection]()
        if albumType.contains(.smartAlbum) { /// 系统智能相册
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            smartAlbums.enumerateObjects { (assetCollection, index, stop) in
                if !filterEmpty || assetCollection.estimatedAssetCount > 0 {
                    albums.append(assetCollection)
                }
            }
        }
        if albumType.contains(.userAlbum) { /// 用户创建的相册
            let userAlbums = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
            userAlbums.enumerateObjects { (collection, index, stop) in
                if let assetCollection = collection as? PHAssetCollection {
                    if !filterEmpty || assetCollection.estimatedAssetCount > 0 {
                        albums.append(assetCollection)
                    }
                }
            }
        }
        if albumType.contains(.syncedAlbum) { /// iPhone中同步的相册
            let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil)
            syncedAlbums.enumerateObjects { (assetCollection, index, stop) in
                if !filterEmpty || assetCollection.estimatedAssetCount > 0 {
                    albums.append(assetCollection)
                }
            }
        }
        if albumType.contains(.iCloudAlbum) { /// iCloud中同步的相册
            let iCloudAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil)
            iCloudAlbums.enumerateObjects { (assetCollection, index, stop) in
                if !filterEmpty || assetCollection.estimatedAssetCount > 0 {
                    albums.append(assetCollection)
                }
            }
        }
        if albumType.contains(.iCloudAlbum) { /// iCloud分享的相册
            let iCloudShared = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
            iCloudShared.enumerateObjects { (assetCollection, index, stop) in
                if !filterEmpty || assetCollection.estimatedAssetCount > 0 {
                    albums.append(assetCollection)
                }
            }
        }
        return albums
    }
    
    /// 获取相册中的资源
    ///
    /// - Parameters:
    ///   - assetCollection: 相册
    ///   - mediaTypes: 资源类型，默认[.image, .video]
    /// - Returns: 资源集合
    static func getPhotoAssets(for assetCollection: PHAssetCollection, with mediaTypes: [PHAssetMediaType] = [.image, .video]) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        if mediaTypes.count > 0 {
            // 拼接条件语句
            var predicateFormat = ""
            for i in 0 ..< mediaTypes.count {
                let mediaType = mediaTypes[i]
                if i == mediaTypes.count - 1 {
                    predicateFormat += "mediaType == \(mediaType.rawValue)"
                } else {
                    predicateFormat += "mediaType == \(mediaType.rawValue) || "
                }
            }
            options.predicate = NSPredicate(format: predicateFormat)
        }
        // 按创建时间排序
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let phAssets = PHAsset.fetchAssets(in: assetCollection, options: options)
        return phAssets
    }
    
    /// 异步获取图片
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - targetSize: 图片目标尺寸
    ///   - contentMode: 图片处理模式，默认aspectFill
    ///   - completion: 完成的回调，image是图片， finished表示是否完成
    /// - Returns: 请求id
    @discardableResult
    static func requestImageAsynchronous(for phAsset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill, completion: @escaping (_ image: UIImage?, _ finished: Bool) -> ()) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        /// isSynchronous设置为false异步获取
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        /// highQualityFormat: 直接返回最好的图片，fastFormat: 直接返回较差的图片，opportunistic: 返回多次图片，质量由差到好
        options.deliveryMode = .highQualityFormat
        let imageRequestID = PHImageManager.default().requestImage(for: phAsset, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) in
            // 是否取消
            let cancelled = info?[PHImageCancelledKey] as? Bool ?? false
            // 是否有错误
            let hasError = info?[PHImageErrorKey] != nil
            // 请求结果是否不完全
            let degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            /// 没有取消、没有错误、请求结果完整才算完成
            let finished = !cancelled && !hasError && !degraded
            /// 异步请求默认在主线程回调
            completion(image, finished)
        }
        return imageRequestID
    }
    
    /// 异步获取图片数据，数据为原图的数据
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - completion: 完成的回调，data是原图的图片数据，finished表示是否完成
    /// - Returns: 请求id
    @discardableResult
    static func requestImageDataAsynchronous(for phAsset: PHAsset, completion: @escaping (_ data: Data?, _ finished: Bool) -> ()) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        let imageRequestID = PHImageManager.default().requestImageData(for: phAsset, options: options) { (data, dataUTI, orientation, info) in
            // 是否取消
            let cancelled = info?[PHImageCancelledKey] as? Bool ?? false
            // 是否有错误
            let hasError = info?[PHImageErrorKey] != nil
            // 请求结果是否不完全
            let degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            /// 没有取消、没有错误、请求结果完整才算完成
            let finished = !cancelled && !hasError && !degraded
            /// 异步请求默认在主线程回调
            completion(data, finished)
        }
        return imageRequestID
    }
    
    /// 获取视频资源
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - completion: 完成的回调，avAsset是视频资源, videoPath是视频存储路径
    /// - Returns: 请求id
    @discardableResult
    static func requestAVAsset(for phAsset: PHAsset, completion: @escaping (_ avAsset: AVAsset?, _ videoPath: String?) -> ()) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        let imageRequestID = PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { (avAsset, audioMix, info) in
            /// 主线程回调
            DispatchQueue.main.async {
                completion(avAsset, (avAsset as? AVURLAsset)?.url.path)
            }
        }
        return imageRequestID
    }
    
    /// 保存图片到相册
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - completion: 完成的回调，success是否成功
    static func saveImageToAlbum(image: UIImage, completion: @escaping (_ success: Bool) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (success, error) in
            /// 主线程回调
            DispatchQueue.main.async {
                completion(success)
            }
        })
    }
    
    /// 保存视频到相册
    ///
    /// - Parameters:
    ///   - videoPath: 视频文件路径
    ///   - completion: 完成的回调，success是否成功
    static func saveVideoToAlbum(videoPath: String, completion: @escaping (_ success: Bool) -> ()) {
        let videoUrl = URL(fileURLWithPath: videoPath)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }, completionHandler: { (success, error) in
            /// 主线程回调
            DispatchQueue.main.async {
                completion(success)
            }
        })
    }
    
    /// 取消图片请求
    ///
    /// - Parameter imageRequestID: 请求id
    static func cancelImageRequest(imageRequestID: PHImageRequestID) {
        PHImageManager.default().cancelImageRequest(imageRequestID)
    }
    
}

// MARK: -  封装的业务方法
extension HXPhotoImageManager {
    
    /// 获取缩略图
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - completion: 完成的回调
    /// - Returns: 请求id
    @discardableResult
    static func requestThumbImage(for phAsset: PHAsset, completion: @escaping (_ image: UIImage?, _ finished: Bool) -> ()) -> PHImageRequestID {
        let targetSize = CGSize(width: 200, height: 200)
        return requestImageAsynchronous(for: phAsset, targetSize: targetSize, completion: completion)
    }
    
    /// 获取预览图
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - completion: 完成的回调
    /// - Returns: 请求id
    @discardableResult
    static func requestPreviewImage(for phAsset: PHAsset, completion: @escaping (_ image: UIImage?, _ finished: Bool) -> ()) -> PHImageRequestID {
        let targetSize = getPriviewSize(originSize: CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight))
        return requestImageAsynchronous(for: phAsset, targetSize: targetSize, completion: completion)
    }
    
    /// 获取原图
    ///
    /// - Parameters:
    ///   - phAsset: 相册资源
    ///   - completion: 完成的回调
    /// - Returns: 请求id
    @discardableResult
    static func requestOriginImage(for phAsset: PHAsset, completion: @escaping (_ image: UIImage?, _ finished: Bool) -> ()) -> PHImageRequestID {
        return requestImageDataAsynchronous(for: phAsset, completion: { (imageData, finished) in
            let image = imageData != nil ? UIImage(data: imageData!) : nil
            completion(image, finished)
        })
    }
    
    /// 根据原图大小，计算预览图大小
    ///
    /// - Parameters:
    ///   - originSize: 原图大小
    ///   - standard: 基准宽高
    /// - Returns: 预览图大小
    static func getPriviewSize(originSize: CGSize, standard: CGFloat = 1280) -> CGSize {
        let width = originSize.width
        let height = originSize.height
        let pixelScale = width / height
        var targetSize = CGSize.zero
        if width <= standard && height <= standard {
            // 图片宽或者高均小于或等于standard时图片尺寸保持不变，不改变图片大小
            targetSize.width = width
            targetSize.height = height
        } else if width > standard && height > standard {
            // 宽以及高均大于standard，但是图片宽高比例大于(小于)2时，则宽或者高取小(大)的等比压缩至standard
            if pixelScale > 2 {
                targetSize.width = standard * pixelScale
                targetSize.height = standard
            } else if pixelScale < 0.5 {
                targetSize.width = standard
                targetSize.height = standard / pixelScale
            } else if pixelScale > 1 {
                targetSize.width = standard
                targetSize.height = standard / pixelScale
            } else {
                targetSize.width = standard * pixelScale
                targetSize.height = standard
            }
        } else {
            // 宽或者高大于standard，但是图片宽度高度比例小于或等于2，则将图片宽或者高取大的等比压缩至standard
            if pixelScale <= 2 && pixelScale > 1 {
                targetSize.width = standard
                targetSize.height = standard / pixelScale
            } else if pixelScale > 0.5 && pixelScale <= 1 {
                targetSize.width = standard * pixelScale
                targetSize.height = standard
            } else {
                targetSize.width = width
                targetSize.height = height
            }
        }
        return targetSize
    }
    
}

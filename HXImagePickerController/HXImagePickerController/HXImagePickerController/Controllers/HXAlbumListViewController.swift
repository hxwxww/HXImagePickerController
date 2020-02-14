//
//  HXAlbumListViewController.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

class HXAlbumListViewController: UIViewController {

    /// 懒加载tableView
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.hx_registerCell(cellClass: HXAlbumCell.self)
        return tableView
    }()
    
    /// 数据源
    private var albums: [HXAlbumModel] = []
    
    /// 所在的导航控制器
    private weak var pickerController: HXImagePickerController? {
        return navigationController as? HXImagePickerController
    }
        
    deinit {
        HXLog("HXAlbumListViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// 首先push到图片列表vc
        pushToImageListVC(albumModel: nil, animated: false)
        /// 设置属性
        title = "照片"
        view.backgroundColor = .white
        view.addSubview(tableView)
        setupCancelItem()
        requestAlbumModels()
    }
    
    private func requestAlbumModels() {
        HXPhotoImageManager.getPhotoLibraryAuthorization { [weak self] (success) in
            guard let `self` = self else { return }
            if success {
                let mediaTypes = self.pickerController?.mediaTypes ?? [.image, .video]
                DispatchQueue.global().async {
                    let photoAlbums = HXPhotoImageManager.getPhotoAlbums()
                    var albumModels = [HXAlbumModel]()
                    for assetCollection in photoAlbums {
                        let albumModel = HXAlbumModel(assetCollection, mediaTypes: mediaTypes)
                        albumModels.append(albumModel)
                    }
                    DispatchQueue.main.async {
                        self.albums = albumModels
                        self.tableView.reloadData()
                        /// 设置首次push的图片列表页的相册模型
                        if let imageListVC = self.navigationController?.topViewController as? HXImageListViewController {
                            imageListVC.albumModel = self.albums[0]
                        }
                    }
                }
            } else {
                self.pickerController?.showAuthorizationAlert()
            }
        }
    }
    
    /// 取消
    private func setupCancelItem() {
        let cancelItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelItemClicked))
        navigationItem.rightBarButtonItem = cancelItem
    }
    
    @objc private func cancelItemClicked() {
        pickerController?.cancelSelect()
    }
    
    /// 跳转到照片列表页
    ///
    /// - Parameters:
    ///   - albumModel: 相册模型
    ///   - animated: 是否跳转动画
    private func pushToImageListVC(albumModel: HXAlbumModel?, animated: Bool) {
        let imageListVC = HXImageListViewController()
        imageListVC.albumModel = albumModel
        navigationController?.pushViewController(imageListVC, animated: animated)
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HXAlbumListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.hx_dequeueReusableCell(indexPath: indexPath) as HXAlbumCell
        cell.albumModel = albums[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        pushToImageListVC(albumModel: albums[indexPath.row], animated: true)
    }
    
}

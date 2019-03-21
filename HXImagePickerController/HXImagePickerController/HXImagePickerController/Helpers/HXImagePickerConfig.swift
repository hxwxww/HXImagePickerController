//
//  HXImagePickerConfig.swift
//  HXImagePickerController
//
//  Created by HongXiangWen on 2019/2/28.
//  Copyright © 2019年 WHX. All rights reserved.
//

import UIKit

// MARK: - 尺寸相关

/// 屏幕bounds
let hxip_screenBounds = UIScreen.main.bounds

/// 屏幕尺寸
let hxip_screenSize = hxip_screenBounds.size

/// 屏幕宽度
let hxip_screenWidth = hxip_screenSize.width

/// 获取屏幕高度
let hxip_screenHeight = hxip_screenSize.height

/// 是否是IPhoneX
let hxip_isIPhoneX = hxip_screenSize.equalTo(CGSize(width: 414, height: 896)) || hxip_screenSize.equalTo(CGSize(width: 896, height: 414)) || hxip_screenSize.equalTo(CGSize(width: 375, height: 812)) || hxip_screenSize.equalTo(CGSize(width: 812, height: 375))

/// 获取状态栏高度
let hxip_statusBarHeight: CGFloat = hxip_isIPhoneX ? 44 : 20

/// 导航栏高度
let hxip_navigationBarHeight: CGFloat = 44.0

/// 顶部安全高度
let hxip_safeTopHeight = hxip_statusBarHeight + hxip_navigationBarHeight

/// 底部安全高度
let hxip_safeBottomHeight: CGFloat = hxip_isIPhoneX ? 34 : 0

/// 工具栏高度
let hxip_toolBarHeight: CGFloat = 49.0

/// 工具栏背景颜色
let hxip_toolBarBackgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.97)

// MARK: -  自定义方法

/// 自定义log
///
/// - Parameters:
///   - message: 打印信息
///   - filePath: 文件路径
///   - methodName: 方法名
///   - line: 行数
public func HXLog<T>(_ message: T, filePath: String = #file, methodName: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (filePath as NSString).lastPathComponent.components(separatedBy: ".").first!
    print("==>> \(fileName).\(methodName)[\(line)]: \(message) \n")
    #endif
}

/// 视频时间格式化
func hxip_formatVideoDuration(_ duration: TimeInterval) -> String {
    var formatString: String
    if duration < 60 {
        formatString = String(format: "00:%.2ld", Int(duration))
    } else if duration >= 60 && duration <= 36000 {
        formatString = String(format: "%.2ld:%.2ld", Int(duration) / 60, Int(duration) % 60)
    } else {
        formatString = String(format: "%.2ld:%.2ld:%.2ld", Int(duration) / 3600, Int(duration) % 3600 / 60, Int(duration) % 60)
    }
    return formatString
}

/// 生成原图按钮的图片
///
/// - Parameter color: 选中颜色color，如果为nil则是正常图片，否则为选中图片
/// - Returns: 图片
func hxip_generateOriginBtnImage(_ color: UIColor? = nil) -> UIImage? {
    let size = CGSize(width: 20, height: 20)
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer {
        UIGraphicsEndImageContext()
    }
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.setLineWidth(1)
    context.setStrokeColor(UIColor.white.cgColor)
    context.addArc(center: CGPoint(x: size.width / 2, y: size.height / 2), radius: (size.width / 2) - 2, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: false)
    context.strokePath()
    if let color = color {
        context.setFillColor(color.cgColor)
        context.addArc(center: CGPoint(x: size.width / 2, y: size.height / 2), radius: (size.width / 2) - 5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: false)
        context.fillPath()
    }
    guard let image = UIGraphicsGetImageFromCurrentImageContext(),
        let imageRef = image.cgImage else { return nil }
    return UIImage(cgImage: imageRef, scale: scale, orientation: .up)
}

//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/14/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        // 1
        let downloadTask = session.downloadTask(with: url, // create download task to save downloaded file to disk
        completionHandler: { [weak self] url, response, error in // call completion handler after file downloaded on to disk
        // 2
        if error == nil, let url = url,
        let data = try? Data(contentsOf: url), // load local url file into a data object
        // 3
        let image = UIImage(data: data) { // create an image from the retrieved data object
        // 4 only want to set image property if self (imageView) still exists
        DispatchQueue.main.async { // ui code is done on main thread
            if let weakSelf = self { // we look if self still exists (self refers to imageView)
                weakSelf.image = image // in main thread, load the image into image property
                }
            // else there is no image view to set the image on
            }
            }
        })
        // 5
        downloadTask.resume() // start downloadTask
        return downloadTask // return to caller so cancel() can be called
    }
}

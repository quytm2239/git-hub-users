//
//  ImageDownloader.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit
import CoreData

class ImageDownloader: NSObject {
    
    static let current = ImageDownloader()
    private override init() { super.init() }
    
    private var container: NSPersistentContainer!
    private var backgroundContext: NSManagedObjectContext!
    fileprivate static var currentContext: NSManagedObjectContext {
        return current.backgroundContext
    }
    
    lazy var downloadPool: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "IMAGE_DOWNLOADER_DOWNLOAD_POOL"
        // I use this 3 concurrent operations for better performance
        // We can it to one by one img downloading here, set it to 1
        // But it is quite slow to finish all list img
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    let persistQueue = DispatchQueue(label: "IMAGE_DOWNLOADER_CACHE_QUEUE")
    
    static func firstSetup() {
        current.container = NSPersistentContainer(name: "ResourceCaching")
        
        current.container.loadPersistentStores { storeDescription, error in
            if let error = error {
                Logger.error("IMAGE_DOWNLOADER", error.localizedDescription, #fileID, #line)
            }
        }
        current.backgroundContext = current.container.newBackgroundContext()
    }
    
    static func saveContext() {
        let context = current.backgroundContext!
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                Logger.error("IMAGE_DOWNLOADER", nserror.localizedDescription, #fileID, #line)
            }
        }
    }
    
    static func pauseAllDownload() {
        current.downloadPool.isSuspended = true
    }
    
    static func forceDownload(setNeedToBeDownloaded: Set<String>) {
        
        for (key, value) in current.dictDownloadedImage {
            if !setNeedToBeDownloaded.contains(key) && !value.isFinished {
                // here are all downloaders that need to be cancelled to allow new
                // force it become cancelled and change state to error
                // we can retry/renew it later
                if !value.isCancelled { value.cancel() }
                value.clearListener()
                value.state = .error
            }
        }
        
        // resume the download queue
        current.downloadPool.isSuspended = false
    }
    
    private var dictDownloadedImage: [String: DownloadedImageInfo] = [:]
    static func loadImage(imgURL: String, completion: @escaping (String, UIImage?) -> Void) {
        if let imageData = current.dictDownloadedImage[imgURL] {
            imageData.onFinishLoadImg = { image, loadedURL in
                completion(loadedURL, image)
            }
            
            if let image = imageData.image {
                completion(imgURL, image)
            } else {
                if imageData.state == .error {
                    imageData.cancel()
                    imageData.clearListener()
                    current.dictDownloadedImage.removeValue(forKey: imgURL)
                    
                    // Replace old downloader with new downloader, but still same img url
                    let item = DownloadedImageInfo.init(state: .new, url: imgURL, image: nil)
                    current.dictDownloadedImage.updateValue(item, forKey: imgURL)
                    
                    item.onFinishLoadImg = { image, loadedURL in
                        completion(loadedURL, image)
                    }
                    
                    loadLocalImg(urlStr: imgURL) { localImg, loadedURL in
                        if loadedURL == imgURL {
                            if localImg == nil {
                                current.downloadPool.addOperation(item)
                            } else {
                                item.image = localImg
                                item.state = .done
                                item.triggerFinish()
                            }
                        }
                    }
                    
                } else {
                    loadLocalImg(urlStr: imgURL) { localImg, loadedURL in
                        if loadedURL == imgURL {
                            if localImg == nil {
                                completion(imgURL, nil)
                            } else {
                                completion(imgURL, localImg)
                            }
                        }
                    }
                }
            }
        } else {
            let item = DownloadedImageInfo.init(state: .new, url: imgURL, image: nil)
            current.dictDownloadedImage.updateValue(item, forKey: imgURL)
            
            item.onFinishLoadImg = { image, loadedURL in
                completion(loadedURL, image)
            }
            
            loadLocalImg(urlStr: imgURL) { localImg, loadedURL in
                if loadedURL == imgURL {
                    if localImg == nil {
                        current.downloadPool.addOperation(item)
                    } else {
                        item.image = localImg
                        item.state = .done
                        item.triggerFinish()
                    }
                }
            }
        }
    }
    
    static func loadImage(imgURL: String, index: IndexPath, completion: @escaping (String, UIImage?, IndexPath) -> Void) {
        if let imgDownloaderInfo = current.dictDownloadedImage[imgURL] {
            
            imgDownloaderInfo.indexPath = index // update to new index
            imgDownloaderInfo.onFinishLoadImgIndex = { image, loadedURL, index in
                completion(loadedURL, image, index)
            }
            
            switch imgDownloaderInfo.state {
            case .done: imgDownloaderInfo.triggerFinish()
            case .error:
                imgDownloaderInfo.cancel()
                imgDownloaderInfo.clearListener()
                current.dictDownloadedImage.removeValue(forKey: imgURL)
                
                // Replace old downloader with new downloader, but still same img url
                let newImgDownloaderInfo = DownloadedImageInfo.init(state: .new, url: imgURL, image: nil, indexPath: index)
                current.dictDownloadedImage.updateValue(newImgDownloaderInfo, forKey: imgURL)
                
                newImgDownloaderInfo.onFinishLoadImgIndex = { image, loadedURL, index in
                    completion(loadedURL, image, index)
                }
                
                loadLocalImg(urlStr: imgURL) { localImg, loadedURL in
                    if loadedURL == imgURL {
                        if localImg == nil {
                            current.downloadPool.addOperation(newImgDownloaderInfo)
                        } else {
                            newImgDownloaderInfo.image = localImg
                            newImgDownloaderInfo.state = .done
                            newImgDownloaderInfo.triggerFinish()
                        }
                    }
                }
                
            case .loading, .new:
                if imgDownloaderInfo.isCancelled {
                    imgDownloaderInfo.clearListener()
                    current.dictDownloadedImage.removeValue(forKey: imgURL)
                    
                    // Replace old downloader with new downloader, but still same img url
                    let newImgDownloaderInfo = DownloadedImageInfo.init(state: .new, url: imgURL, image: nil, indexPath: index)
                    current.dictDownloadedImage.updateValue(newImgDownloaderInfo, forKey: imgURL)
                    
                    newImgDownloaderInfo.onFinishLoadImgIndex = { image, loadedURL, index in
                        completion(loadedURL, image, index)
                    }
                    current.downloadPool.addOperation(newImgDownloaderInfo)
                }
            }
        } else {
            // new downloader
            let newImgDownloaderInfo = DownloadedImageInfo.init(state: .new, url: imgURL, image: nil, indexPath: index)
            current.dictDownloadedImage.updateValue(newImgDownloaderInfo, forKey: imgURL)
            
            newImgDownloaderInfo.onFinishLoadImgIndex = { image, loadedURL, index in
                completion(loadedURL, image, index)
            }
            
            loadLocalImg(urlStr: imgURL) { localImg, loadedURL in
                if loadedURL == imgURL {
                    if localImg == nil {
                        current.downloadPool.addOperation(newImgDownloaderInfo)
                    } else {
                        newImgDownloaderInfo.image = localImg
                        newImgDownloaderInfo.state = .done
                        newImgDownloaderInfo.triggerFinish()
                    }
                }
            }
        }
    }
    
    static func syncLoadImage(imgURL: String) -> (String, UIImage?, DownloadedImageInfo.State) {
        if let imageData = current.dictDownloadedImage[imgURL] {
            if let image = imageData.image {
                return (imgURL, image, imageData.state)
            } else {
                return (imgURL, nil, imageData.state)
            }
        } else {
            return (imgURL, nil, .new)
        }
    }
    
    static func cancelDownload(imgURL: String) {
        if let imageData = current.dictDownloadedImage[imgURL] {
            imageData.cancel()
            imageData.clearListener()
            current.dictDownloadedImage.removeValue(forKey: imgURL)
            Logger.d("IMAGE_DOWNLOADER", "Cancel download: \(imgURL)", #fileID, #line)
        }
    }
    
//    static func loadLocalImg(urlStr: String) -> UIImage? {
//        let fetchRequest = LRemoteImage.fetchRequest()
//        fetchRequest.fetchLimit = 1
//        fetchRequest.predicate = NSPredicate(
//            format: "img_url LIKE %@", urlStr
//        )
//
//        do {
//            let imgRecords = try ImageDownloader.currentContext.fetch(fetchRequest)
//
//            guard let first = imgRecords.first, let data = first.img_data else {
//                Logger.d("IMAGE_DOWNLOADER", "Load cached image: \(urlStr)\n size: NULL", #fileID, #line)
//                return nil
//            }
//            Logger.d("IMAGE_DOWNLOADER", "Load cached image: \(urlStr)\n size: \(data.count)", #fileID, #line)
//            return UIImage(data: data)
//        } catch let error as NSError {
//            Logger.error("IMAGE_DOWNLOADER", "Load cached image: \(error.localizedDescription)", #fileID, #line)
//            return nil
//        }
//    }
    
    static func loadLocalImg(urlStr: String, completion: @escaping (UIImage?, String) -> Void) {
        
        ImageDownloader.currentContext.perform {
            do {
                let fetchRequest = LRemoteImage.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(
                    format: "img_url LIKE %@", urlStr
                )
                
                let imgRecords = try ImageDownloader.currentContext.fetch(fetchRequest)
                
                guard let first = imgRecords.first, let data = first.img_data else {
                    Logger.d("IMAGE_DOWNLOADER", "Load cached image: \(urlStr)\n size: NULL", #fileID, #line)
                    return completion(nil, urlStr)
                }
                Logger.d("IMAGE_DOWNLOADER", "Load cached image: \(urlStr)\n size: \(data.count)", #fileID, #line)
                return completion(UIImage(data: data), urlStr)
            } catch let error as NSError {
                Logger.error("IMAGE_DOWNLOADER", "Load cached image: \(error.localizedDescription)", #fileID, #line)
                return completion(nil, urlStr)
            }
        }
    }
    
    fileprivate static func saveImage(data: Data, urlStr: String) {
        current.persistQueue.async {
            let imgRecord = LRemoteImage(context: self.currentContext)
            imgRecord.id = UUID.init()
            imgRecord.img_url = urlStr
            imgRecord.img_data = data
            
            do {
                try ImageDownloader.currentContext.save()
                Logger.d("IMAGE_DOWNLOADER", "Persisted image: \(urlStr)\n size: \(data.count)", #fileID, #line)
            } catch let error as NSError {
                Logger.error("IMAGE_DOWNLOADER", "Persisted image: \(error.localizedDescription)", #fileID, #line)
            }
        }
    }
}

class DownloadedImageInfo: Operation {
    
    enum State {
        case new, loading, done, error
    }
    
    internal init(state: State = .new, url: String = "", image: UIImage? = nil) {
        self.state = state
        self.url = url
        self.image = image
    }
    
    internal init(state: State = .new, url: String = "", image: UIImage? = nil, indexPath: IndexPath = .init(row: 0, section: 0)) {
        self.state = state
        self.url = url
        self.image = image
        self.indexPath = indexPath
    }
    
    var state: State = .new
    var url = ""
    var image: UIImage?
    var indexPath: IndexPath = .init(row: 0, section: 0)
    
    override func main() {
        
        if isCancelled {
            self.state = .error
            self.triggerFinish()
            return
        }
        
        switch self.state {
        case .loading, .done:
            if self.state == .done {
                self.triggerFinish()
            }
            return
        default: break
        }
        self.state = .loading
        
//        if let img = ImageDownloader.loadLocalImg(urlStr: url) {
//            Logger.d("IMAGE_DOWNLOADER", "\nLoaded avatar from cache: \(url)", #fileID, #line)
//            self.image = img
//            self.onFinishLoadImg(self.image)
//            return self.state = .done
//        }
        
        guard let urlForLoad = URL(string: url) else { return self.state = .done }
        
        guard let imageData = try? Data.init(contentsOf: urlForLoad) else {
            self.state = .error
            self.triggerFinish()
            return
        }
        if isCancelled { return self.state = .error }
        
        self.state = .done
        self.image = UIImage(data: imageData)
  
        self.triggerFinish()

        Logger.d("IMAGE_DOWNLOADER", "Downloading finished: \(urlForLoad.absoluteString)", #fileID, #line)
        
        if let imgData = self.image?.pngData() {
            ImageDownloader.saveImage(data: imgData, urlStr: urlForLoad.absoluteString)
        }
    }
    
    var onFinishLoadImg: (UIImage?, String) -> Void = {_,_ in }
    var onFinishLoadImgIndex: (UIImage?, String, IndexPath) -> Void = {_,_,_ in }

    func triggerFinish() {
        onFinishLoadImg(self.image, self.url)
        onFinishLoadImgIndex(self.image, self.url, self.indexPath)
    }
    func clearListener() {
        onFinishLoadImg = {_,_ in }
        onFinishLoadImgIndex = {_,_,_ in }
    }
}

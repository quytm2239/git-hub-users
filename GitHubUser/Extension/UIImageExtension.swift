//
//  UIImageExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import UIKit

extension UIImage {
    func inverseImage(cgResult: Bool = true) -> UIImage? {
        let coreImage = UIKit.CIImage(image: self)
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        guard let result = filter.value(forKey: kCIOutputImageKey) as? UIKit.CIImage else { return nil }
        if cgResult {
            
            // prevent image tearing
            let ciContext = CIContext(options: [
                CIContextOption.workingColorSpace: NSNull()
            ])
            
            guard let cgImage = ciContext.createCGImage(result, from: result.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }
        return UIImage(ciImage: result)
    }
}

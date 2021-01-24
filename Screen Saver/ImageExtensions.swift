
import AppKit

extension NSImage {
    var averageColor: NSColor? {
        if !isValid { return nil }
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let cgImageRef = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        let inputImage = CIImage(cgImage: cgImageRef!)
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return NSColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }

    var randomPixelColor: NSColor? {
        let x = Int.random(in: 0...Int(self.size.width))
        let y = Int.random(in: 0...Int(self.size.height))
        return self[x, y]
    }

    var aspect: CGFloat {
        return size.width / size.height
    }

    func resize(withSize targetSize: NSSize) -> NSImage {
        var rect = CGRect(origin: CGPoint(x: 0, y: targetSize.height), size: targetSize)
        guard let cgImageRef = self.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return self }
        let imageWithNewSize = NSImage(cgImage: cgImageRef, size: targetSize)

        return imageWithNewSize
    }

    // TODO: OPTIMIZE THIS to not allocate memory every time
    subscript (x: Int, y: Int) -> NSColor? {
        guard x >= 0, x < Int(self.size.width), y >= 0, y < Int(self.size.height) else { return nil }
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let cgImage = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        let pixelData = cgImage?.dataProvider?.data
        let pixelInfo: Int = (Int(self.size.width) * y + x) * 4
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)

        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }

}

extension NSRect {

    var aspect: CGFloat {
        return size.width / size.height
    }

}

extension NSImageView {

    public func fadeIn(duration: TimeInterval = 1, timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut),
                       completion: (() -> Void)? = nil) {
        let animateOpacity = CABasicAnimation(keyPath: "opacity")
        animateOpacity.duration = duration
        animateOpacity.timingFunction = timingFunction
        animateOpacity.fromValue = alphaValue > 0.95 ? 0 : alphaValue
        animateOpacity.toValue = 1.0
        CATransaction.begin()
        layer?.add(animateOpacity, forKey: "opaque")
        CATransaction.setCompletionBlock {
            completion?()
        }
        alphaValue = 1.0
        CATransaction.commit()
    }

    var imageRect: NSRect {
        guard let image = self.image else { return .zero }
        let aspectDifference = frame.aspect / image.aspect
        switch (self.imageScaling) {
        case .scaleProportionallyUpOrDown:
            if aspectDifference > 1 {
                let scaledWidth = frame.height * image.aspect
                let xPos = (frame.width - scaledWidth) / 2
                return NSRect(x: xPos, y: 0, width: scaledWidth, height: frame.height)
            }
            let scaledHeight = frame.width / image.aspect
            let yPos = (frame.height - scaledHeight) / 2
            return NSRect(x: 0, y: yPos, width: frame.width, height: scaledHeight)
        default:
            return self.frame
        }
    }

}

extension Array where Element == String {
    
    func filterImagesOnly() -> [String] {
        let imageExtensions = ["png", "jpg", "jpeg", "heic", "tif", "tiff", "gif"]
        return self.filter({ path in
            let thePath = URL(fileURLWithPath: path)
            let fileExtension = thePath.pathExtension
            return imageExtensions.contains(fileExtension.lowercased())
        })
    }
    
}

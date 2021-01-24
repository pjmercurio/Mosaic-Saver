//
//  ImageProcessor.swift
//  Screen Saver
//
//  Created by Paul Mercurio on 12/11/20.
//  Copyright © 2020 Paul Mercurio. All rights reserved.
//

import Foundation
import AppKit
import ImageIO

struct ImageProcessor {
    var mainView: MainSaverView?
    let fileManager = FileManager.default
    let defaultsManager = DefaultsManager.sharedInstance

    init(_ mainView: MainSaverView) {
        self.mainView = mainView
        indexImages()
    }
    
    func reset() {
        
    }
    
    func indexImages() {
        guard let wallpaperURL = defaultsManager.photosLocation, fileManager.fileExists(atPath: wallpaperURL) else { return renderEmptyState() }
        do {
            let completeUrl = URL(fileURLWithPath: wallpaperURL, isDirectory: true)
            let items = try fileManager.contentsOfDirectory(atPath: completeUrl.path)
            let imageUrls = items.filterImagesOnly().compactMap({ URL(fileURLWithPath: wallpaperURL + $0) })
            getAverageValues(imageUrls)
        } catch let error {
            renderEmptyState(withError: error)
        }
    }
    
    func renderEmptyState(withError error: Error? = nil) {
        mainView?.indicator.isHidden = true
        let label = NSTextField(labelWithString: "No pictures found. Set location in preferences.")
        label.font = NSFont(name: "Helvetica Neue Thin", size: 24.0)
        label.usesSingleLineMode = false
        label.textColor = .white
        label.alignment = .center
        label.stringValue = error?.localizedDescription ?? "No pictures found. Set location in preferences."
        mainView?.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1, constant: 0),
             NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: mainView, attribute: .centerY, multiplier: 1, constant: 0)])
    }

    func getAverageValues(_ imageURLS: [URL]) {
        guard imageURLS.count > 0 else { return renderEmptyState() }
        DispatchQueue.global(qos: .background).async {
            var colorToThumbnailMap = [NSColor: URL]()
            for (index, imageURL) in imageURLS.enumerated() {
                guard let thumbnailURL = self.resizeToThumbnail(imageURL) else { continue }
                let image = NSImage(contentsOf: thumbnailURL)
                let progress = Float(index) / Float(imageURLS.count) * 100.0
                self.mainView?.updateIndexingProgress(progress)
                guard let color = image?.averageColor else { continue }
                colorToThumbnailMap[color] = thumbnailURL
            }
            DispatchQueue.main.async {
                self.mainView?.renderColorGrid(colorToThumbnailMap, imageURLS)
            }
        }
    }

    func resizeToThumbnail(_ imageUrl: URL) -> URL? {
        do {
            let cachesURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let thumbnailURL = cachesURL.appendingPathComponent("MosaicSaver").appendingPathComponent("imageDB")
            if !fileManager.fileExists(atPath: thumbnailURL.path) {
                try fileManager.createDirectory(atPath: thumbnailURL.path, withIntermediateDirectories: true, attributes: nil)
            }
            return writeResizedImage(at: imageUrl, to: thumbnailURL)
        } catch { return nil }
    }

    func writeResizedImage(at url: URL, to destinationURL: URL) -> URL? {
        let imageDestinationURL = destinationURL.appendingPathComponent(url.lastPathComponent)
        guard !fileManager.fileExists(atPath: imageDestinationURL.path) else { return imageDestinationURL }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 250
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        else { return nil }

        let resizedImage =  NSImage(cgImage: image, size: NSSize(width: 250, height: 250))
        guard let tiffData = resizedImage.tiffRepresentation,
              let data = NSBitmapImageRep(data: tiffData),
              let imgData = data.representation(using: .jpeg, properties: [.compressionFactor : NSNumber(floatLiteral: 0.5)]) else { return nil }
        do {
            try imgData.write(to: imageDestinationURL)
            return imageDestinationURL
        } catch { return nil }
    }

//    func resizeMainImage(at url: URL, to destinationURL: URL, _ size: NSSize) -> URL? {
//        let imageDestinationURL = destinationURL.appendingPathComponent(url.lastPathComponent)
//        guard !fileManager.fileExists(atPath: imageDestinationURL.path) else { return imageDestinationURL }
//        let options: [CFString: Any] = [
//            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
//            kCGImageSourceCreateThumbnailWithTransform: true,
//            kCGImageSourceShouldCacheImmediately: true,
//            kCGImageSourceThumbnailMaxPixelSize: size.width
//        ]
//
//        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
//              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, nil)
//        else { return nil }
//
//        let resizedImage =  NSImage(cgImage: image, size: size)
//        guard let tiffData = resizedImage.tiffRepresentation,
//              let data = NSBitmapImageRep(data: tiffData),
//              let imgData = data.representation(using: .jpeg, properties: [.compressionFactor : NSNumber(floatLiteral: 0.5)]) else { return nil }
//        do {
//            try imgData.write(to: imageDestinationURL)
//            return imageDestinationURL
//        } catch { return nil }
//    }

}

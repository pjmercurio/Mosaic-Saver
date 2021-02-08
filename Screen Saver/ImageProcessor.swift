//
//  ImageProcessor.swift
//  Mosaic Saver
//
//  Created by Paul Mercurio on 12/11/20.
//  Copyright © 2020 Paul Mercurio. All rights reserved.
//

import Foundation
import AppKit
import ImageIO

protocol ImageProcessorDelegate: AnyObject {
    func renderMainGrid(_ colorToThumbnailMap: [NSColor: URL], _ mainImageURLs: [URL]?)
    func renderEmptyState(withError error: Error?)
    func updateIndexingProgress(_ progress: Float)
}

struct ImageProcessor {
    weak var delegate: ImageProcessorDelegate?
    let fileManager = FileManager.default
    let defaultsManager = DefaultsManager.sharedInstance

    init(_ delegate: ImageProcessorDelegate) {
        self.delegate = delegate
        indexImages()
    }
    
    func indexImages() {
        guard let wallpaperURL = defaultsManager.photosLocation, fileManager.fileExists(atPath: wallpaperURL) else {
            delegate?.renderEmptyState(withError: nil)
            return
        }
        do {
            let completeUrl = URL(fileURLWithPath: wallpaperURL, isDirectory: true)
            let items = try fileManager.contentsOfDirectory(atPath: completeUrl.path)
            let imageUrls = items.filterImagesOnly().compactMap({ URL(fileURLWithPath: wallpaperURL + $0) })
            getAverageValues(imageUrls)
        } catch let error {
            delegate?.renderEmptyState(withError: error)
        }
    }

    // Cache the average color value for every source image
    func getAverageValues(_ imageURLS: [URL]) {
        guard imageURLS.count > 0 else {
            delegate?.renderEmptyState(withError: nil)
            return
        }
        DispatchQueue.global(qos: .background).async {
            var colorToThumbnailMap = [NSColor: URL]()
            for (index, imageURL) in imageURLS.enumerated() {
                guard let thumbnailURL = self.resizeToThumbnail(imageURL) else { continue }
                let image = NSImage(contentsOf: thumbnailURL)
                let progress = Float(index) / Float(imageURLS.count) * 100.0
                self.delegate?.updateIndexingProgress(progress)
                guard let color = image?.averageColor else { continue }
                colorToThumbnailMap[color] = thumbnailURL
            }
            DispatchQueue.main.async {
                self.delegate?.renderMainGrid(colorToThumbnailMap, imageURLS)
            }
        }
    }

    // Cache every image as tiny thumbnails for later use as pixels
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

    // Write a resized thumbnail image to disk if it doesn't already exist
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

}

////
////  MainSaverView.swift
////  Mosaic Saver
////
////  Created by Paul Mercurio on 12/11/20.
////  Copyright © 2020 Paul Mercurio. All rights reserved.
////

import ScreenSaver

class MainSaverView: ScreenSaverView {

    // Preferences
    override var hasConfigureSheet: Bool { return true }
    override var configureSheet: NSWindow? {
        return ConfigureSheetController.sharedInstance.window
    }

    // Global Objects
    let defaultsManager = DefaultsManager.sharedInstance
    var imageProcessor: ImageProcessor? = nil
    let indicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 100, height: 20))
    var colorToThumbnailMap = [NSColor: URL]()
    var mainImageURLs = [URL]()
    var mainImageView = NSImageView()
    var imageCache = [URL: NSImage]()

    // MARK: - Initialization
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        imageProcessor = ImageProcessor(self)
        addProgressIndicator()
        ConfigureSheetController.sharedInstance.refreshPreview = refreshPreview
    }

    func addProgressIndicator() {
        addSubview(indicator)
        indicator.isIndeterminate = false
        indicator.controlTint = .defaultControlTint
        indicator.minValue = 0
        indicator.maxValue = 100
        indicator.doubleValue = 0
        indicator.isBezeled = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([NSLayoutConstraint(item: indicator, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
                                     NSLayoutConstraint(item: indicator, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
                                     NSLayoutConstraint(item: indicator, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.5, constant: 0)]
        )
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    override func draw(_ rect: NSRect) {
        let backgroundColor = defaultsManager.backgroundColor
        drawBackground(backgroundColor)
    }

    private func drawBackground(_ color: NSColor) {
        let background = NSBezierPath(rect: bounds)
        color.setFill()
        background.fill()
    }
    
    // Refresh preview window after prefs have been updated
    func refreshPreview() {
        colorToThumbnailMap.removeAll()
        mainImageURLs.removeAll()
        imageCache.removeAll()
        setNeedsDisplay(self.bounds)
        subviews.removeAll()
        addProgressIndicator()
        imageProcessor?.indexImages()
    }

    // Draw all of the mini blocks for the original image
    func drawImagePixels() {
        guard let mainImage = mainImageView.image else { return }
        let pixelData = mainImage.pixelData
        let colorValues: [NSColor] = Array(colorToThumbnailMap.keys)
        let mainImageRect = mainImageView.imageRect
        let buildStyle = defaultsManager.buildStyle
        let blockWidth = mainImageRect.width < 500 ? defaultsManager.blockSize / 2 : defaultsManager.blockSize
        let blockHeight = blockWidth * 2 / 3
        let numHorizontalBlocks = Int(mainImageRect.width / CGFloat(blockWidth))
        let numVerticalBlocks = Int(mainImageRect.height / CGFloat(blockHeight))
        let horizontalRatio = mainImage.size.width / mainImageRect.width
        let verticalRatio = mainImage.size.height / mainImageRect.height

        var blocks: [NSView] = []
        func innerLoop(_ x: Int, _ y: Int) {
            let midpointX = (CGFloat(x * blockWidth) * horizontalRatio) + CGFloat(blockWidth / 2)
            let midpointY = (CGFloat(y * blockHeight) * verticalRatio) + CGFloat(blockHeight / 2)
//            guard let blockColor = mainImage[Int(midpointX), Int(midpointY)] else { return }
            guard let blockColor = mainImage.colorForPixel(x: Int(midpointX), y: Int(midpointY), pixelData: pixelData) else { return }
            let nearestColor = colorValues.reduce(colorValues.first!, { curr, next in
                if next.difference(from: blockColor) >= curr.difference(from: blockColor) { return curr }
                return next
            })
            guard let newImageURL = self.colorToThumbnailMap[nearestColor] else { return }

            let newImage = self.imageCache[newImageURL] ?? NSImage(byReferencing: newImageURL)
            let xPos = x * blockWidth + Int(mainImageRect.origin.x)
            let yPos = Int(self.frame.height) - (y * blockHeight) - Int(mainImageRect.origin.y) - blockHeight
            let imageView = NSView(frame: NSRect(x: xPos, y: yPos, width: blockWidth, height: blockHeight))
            imageView.wantsLayer = true
            imageView.alphaValue = 0
            imageView.layer?.contents = newImage
            imageView.layer?.contentsGravity = .resizeAspectFill
            imageCache[newImageURL] = newImage
            addSubview(imageView)
            blocks.append(imageView)
        }

        let xArray = Array(0...numHorizontalBlocks)
        let yArray = Array(0...numVerticalBlocks)
        switch buildStyle {
        case "Scan Vertical":
            for x in xArray {
                for y in yArray { innerLoop(x, y) }
            }
        case "Scan Horizontal":
            for y in yArray {
                for x in xArray { innerLoop(x, y) }
            }
        default:
            var shuffledPoints: [(Int, Int)] = []
            for x in xArray {
                for y in yArray {
                    shuffledPoints.append((x, y))
                }
            }
            shuffledPoints = shuffledPoints.shuffled()
            for point in shuffledPoints { innerLoop(point.0, point.1) }
        }
        addBlockAtIndex(0, from: blocks)
    }

    func addBlockAtIndex(_ index: Int, from blocks: [NSView]) {
        guard index < blocks.count else {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.showMainImage()
            }
            return
        }
        let buildSpeed: TimeInterval = 0.01 - defaultsManager.buildSpeed
        let block = blocks[index]
        block.zoomIn(duration: 1.5)
        block.fadeIn()
        Timer.scheduledTimer(withTimeInterval: buildSpeed, repeats: false) { [weak self] _ in
            self?.addBlockAtIndex(index + 1, from: blocks)
        }
    }

    // Prepare main image view for later display
    func setupMainImageView() {
        guard let mainImageURL = mainImageURLs.randomElement() else { return }
        let mainImage = NSImage(byReferencing: mainImageURL).resizedImageTo(newSize: bounds.size)
        mainImageView.frame = frame
        mainImageView.wantsLayer = true
        mainImageView.image = mainImage
        mainImageView.imageScaling = .scaleProportionallyUpOrDown
        mainImageView.layer?.backgroundColor = defaultsManager.backgroundColor.cgColor
    }

    // Display original image after all blocks are displayed
    func showMainImage() {
        mainImageView.alphaValue = 0
        addSubview(mainImageView)

        guard let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 20]) else { return }
        blurFilter.name = "blur"
        mainImageView.layer?.filters = [blurFilter]

        let animationDuration = 3.0
        let outAnimation = CABasicAnimation()
        outAnimation.keyPath = "filters.blur.inputRadius"
        outAnimation.fromValue = 20
        outAnimation.toValue = 0
        outAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        outAnimation.duration = animationDuration
        outAnimation.fillMode = .forwards
        outAnimation.isRemovedOnCompletion = false

        mainImageView.fadeIn(duration: animationDuration) {
            self.mainImageView.layer?.add(outAnimation, forKey: nil)
            Timer.scheduledTimer(withTimeInterval: animationDuration + 5, repeats: false) { _ in
                self.subviews.removeAll()
                self.renderMainGrid(self.colorToThumbnailMap)
            }
        }
    }

}

extension MainSaverView: ImageProcessorDelegate {
    // Show state when current source folder has no images
    func renderEmptyState(withError error: Error? = nil) {
        indicator.isHidden = true
        let label = NSTextField(labelWithString: "No pictures found. Set location in preferences.")
        label.font = NSFont(name: "Helvetica Neue Thin", size: 24.0)
        label.textColor = .white
        label.alignment = .center
        label.stringValue = error?.localizedDescription ?? "No pictures found. Set location in preferences."
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
             NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)])
    }

    // Show the main state when images are indexed and ready
    func renderMainGrid(_ colorToThumbnailMap: [NSColor: URL], _ mainImageURLs: [URL]? = nil) {
        self.colorToThumbnailMap = colorToThumbnailMap
        self.mainImageURLs = mainImageURLs ?? self.mainImageURLs
        indicator.isHidden = true

        setupMainImageView()
        drawImagePixels()
    }
    
    func updateIndexingProgress(_ progress: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.indicator.isHidden = false
            self?.indicator.doubleValue = Double(progress)
        }
    }
}

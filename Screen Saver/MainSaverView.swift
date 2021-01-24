////
////  Main.swift
////  Screen Saver
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
    
    func refreshPreview() {
        setNeedsDisplay(bounds)
        subviews.removeAll()
        addProgressIndicator()
        imageProcessor?.indexImages()
    }

    func renderColorGrid(_ colorToThumbnailMap: [NSColor: URL], _ mainImageURLs: [URL]? = nil) {
        self.colorToThumbnailMap = colorToThumbnailMap
        self.mainImageURLs = mainImageURLs ?? self.mainImageURLs
        indicator.isHidden = true

        guard let mainImageView = setupMainImageView() else { return }
        drawImagePixels(in: mainImageView)
    }

    func setupMainImageView() -> NSImageView? {
        guard let mainImageURL = mainImageURLs.randomElement() else { return nil }
//        let mainImageURL = URL(fileURLWithPath: "/Users/paulmercurio/Pictures/Mosaic/bernie.jpg")
//        let imageName = mainImageURL.lastPathComponent
//        let cacheImageURL = URL(fileURLWithPath: "/Users/paulmercurio/Library/Caches/MosaicSaver/imageDB/\(imageName)")
//        print("Image Name: \(mainImageURL.lastPathComponent)")
//        print("CACHE IIMAGE URL: \(cacheImageURL)")
        let mainImage = NSImage(byReferencing: mainImageURL)
        let mainImageView = NSImageView(frame: frame)
        mainImageView.wantsLayer = true
        mainImageView.image = mainImage
        mainImageView.imageScaling = .scaleProportionallyUpOrDown
        mainImageView.layer?.backgroundColor = defaultsManager.backgroundColor.cgColor
        return mainImageView
    }

    func drawImagePixels(in mainImageView: NSImageView) {
        guard let mainImage = mainImageView.image else { return }
        let colorValues: [NSColor] = Array(colorToThumbnailMap.keys)
        let mainImageRect = mainImageView.imageRect
        let buildStyle = defaultsManager.buildStyle
        let blockWidth = mainImageRect.width < 500 ? defaultsManager.blockSize / 2 : defaultsManager.blockSize
        let blockHeight = blockWidth * 2 / 3
        let numHorizontalBlocks = Int(mainImageRect.width / CGFloat(blockWidth))
        let numVerticalBlocks = Int(mainImageRect.height / CGFloat(blockHeight))
        let horizontalRatio = mainImage.size.width / mainImageRect.width
        let verticalRatio = mainImage.size.height / mainImageRect.height
        
        func innerLoop(_ x: Int, _ y: Int) {
            let midpointX = (CGFloat(x * blockWidth) * horizontalRatio) + CGFloat(blockWidth / 2)
            let midpointY = (CGFloat(y * blockHeight) * verticalRatio) + CGFloat(blockHeight / 2)
            guard let blockColor = mainImage[Int(midpointX), Int(midpointY)] else { return }
            let nearestColor = colorValues.reduce(colorValues.first!, { curr, next in
                if next.difference(from: blockColor) >= curr.difference(from: blockColor) { return curr }
                return next
            })
            guard let newImageURL = self.colorToThumbnailMap[nearestColor] else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let newImage = self.imageCache[newImageURL] ?? NSImage(byReferencing: newImageURL)
                let xPos = x * blockWidth + Int(mainImageRect.origin.x)
                let yPos = Int(self.frame.height) - (y * blockHeight) - Int(mainImageRect.origin.y) - blockHeight
                let imageView = NSView(frame: NSRect(x: xPos, y: yPos, width: blockWidth, height: blockHeight))
                imageView.wantsLayer = true
                imageView.layer?.contents = newImage
                imageView.layer?.contentsGravity = .resizeAspectFill
                self.imageCache[newImageURL] = newImage
                self.addSubview(imageView)
            }
        }

        DispatchQueue.global(qos: .background).async {
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
                var wholeArray: [(Int, Int)] = []
                for x in xArray {
                    for y in yArray {
                        wholeArray.append((x, y))
                    }
                }
                wholeArray = wholeArray.shuffled()
                for point in wholeArray { innerLoop(point.0, point.1) }
            }
            DispatchQueue.main.async { [weak self] in
                self?.showMainImage(mainImageView)
            }
        }
    }

    func showMainImage(_ mainImageView: NSImageView) {
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
            mainImageView.layer?.add(outAnimation, forKey: nil)
            let holdDuration = self.defaultsManager.holdDuration
            Timer.scheduledTimer(withTimeInterval: animationDuration + holdDuration, repeats: false) { _ in
                self.subviews.removeAll()
                self.renderColorGrid(self.colorToThumbnailMap)
            }
        }
    }

    func updateIndexingProgress(_ progress: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.indicator.isHidden = false
            self?.indicator.doubleValue = Double(progress)
        }
    }

}


//
//  ConfigureSheetController.swift
//  Mosaic Saver
//
//  Created by Paul Mercurio on 1/21/21.
//  Copyright © 2021 Paul Mercurio. All rights reserved.
//

import Cocoa

class ConfigureSheetController: NSObject {
    static var sharedInstance = ConfigureSheetController()
    var defaultsManager = DefaultsManager.sharedInstance
    public var refreshPreview: (() -> Void)?
    
    @IBOutlet var window: NSWindow!
    @IBOutlet weak var colorPicker: NSColorWell!
    @IBOutlet weak var blockSizeSlider: NSSlider!
    @IBOutlet weak var buildSpeedSlider: NSSlider!
    @IBOutlet weak var buildStyleButton: NSPopUpButton!
    @IBOutlet weak var photoLocationLabel: NSButton!
    
    @IBAction func chooseFolder(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        
        if (dialog.runModal() == .OK) {
            guard let path = dialog.url?.path else { return }
            photoLocationLabel.attributedTitle = NSMutableAttributedString(string: path, attributes: [NSAttributedString.Key.foregroundColor: NSColor.red])
        }
    }

    @IBAction func revealInFinder(_ sender: NSButton) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: sender.title)
    }

    @IBAction func save(_ sender: NSButton) {
        let color = colorPicker.color
        let blockSize = blockSizeSlider.integerValue
        let buildSpeed = buildSpeedSlider.doubleValue
        let buildStyle = buildStyleButton.selectedItem?.title ?? "Scan Vertical"
        let photoLocation = photoLocationLabel.title
        defaultsManager.backgroundColor = color
        defaultsManager.blockSize = blockSize
        defaultsManager.buildSpeed = buildSpeed
        defaultsManager.buildStyle = buildStyle
        defaultsManager.photosLocation = photoLocation
        refreshPreview?()
        window.sheetParent?.endSheet(window)
    }

    @IBAction func cancel(_ sender: AnyObject) {
        NSColorPanel.shared.close()
        window.sheetParent?.endSheet(window)
        getDefaults()
    }

    override init() {
        super.init()

        let myBundle = Bundle(for: ConfigureSheetController.self)
        myBundle.loadNibNamed("ConfigureSheet", owner: self, topLevelObjects: nil)
        setupBuildButton()
        getDefaults()
    }
    
    func setupBuildButton() {
        buildStyleButton.removeAllItems()
        buildStyleButton.addItem(withTitle: "Scan Vertical")
        buildStyleButton.addItem(withTitle: "Scan Horizontal")
        buildStyleButton.addItem(withTitle: "Random")
    }
    
    func getDefaults() {
        let backgroundColor = defaultsManager.backgroundColor
        let blockSize = defaultsManager.blockSize
        let buildSpeed = defaultsManager.buildSpeed
        let buildStyle = defaultsManager.buildStyle
        let photosLocation = defaultsManager.photosLocation
        colorPicker.color = backgroundColor
        blockSizeSlider.integerValue = blockSize
        buildSpeedSlider.doubleValue = buildSpeed
        buildStyleButton.selectItem(withTitle: buildStyle)
        photoLocationLabel.attributedTitle = NSMutableAttributedString(string: photosLocation ?? "Not set", attributes: [NSAttributedString.Key.foregroundColor: NSColor.red])
    }
    
}

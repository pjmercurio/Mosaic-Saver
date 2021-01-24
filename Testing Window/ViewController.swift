//
//  ViewController.swift
//  Testing Window
//
//  Created by Paul Mercurio on 12/11/20.
//  Copyright © 2020 Paul Mercurio. All rights reserved.
//

import Cocoa
import ScreenSaver

class ViewController: NSViewController {

    @IBOutlet var saver: MainSaverView?

    override func viewDidLoad() {
        super.viewDidLoad()

        addScreensaver()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func addScreensaver() {
        if let saver = MainSaverView(frame: view.frame, isPreview: false) {
            view.addSubview(saver)
            saver.autoresizingMask = [.width, .height]
            self.saver = saver
        }
    }

}


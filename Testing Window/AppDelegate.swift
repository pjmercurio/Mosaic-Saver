//
//  AppDelegate.swift
//  Testing Window
//
//  Created by Paul Mercurio on 12/11/20.
//  Copyright © 2020 Paul Mercurio. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
//    @IBOutlet var window: NSWindow!
    let configureSheet = ConfigureSheetController.sharedInstance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func openConfigureSheet(sender: NSMenuItem) {
        print("open configure sheet...")
        let window = configureSheet.window
        window?.beginSheet(configureSheet.window, completionHandler: nil)
    }

}

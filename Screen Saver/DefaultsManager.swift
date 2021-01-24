//
//  DefaultsManager.swift
//  Screen Saver
//
//  Created by Paul Mercurio on 1/21/21.
//  Copyright © 2021 Paul Mercurio. All rights reserved.
//

import ScreenSaver

struct DefaultsManager {
    
    enum PrefKey: String {
        case backgroundColor
        case blockSize
        case holdDuration
        case buildStyle
        case photosLocation
    }
    
    static var sharedInstance = DefaultsManager()
    var defaults: UserDefaults?

    init() {
        defaults = UserDefaults.standard
    }

    var backgroundColor: NSColor {
        set(newColor) {
            do {
                let colorData = try NSKeyedArchiver.archivedData(withRootObject: newColor, requiringSecureCoding: false)
                defaults?.set(colorData, forKey: PrefKey.backgroundColor.rawValue)
            } catch {}
        }
        get {
            if let colorData = defaults?.data(forKey: PrefKey.backgroundColor.rawValue) {
                do {
                    let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
                    return color ?? .black
                } catch { return .black }
            }
            return .black
        }
    }

    var blockSize: Int {
        set(newColor) {
            setValue(newColor, key: .blockSize)
        }
        get {
            return getValue(forKey: .blockSize) as? Int ?? 20
        }
    }

    var holdDuration: Double {
        set(newDuration) {
            setValue(newDuration, key: .holdDuration)
        }
        get {
            return getValue(forKey: .holdDuration) as? Double ?? 5
        }
    }
    
    var buildStyle: String {
        set(newStyle) {
            setValue(newStyle, key: .buildStyle)
        }
        get {
            return getValue(forKey: .buildStyle) as? String ?? "Scan Vertical"
        }
    }

    var photosLocation: String? {
        set(newLocation) {
            setValue(newLocation!, key: .photosLocation)
        }
        get {
            if let location = getValue(forKey: .photosLocation) as? String {
                if location.last != "/" { return location + "/" }
                return location
            }
            return nil
        }
    }

    func setValue(_ value: Any, key: PrefKey) {
        defaults?.setValue(value, forKey: key.rawValue)
    }

    func getValue(forKey key: PrefKey) -> Any? {
        return defaults?.value(forKey: key.rawValue)
    }

}

//
//  SettingsManager.swift
//  ByeByeDPI
//
//  Manages application settings using UserDefaults
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedProfile: String {
        didSet { save() }
    }
    
    @Published var enableFakePackets: Bool {
        didSet { save() }
    }
    
    @Published var enableDisorder: Bool {
        didSet { save() }
    }
    
    @Published var autoMode: Bool {
        didSet { save() }
    }
    
    @Published var ttl: Int {
        didSet { save() }
    }
    
    @Published var maxOpenFiles: Int {
        didSet { save() }
    }
    
    @Published var customArgs: String {
        didSet { save() }
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let selectedProfile = "selectedProfile"
        static let enableFakePackets = "enableFakePackets"
        static let enableDisorder = "enableDisorder"
        static let autoMode = "autoMode"
        static let ttl = "ttl"
        static let maxOpenFiles = "maxOpenFiles"
        static let customArgs = "customArgs"
    }
    
    // MARK: - Initialization
    
    init() {
        let defaults = UserDefaults.standard
        
        self.selectedProfile = defaults.string(forKey: Keys.selectedProfile) ?? "Default"
        self.enableFakePackets = defaults.object(forKey: Keys.enableFakePackets) as? Bool ?? true
        self.enableDisorder = defaults.object(forKey: Keys.enableDisorder) as? Bool ?? true
        self.autoMode = defaults.object(forKey: Keys.autoMode) as? Bool ?? true
        self.ttl = defaults.integer(forKey: Keys.ttl) != 0 ? defaults.integer(forKey: Keys.ttl) : 8
        self.maxOpenFiles = defaults.integer(forKey: Keys.maxOpenFiles) != 0 ? defaults.integer(forKey: Keys.maxOpenFiles) : 1024
        self.customArgs = defaults.string(forKey: Keys.customArgs) ?? ""
    }
    
    // MARK: - Public Methods
    
    func resetToDefaults() {
        selectedProfile = "Default"
        enableFakePackets = true
        enableDisorder = true
        autoMode = true
        ttl = 8
        maxOpenFiles = 1024
        customArgs = ""
    }
    
    func buildArguments() -> [String] {
        var args: [String] = []
        
        switch selectedProfile {
        case "Default":
            args.append("--disorder")
            args.append("--auto")
        case "Aggressive":
            args.append("--disorder")
            args.append("--fake")
            args.append("--auto")
        case "Conservative":
            args.append("--disorder")
        case "Custom":
            // Parse custom arguments
            if !customArgs.isEmpty {
                args.append(contentsOf: customArgs.split(separator: " ").map(String.init))
            }
        default:
            break
        }
        
        // Override with individual settings if not in custom mode
        if selectedProfile != "Custom" {
            if enableFakePackets && !args.contains("--fake") {
                args.append("--fake")
            }
            if enableDisorder && !args.contains("--disorder") {
                args.append("--disorder")
            }
            if autoMode && !args.contains("--auto") {
                args.append("--auto")
            }
        }
        
        args.append("--ttl")
        args.append("\(ttl)")
        
        args.append("--max-open-files")
        args.append("\(maxOpenFiles)")
        
        return args
    }
    
    // MARK: - Private Methods
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(selectedProfile, forKey: Keys.selectedProfile)
        defaults.set(enableFakePackets, forKey: Keys.enableFakePackets)
        defaults.set(enableDisorder, forKey: Keys.enableDisorder)
        defaults.set(autoMode, forKey: Keys.autoMode)
        defaults.set(ttl, forKey: Keys.ttl)
        defaults.set(maxOpenFiles, forKey: Keys.maxOpenFiles)
        defaults.set(customArgs, forKey: Keys.customArgs)
    }
}

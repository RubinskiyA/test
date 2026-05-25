//
//  ByeByeDPIApp.swift
//  ByeByeDPI
//
//  Main entry point for the iOS application
//

import SwiftUI

@main
struct ByeByeDPIApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vpnManager)
                .environmentObject(settingsManager)
        }
    }
}

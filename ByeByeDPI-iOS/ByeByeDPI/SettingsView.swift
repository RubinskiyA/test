//
//  SettingsView.swift
//  ByeByeDPI
//
//  Settings configuration view
//

import SwiftUI

struct DPIProfile: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let args: [String]
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    let profiles: [DPIProfile] = [
        DPIProfile(
            name: "Default",
            description: "Standard bypass strategy",
            args: ["--disorder", "--auto"]
        ),
        DPIProfile(
            name: "Aggressive",
            description: "More aggressive bypass methods",
            args: ["--disorder", "--fake", "--auto"]
        ),
        DPIProfile(
            name: "Conservative",
            description: "Minimal changes to packets",
            args: ["--disorder"]
        ),
        DPIProfile(
            name: "Custom",
            description: "User-defined parameters",
            args: []
        )
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("DPI Bypass Profile")) {
                    Picker("Profile", selection: $settingsManager.selectedProfile) {
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile.name)
                        }
                    }
                    
                    if let profile = profiles.first(where: { $0.name == settingsManager.selectedProfile }) {
                        Text(profile.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Advanced Settings")) {
                    Toggle("Enable Fake Packets", isOn: $settingsManager.enableFakePackets)
                    Toggle("Enable Disorder", isOn: $settingsManager.enableDisorder)
                    Toggle("Auto Mode", isOn: $settingsManager.autoMode)
                    
                    HStack {
                        Text("TTL")
                        Spacer()
                        Stepper(value: $settingsManager.ttl, in: 1...255) {
                            Text("\(settingsManager.ttl)")
                                .monospacedDigit()
                        }
                    }
                    
                    HStack {
                        Text("Max Open Files")
                        Spacer()
                        Stepper(value: $settingsManager.maxOpenFiles, in: 100...10000, step: 100) {
                            Text("\(settingsManager.maxOpenFiles)")
                                .monospacedDigit()
                        }
                    }
                }
                
                Section(header: Text("Custom Arguments")) {
                    TextField("--arg1 --arg2", text: $settingsManager.customArgs)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Enter additional byedpi arguments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset to Defaults") {
                        settingsManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}

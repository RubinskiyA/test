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
    @StateObject private var strategyTester = StrategyTester()
    @State private var showTestResults = false
    
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
                Section(header: Text("Auto-Detection")) {
                    Button(action: startStrategyTesting) {
                        HStack {
                            Image(systemName: strategyTester.isTesting ? "arrow.triangle.2.circlepath" : "wand.and.stars")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text("Auto-detect Best Strategy")
                                    .font(.body)
                                Text(strategyTester.isTesting ? "Testing... \(strategyTester.currentTestIndex)/\(strategyTester.totalTests)" : "Test all strategies and find optimal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(strategyTester.isTesting)
                    
                    if strategyTester.isTesting {
                        ProgressView(value: strategyTester.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    
                    if let best = strategyTester.bestStrategy {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Best Strategy Found")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(best.displayText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Apply This Strategy") {
                            strategyTester.saveBestStrategy(to: settingsManager)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !strategyTester.results.isEmpty && !strategyTester.isTesting {
                        NavigationLink(destination: testResultsView) {
                            Label("View All Results", systemImage: "list.bullet")
                        }
                    }
                }
                
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
    
    // MARK: - Helper Views
    
    private var testResultsView: some View {
        List(strategyTester.results) { result in
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                VStack(alignment: .leading) {
                    Text(result.strategyName)
                        .font(.subheadline)
                    if let latency = result.latencyMs {
                        Text("\(Int(latency)) ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let error = result.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                Spacer()
                if strategyTester.bestStrategy?.id == result.id {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .navigationTitle("Test Results")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Methods
    
    private func startStrategyTesting() {
        Task {
            await strategyTester.startTesting()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}

//
//  ContentView.swift
//  ByeByeDPI
//
//  Main UI view for the application
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status Indicator
                VStack(spacing: 15) {
                    Circle()
                        .fill(vpnManager.isConnected ? Color.green : Color.gray)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: vpnManager.isConnected ? "shield.fill" : "shield.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                    
                    Text(vpnManager.isConnected ? "Connected" : "Disconnected")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(vpnManager.isConnected ? .green : .gray)
                    
                    if vpnManager.isConnected {
                        Text("Traffic is being protected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                
                // Connect Button
                Button(action: {
                    Task {
                        await vpnManager.toggleConnection()
                    }
                }) {
                    Text(vpnManager.isConnected ? "Disconnect" : "Connect")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vpnManager.isConnected ? Color.red : Color.blue)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .disabled(vpnManager.isConnecting)
                
                if vpnManager.isConnecting {
                    ProgressView("Connecting...")
                        .padding()
                }
                
                // Settings Button
                Button(action: { showingSettings = true }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Info
                VStack(spacing: 5) {
                    Text("byedpi iOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Version 1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("ByeByeDPI")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settingsManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VPNManager())
        .environmentObject(SettingsManager())
}

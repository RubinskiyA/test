//
//  VPNManager.swift
//  ByeByeDPI
//
//  Manages VPN connection state and communicates with Packet Tunnel Extension
//

import Foundation
import NetworkExtension
import Combine

enum VPNStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case invalid
    
    static func from(neStatus: NEVPNStatus) -> VPNStatus {
        switch neStatus {
        case .connected: return .connected
        case .connecting: return .connecting
        case .disconnected: return .disconnected
        case .disconnecting: return .disconnecting
        case .invalid: return .invalid
        @unknown default: return .invalid
        }
    }
}

class VPNManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var status: VPNStatus = .disconnected
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let manager = NETunnelProviderManager()
    private var statusObserver: NSKeyValueObservation?
    private var settingsManager: SettingsManager?
    
    // MARK: - Shared Instance
    
    static let shared = VPNManager()
    
    // MARK: - Initialization
    
    init() {
        setupObserver()
    }
    
    func setSettingsManager(_ settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Public Methods
    
    /// Load VPN configuration from saved settings
    func loadConfiguration() async throws {
        do {
            try await manager.loadFromPreferences(identifier: "com.byebyedpi.PacketTunnel")
            updateStatus(from: manager.connection.status)
        } catch {
            print("Failed to load VPN configuration: \(error)")
            throw error
        }
    }
    
    /// Save VPN configuration for future use
    func saveConfiguration() async throws {
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = "com.byebyedpi.PacketTunnel"
        tunnelProtocol.serverAddress = "localhost"
        
        manager.protocolConfiguration = tunnelProtocol
        manager.localizedDescription = "ByeByeDPI"
        manager.isEnabled = true
        
        do {
            try await manager.saveToPreferences()
            print("VPN configuration saved successfully")
        } catch {
            print("Failed to save VPN configuration: \(error)")
            throw error
        }
    }
    
    /// Start VPN connection
    func connect() async {
        guard !isConnected && !isConnecting else { return }
        
        do {
            isConnecting = true
            errorMessage = nil
            
            // Try to load existing configuration
            do {
                try await loadConfiguration()
            } catch {
                // If no configuration exists, create a new one
                try await saveConfiguration()
            }
            
            // Build arguments from settings
            var args: [String] = ["byedpi"]
            if let settingsManager = settingsManager {
                args.append(contentsOf: settingsManager.buildArguments())
            }
            
            // Start the tunnel
            let options = ["arguments": args] as [String : NSObject]
            try manager.connection.startVPNTunnel(options: options)
            
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
            isConnecting = false
            print("Connection error: \(error)")
        }
    }
    
    /// Stop VPN connection
    func disconnect() {
        guard isConnected || isConnecting else { return }
        
        manager.connection.stopVPNTunnel()
    }
    
    /// Toggle connection state
    func toggleConnection() async {
        if isConnected {
            disconnect()
        } else {
            await connect()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObserver() {
        statusObserver = observe(\.manager.connection.status, options: [.new]) { [weak self] _, change in
            guard let self = self,
                  let newStatus = change.newValue else { return }
            
            DispatchQueue.main.async {
                self.updateStatus(from: newStatus)
            }
        }
    }
    
    private func updateStatus(from neStatus: NEVPNStatus) {
        switch neStatus {
        case .connected:
            status = .connected
            isConnected = true
            isConnecting = false
            errorMessage = nil
            
        case .connecting:
            status = .connecting
            isConnected = false
            isConnecting = true
            errorMessage = nil
            
        case .disconnected:
            status = .disconnected
            isConnected = false
            isConnecting = false
            
        case .disconnecting:
            status = .disconnecting
            isConnected = false
            isConnecting = true
            
        case .invalid:
            status = .invalid
            isConnected = false
            isConnecting = false
            errorMessage = "VPN configuration is invalid"
            
        @unknown default:
            status = .invalid
            isConnected = false
            isConnecting = false
        }
    }
}

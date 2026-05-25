//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Network Extension packet tunnel provider for ByeByeDPI
//

import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private let logger = OSLog(subsystem: "com.byebyedpi.PacketTunnel", category: "PacketTunnel")
    private var byeDpiProxy: ByeDpiProxy?
    private var isRunning = false
    
    // MARK: - NEPacketTunnelProvider
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("Starting packet tunnel...", log: logger, type: .info)
        
        guard let options = options,
              let args = options["arguments"] as? [String] else {
            os_log("No arguments provided", log: logger, type: .error)
            completionHandler(NSError(domain: "PacketTunnel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No arguments provided"]))
            return
        }
        
        os_log("Arguments: %{public}@", log: logger, type: .info, args.joined(separator: " "))
        
        // Configure network settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // Set up DNS servers
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        
        // Set up IP settings for the tunnel interface
        settings.ipv4Settings = NEIPv4Settings(
            addresses: ["10.0.0.1"],
            subnetMasks: ["255.255.255.0"]
        )
        
        // Route all traffic through the tunnel
        settings.ipv4Settings?.includedRoutes = [
            NEIPv4Route.default()
        ]
        
        // Optional: IPv6 support
        settings.ipv6Settings = NEIPv6Settings(
            addresses: ["fd00::1"],
            networkPrefixLengths: [64]
        )
        settings.ipv6Settings?.includedRoutes = [
            NEIPv6Route.default()
        ]
        
        // MTU settings
        settings.mtu = 1500
        
        // Apply settings and complete
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                os_log("Failed to set tunnel settings: %{public}@", log: self!.logger, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }
            
            // Start byedpi proxy
            self?.startByeDpi(with: args, completion: completionHandler)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("Stopping packet tunnel with reason: %{public}d", log: logger, type: .info, reason.rawValue)
        
        // Stop byedpi proxy
        byeDpiProxy?.stop()
        byeDpiProxy = nil
        isRunning = false
        
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Handle messages from the main app if needed
        os_log("Received app message: %{public}@", log: logger, type: .info, messageData.count)
        
        if let completionHandler = completionHandler {
            completionHandler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        os_log("Tunnel going to sleep", log: logger, type: .info)
        completionHandler()
    }
    
    override func wake() {
        os_log("Tunnel waking up", log: logger, type: .info)
    }
    
    // MARK: - Private Methods
    
    private func startByeDpi(with args: [String], completion: @escaping (Error?) -> Void) {
        os_log("Starting byedpi proxy", log: logger, type: .info)
        
        do {
            byeDpiProxy = try ByeDpiProxy(arguments: args)
            
            // Get the file descriptor for the tunnel device
            guard let tunnelFD = self.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 else {
                throw NSError(domain: "PacketTunnel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get tunnel file descriptor"])
            }
            
            try byeDpiProxy?.start(tunnelFD: tunnelFD)
            isRunning = true
            
            os_log("byedpi proxy started successfully", log: logger, type: .info)
            completion(nil)
            
        } catch {
            os_log("Failed to start byedpi proxy: %{public}@", log: logger, type: .error, error.localizedDescription)
            completion(error)
        }
    }
}

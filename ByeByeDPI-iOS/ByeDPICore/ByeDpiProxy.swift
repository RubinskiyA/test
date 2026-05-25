//
//  ByeDpiProxy.swift
//  ByeDPICore
//
//  Swift wrapper for byedpi C library
//

import Foundation

public enum ByeDpiError: Error, LocalizedError {
    case initializationFailed(String)
    case startFailed(String)
    case invalidArguments
    case tunnelFDNotFound
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Failed to initialize byedpi: \(message)"
        case .startFailed(let message):
            return "Failed to start byedpi: \(message)"
        case .invalidArguments:
            return "Invalid arguments provided to byedpi"
        case .tunnelFDNotFound:
            return "Could not obtain tunnel file descriptor"
        }
    }
}

public class ByeDpiProxy {
    private var isRunning = false
    private let arguments: [String]
    
    public init(arguments: [String]) throws {
        guard !arguments.isEmpty else {
            throw ByeDpiError.invalidArguments
        }
        
        self.arguments = arguments
    }
    
    /// Start byedpi with the tunnel file descriptor
    public func start(tunnelFD: Int32) throws {
        guard !isRunning else {
            return
        }
        
        // Convert Swift strings to C strings
        var cArgs: [UnsafeMutablePointer<CChar>?] = arguments.map { arg in
            strdup(arg)
        }
        cArgs.append(nil) // Null-terminate the array
        
        defer {
            // Free allocated C strings
            for ptr in cArgs.dropLast() {
                free(ptr)
            }
        }
        
        // Initialize byedpi
        let initResult = cArgs.withUnsafeMutableBufferPointer { buffer in
            bye_dpi_init(buffer.baseAddress!, Int32(arguments.count))
        }
        
        if initResult != 0 {
            let errorMessage = String(cString: bye_dpi_get_error())
            throw ByeDpiError.initializationFailed(errorMessage)
        }
        
        // Start byedpi with tunnel FD
        let startResult = bye_dpi_start(tunnelFD)
        
        if startResult != 0 {
            let errorMessage = String(cString: bye_dpi_get_error())
            throw ByeDpiError.startFailed(errorMessage)
        }
        
        isRunning = true
    }
    
    /// Stop byedpi
    public func stop() {
        guard isRunning else {
            return
        }
        
        bye_dpi_stop()
        isRunning = false
    }
    
    /// Check if byedpi is currently running
    public func isRunning() -> Bool {
        return bye_dpi_is_running() != 0
    }
}

// MARK: - C Function Imports

@_silgen_name("bye_dpi_init")
func bye_dpi_init(_ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>?, _ argc: Int32) -> Int32

@_silgen_name("bye_dpi_start")
func bye_dpi_start(_ tunnel_fd: Int32) -> Int32

@_silgen_name("bye_dpi_stop")
func bye_dpi_stop()

@_silgen_name("bye_dpi_is_running")
func bye_dpi_is_running() -> Int32

@_silgen_name("bye_dpi_get_error")
func bye_dpi_get_error() -> UnsafePointer<CChar>

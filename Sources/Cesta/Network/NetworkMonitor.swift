//
//  NetworkMonitor.swift
//
//
//  Created by Jonathan Gikabu on 12/10/2023.
//

import Foundation
import Network

public class NetworkMonitor: ObservableObject {
    public static let `default`: NetworkMonitor = NetworkMonitor()
    
    @Published public var connected: Bool = false
    @Published public var status: NWPath.Status = .unsatisfied
    @Published public var interface: NetworkInterface = .none
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue.main
    
    private init() {}
    
    public var currentPath: NWPath {
        pathMonitor.currentPath
    }
    
    public func start() {
        pathMonitor.pathUpdateHandler = { [self] path in
            status = path.status
            interface = NetworkInterface.fromPath(path)
            connected = path.status == .satisfied
            switch path.status {
            case .satisfied:
                log.info("network usable: \(interface.description)")
            default:
                log.error("network not usable: \(interface.description), desc: \(path.debugDescription)")
            }
        }
        
        pathMonitor.start(queue: monitorQueue)
    }
}

public enum NetworkInterface: CustomStringConvertible {
    case wifi, cellular, wiredEthernet, other, none
    
    public var description: String {
        switch self {
        case .cellular:
            return "Cellular"
        case .wifi:
            return "Wi-Fi"
        case .wiredEthernet:
            return "Wired Ethernet"
        case .other:
            return "Unknown"
        case .none:
            return "No Connection"
        }
    }
    
    public static func fromPath(_ path: NWPath) -> Self {
        return if path.status == .unsatisfied {
            .none
        } else if path.usesInterfaceType(.wifi) {
            .wifi
        } else if path.usesInterfaceType(.cellular) {
            .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            .wiredEthernet
        } else {
            .other
        }
    }
}

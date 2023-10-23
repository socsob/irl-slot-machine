//
//  WatchConnectivity.swift
//  slotme
//
//  Created by Andrew Canter on 10/18/23.
//

import WatchConnectivity

class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var shouldPerformAction: Bool = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.default.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let request = message["request"] as? String, request == "performAction" {
            DispatchQueue.main.async {
                self.shouldPerformAction = true
            }
        }
    }
}

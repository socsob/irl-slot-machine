//
//  WatchConnection.swift
//  slotme
//
//  Created by Andrew Canter on 10/18/23.
//

import WatchConnectivity

class WatchConnection: NSObject, ObservableObject, WCSessionDelegate {
    
    
    
    @Published var shouldPerformAction: Bool = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }
        }
        
        func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
            
        }

        private func executeAction() {
            // Your function logic here
            print("Function executed due to Watch signal!")
        }
}

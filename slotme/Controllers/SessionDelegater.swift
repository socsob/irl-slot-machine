//
//  SessionDelegater.swift
//  slotme
//
//  Created by Andrew Canter on 10/18/23.
//

import Combine
import WatchConnectivity

class SessionDelegater: NSObject, ObservableObject, WCSessionDelegate {
    @Published var shouldSpin: Bool = false
    
    override init() {
            super.init()
            setupSession()
        }
    
    private func setupSession() {
        if WCSession.isSupported() {

                let session = WCSession.default
                session.delegate = self
                session.activate()
            print(WCSession.isSupported() ? "SUPPORT" : "NOT SUPPORT")
            // IS WATCH PAIRED??? idk
            print(session.isPaired ? "PAIRED" : "NOT PAIRED")
            print(session.isReachable ? "REACHABLE" : "NOT REAC")
            print(session.isComplicationEnabled ? "COMP" : "NOT COMP")
            print(session.activationState == WCSessionActivationState.activated ? "ACTIVE" : "NOT ACT")



            }
        }
    
    
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Delegater")
        if let request = message["request"] as? String, request == "spin" {
                    DispatchQueue.main.async {
                        self.shouldSpin = true
                    }
                }
    }
    
    // iOS Protocol comformance
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
}


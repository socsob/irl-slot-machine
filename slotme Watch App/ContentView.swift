//
//  ContentView.swift
//  slotme Watch App
//
//  Created by Andrew Canter on 9/16/23.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    
    init() {
        WCSession.default.activate()
    }
    
    var body: some View {
        VStack {
            Button("Signal iPhone") {
                sendSignalToiPhone()
            }
        }
    }
    
    func sendSignalToiPhone() {
        WCSession.default.sendMessage(["request": "spin"], replyHandler: nil, errorHandler: nil)
        
        if WCSession.default.isReachable {
            print("watchTest2")
            WCSession.default.sendMessage(["request": "spin"], replyHandler: nil, errorHandler: nil)
        }
    }
}

struct WatchContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

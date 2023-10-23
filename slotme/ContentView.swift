//
//  ContentView.swift
//  slotme
//
//  Created by Andrew Canter on 9/16/23.
//

import SwiftUI
import Combine



struct ContentView: View {
    @State private var isPopupVisible = false
    @State private var emojiPairs: [(emoji: String, value: String)] = []
    @State private var isLongPress = false
    let maxSymbols = 5
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = true
    
    @ObservedObject var sessionDelegater = SessionDelegater()
    
    
    // Tupple of last index to roll (precomputed) along with animations
    let winnableAnimationPairs: [(Int, [Int])] = [(2,[10,20,30]),(0,[30,20,10]),(1,[20,30,10])]
    let loseAnimations = [[20,23,25],[20,30,33],[20,28,25]]
    // First 5 are for symbols, last 2 are for near miss and miss weight
    @State private var symbolWeightPairs: [(String, Int)] = [("", 0),("", 0),("", 0),("", 0),("", 0),("",0),("",0)]
    //Separated to avoid life cycle issues
    @StateObject var columnOneViewModel = SlotMachineColumnViewModel()
    @StateObject var columnTwoViewModel = SlotMachineColumnViewModel()
    @StateObject var columnThreeViewModel = SlotMachineColumnViewModel()
    func updateModelToSpinColumn(viewModel: SlotMachineColumnViewModel, winningSymbol: String, animationLength: Int) {
        viewModel.spinSignaled = true
        viewModel.riggedSymbol = winningSymbol
        viewModel.animationLength = animationLength
    }
    
    func spinSlot() {
        let symbolArray = symbolWeightPairs.map { $0.0 }
        let possibleSymbols = symbolArray.filter{ $0 != ""}
        let winningIndex = weightedRandomSelection(from: symbolWeightPairs.map {$0.1})
        
        var animationTimes: [Int] = []
        var rollSymbols: [String] = []
        // If full miss
        if (possibleSymbols.count == 0 || winningIndex == -1) {
            isPopupVisible = true
            return
        }
        else if (winningIndex == 6) {
            animationTimes = loseAnimations.randomElement() ?? [0,0,0]
            if (possibleSymbols.count > 2) {
                var symbolsList = possibleSymbols.shuffled()
                rollSymbols = [symbolsList.popLast() ?? ":(" ,symbolsList.popLast() ?? ":(",symbolsList.popLast() ?? ":("]
            } else {
                rollSymbols = ["B", "A", "D"]
            }
        } else {
            let animationTimePair = winnableAnimationPairs.randomElement() ?? (0,[0,0,0])
            animationTimes = animationTimePair.1
            // If near miss
            if (winningIndex == 5) {
                let winningAnimationIndex = animationTimePair.0
                if (possibleSymbols.count > 1) {
                    var symbolsList = possibleSymbols.shuffled()
                    let trickSymbol = symbolsList.popLast() ?? ":/"
                    rollSymbols = [String](repeating: trickSymbol, count: 3)
                    rollSymbols[winningAnimationIndex] = symbolsList.popLast() ?? ":/"
                } else {
                    // If this triggers they deserve it
                    rollSymbols = [String](repeating: "FU", count: 3)
                    rollSymbols[winningAnimationIndex] = "🖕"
                }
            } else {
                let winSymbol = possibleSymbols[winningIndex]
                rollSymbols = [String](repeating: winSymbol, count: 3)
            }
        }
        updateModelToSpinColumn(viewModel: columnOneViewModel, winningSymbol: rollSymbols[0], animationLength: animationTimes[0])
        updateModelToSpinColumn(viewModel: columnTwoViewModel, winningSymbol: rollSymbols[1], animationLength: animationTimes[1])
        updateModelToSpinColumn(viewModel: columnThreeViewModel, winningSymbol: rollSymbols[2], animationLength: animationTimes[2])
    }
    
    func weightedRandomSelection(from weights: [Int]) -> Int {
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return -1 }
        
        let randomValue = Int.random(in: 0..<totalWeight)
        var weightSum = 0
        
        for (index, weight) in weights.enumerated() {            weightSum += weight
            if weightSum > randomValue {
                return index
            }
        }
        
        return -1
    }
    init() {
        if let storedDictArray = UserDefaults.standard.value(forKey: "symbolWeightPairs") as? [[String: Any]] {
            let retrievedPairs: [(String, Int)] = storedDictArray.compactMap {
                if let str = $0["string"] as? String, let int = $0["int"] as? Int {
                    return (str, int)
                }
                return nil
            }
            _symbolWeightPairs = State(initialValue: retrievedPairs)
        }
    }
    
    var body: some View {
        ZStack {
            let possibleSymbols = symbolWeightPairs.map { $0.0 }.filter{ $0 != ""}
            SlotMachineColumn(possibleSymbols: possibleSymbols, widthPosition:  UIScreen.main.bounds.size.width / 4, viewModel: columnOneViewModel)
            SlotMachineColumn(possibleSymbols: possibleSymbols, widthPosition:  UIScreen.main.bounds.size.width / 2 , viewModel: columnTwoViewModel)
            SlotMachineColumn(possibleSymbols: possibleSymbols, widthPosition:  UIScreen.main.bounds.size.width * 3 / 4, viewModel: columnThreeViewModel)
            Button(action: {
                if isPopupVisible && !isLongPress {
                    isPopupVisible = false
                    let dictArray = symbolWeightPairs.map { ["string": $0.0, "int": $0.1] }
                    UserDefaults.standard.setValue(dictArray, forKey: "symbolWeightPairs")
                }
                else if !isLongPress {
                    spinSlot()
                }
            }) {
                Color.clear
                    .edgesIgnoringSafeArea(.all)
            }
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onChanged { _ in
                isLongPress = false
            }
                .onEnded { _ in
                    isLongPress = true
                    isPopupVisible = true
                })
            if isPopupVisible {
                RoundedRectangle(cornerRadius: 15)
                
                    .fill(Color(.systemBackground))
                    .frame(width: UIScreen.main.bounds.size.width * 0.8, height: UIScreen.main.bounds.size.height * 0.8)
                    .shadow(radius: 10)
                    .overlay(VStack {
                        Text("Settings").font(.system(size:35))
                        HStack(spacing: 20) {
                            VStack(spacing: 20) {
                                Text("Symbols")
                                Text("Weight")
                            }
                            ForEach(0..<maxSymbols, id: \.self) { index in
                                VStack(spacing: 20) {
                                    TextField("Symbol \(index)", text: $symbolWeightPairs[index].0)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .highPriorityGesture(TapGesture().onEnded { })
                                    TextField("Weight \(index)", value: $symbolWeightPairs[index].1, formatter: formatter)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .highPriorityGesture(TapGesture().onEnded { })
                                }
                            }
                        }
                        HStack(spacing: 20) {
                            Text("Near Miss Weight")
                            TextField("Weight", value: $symbolWeightPairs[5].1, formatter: formatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .highPriorityGesture(TapGesture().onEnded { })
                            Text("Miss Weight")
                            TextField("Weight", value: $symbolWeightPairs[6].1, formatter: formatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .highPriorityGesture(TapGesture().onEnded { })
                        }
                    }.padding())
            }
        }
        .onReceive(sessionDelegater.$shouldSpin) { newValue in
            print("receiving")
            
                    if newValue {
                        print("received")
                        spinSlot()
                        DispatchQueue.main.async {
                            sessionDelegater.shouldSpin = false
                        }
                    }
                }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                }
        )
        .background(isPopupVisible ? Color(.systemBackground).opacity(0.3).edgesIgnoringSafeArea(.all) : nil)
        //        .sheet(isPresented: $showingImagePicker) {
        //                    ImagePicker(image: $inputImage)
        //                }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}


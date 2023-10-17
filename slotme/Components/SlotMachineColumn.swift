//
//  SlotMachineColumn.swift
//  slotme
//
//  Created by Andrew Canter on 10/8/23.
//

import SwiftUI

class SlotMachineColumnViewModel: ObservableObject {
    @Published var spinSignaled: Bool = false
    @Published var riggedSymbol: String = ""
    @Published var animationLength: Int = 0
}

struct SlotMachineColumn: View {
    // Relates to parent view calling the spin function
    // Relates to initial setup of the column
    @ObservedObject var viewModel: SlotMachineColumnViewModel
    let possibleSymbols: [String]
    let widthPosition: CGFloat
    
    let rows = 5
    let symbolSize: CGFloat = 150
    //  These variables are determined by the same spacing
    let screenHeight = UIScreen.main.bounds.size.height
    let rowSize = UIScreen.main.bounds.size.height / 2
    @State private var rowPositions: [CGFloat] = [UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.height / 2, 0, -UIScreen.main.bounds.size.height / 2, -UIScreen.main.bounds.size.height]
    @State private var timerInterval: Double = 0.1
    @State private var timer: Timer?
    @State private var rowSymbols: [String] = []
    init(possibleSymbols: [String], widthPosition: CGFloat, viewModel: SlotMachineColumnViewModel) {
        self.possibleSymbols = possibleSymbols
        self.widthPosition = widthPosition
        self.viewModel = viewModel
        _rowSymbols = State(initialValue: (0..<rows).map { _ in possibleSymbols.randomElement()! })
    }
    func spinColumn() {
        timer?.invalidate() // Invalidate the old timer just in case
        var timerLoop = 0
        let animationLength = viewModel.animationLength
        let riggedSymbol = viewModel.riggedSymbol
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            
            
            for index in 0..<rows {
                //additional .01 added to prevent slight stutter
                
                withAnimation(.linear(duration: timerInterval + 0.01)) {
                    self.rowPositions[index] += self.rowSize
                }
                
                if self.rowPositions[index] > self.screenHeight + self.rowSize {
                    
                    self.rowPositions[index] = -self.rowSize
                    self.rowSymbols[index] = self.possibleSymbols.randomElement()!
                    // Rigs the final symbol
                    if (timerLoop == animationLength - 2) {
                        rowSymbols[index] = riggedSymbol
                    }
                }
            }
            timerLoop += 1
            
            if (timerLoop > animationLength) {
                self.timer?.invalidate()
            }
        }
    }
    var body: some View {
        ZStack {
            ForEach(0..<rows, id: \.self) { index in
                Text(rowSymbols[index])
                    .font(.system(size: symbolSize))
                    .position(x: widthPosition, y: rowPositions[index])
            }
        }
        .onReceive(viewModel.$spinSignaled) { newValue in
                    if newValue {
                        spinColumn() // start spinning
                        DispatchQueue.main.async {
                            viewModel.spinSignaled = false // reset the value after handling
                        }
                    }
                }
        .edgesIgnoringSafeArea(.all)
        .onDisappear {timer?.invalidate()}
    }
}


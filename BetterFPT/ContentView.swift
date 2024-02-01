//
//  ContentView.swift
//  BetterFPT
//
//  Created by Saurabh Sikka A on 01/02/2024.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State private var f0: Int64 = 0
    @State private var f1: Int64 = 0
    @State private var f2: Int64 = 0
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Section {
                        Text("What is the F0 estimate?")
                        TextField("F0 estimate", value: $f0, formatter: NumberFormatter()).keyboardType(.numberPad)
                    }
                    Section {
                        Text("What is the F1 estimate?")
                        TextField("F1 estimate", value: $f1, formatter: NumberFormatter()).keyboardType(.numberPad)
                    }
                    Section {
                        Text("What is the F2 Estimate?")
                        TextField("F2 estimate", value: $f2, formatter: NumberFormatter()).keyboardType(.numberPad)
                    }
                    
                }
                .navigationTitle("Feature Cost Estimator")
                .toolbar {
                    Button("Calculate", action: calculate)
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK") {}
                } message: {
                    Text(alertMessage)
                }
            }
        }
    }
    
    func calculate() {
        do {
            let config = MLModelConfiguration()
            let model = try realdeal(configuration: config)
            let prediction = try model.prediction(F0_mhrs: Int64(f0), F1_mhrs: Int64(f1), F2_mhrs: Int64(f2))
            let finalEstimate = prediction.Real_Hours
            let fE = Int(finalEstimate)
            alertTitle = "Expect to actually burn"
            alertMessage = "\(fE) mhrs"
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem"
        }
        
        showingAlert = true
        
    }
    
}




//
//  ContentView.swift
//  BetterFPT
//
//  Created by Saurabh Sikka A on 01/02/2024.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State private var fptID: String = ""
    @State private var createdDate: Date = Date.now
    @State private var f0: Int64 = 501
    @State private var f1: Int64 = 500
    @State private var f2: Int64 = 500
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Section {
                        HStack {
                            Text("FPT Item ID:")
                            TextField("FPT Item ID", text: $fptID).bold().textFieldStyle(.roundedBorder)
                        }
                    }
                    Section {
                        DatePicker("Item Created on", selection: $createdDate, displayedComponents: [.date])
                    }.foregroundColor(.blue)
                    Section {
                        HStack {
                            Text("F0 estimate:")
                            TextField("F0", value: $f0, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.green)
                        }.padding()
                    }
                    Section {
                        HStack {
                            Text("F1 estimate:")
                            TextField("F1", value: $f1, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.green)
                        }.padding()
                    }
                    Section {
                        HStack {
                            Text("F2 estimate:")
                            TextField("F2", value: $f2, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.green)
                        }.padding()
                    }
                }
                .navigationTitle("Feature Predictor Tool")
                .toolbar {
                    Button("Calculate", action: calculate).foregroundColor(.white).buttonStyle(.borderedProminent)
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK") {}
                } message: {
                    Text(alertMessage)
                }
                Section {
                    Text(alertMessage).font(.footnote)
                    ShareLink(item:  alertMessage)
                }
            }
        }
    }
    
    func calculate() {
        do {
            // calculate Cost
            let config = MLModelConfiguration()
            let model = try superinfCost(configuration: config)
            // this model has a RMSE of 67.7, it was trained on > 2 million items, with 1000 iterations of training on boosted tree algorithm
            // which is the best available training
            let prediction = try model.prediction(F0: Int64(f0), F1: Int64(f1), F2: Int64(f2))
            let finalEstimate = prediction.Cost
            let fE = Int(finalEstimate) // this is the Final Estimated Cost
            
            // calculate turnaround Date
            let conf = MLModelConfiguration()
            let turnmodel = try superTurnx(configuration: conf)
            let pred = try turnmodel.prediction(F0: Int64(f0), F1: Int64(f1), F2: Int64(f2))
            let turnaround = pred.Turnaround
            // result of turnaround is in hours, so convert to seconds and add that to created date
            let turnaroundTime = Int(turnaround / 24)
            let deliveryDate = createdDate + ((turnaround) * 3600)
            let cDay = createdDate.formatted(date: .abbreviated, time: .omitted)
            let dDay = deliveryDate.formatted(date: .abbreviated, time: .omitted)
            
            alertTitle = "Prediction"
            alertMessage = "The FPT item \(fptID) created on \(cDay) has a projected turnaround time of \(turnaroundTime) days. Based on historical trends this indicates that \(fptID) should be in FG status by \(dDay).\nImplementation is predicted to have a Final Cost of \(fE) Real Hours"
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem"
        }
        
        showingAlert = true
    }
}



#Preview {
    ContentView()
}



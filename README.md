Introduction

This is a quick and dirty primer on how we can create a machine learning model using Apple's Create ML framework and use it in an app. 

What we used
macOS 10.14 Mojave or later
Xcode 10 or later
Data set to train the model, extracted from F-state mhrs from FPT
Preparation

We used the CreateML app to perform regression analysis on a data set to create our machine learning model.

Regression analysis is a set of statistical processes for estimating the relationships between a dependent variable (outcome) and one or more independent variables (predictors or covariates). 

Machine learning is done in two steps: we train the model, then we ask the model to make predictions.

Training is the process of the computer looking at all our data to figure out the relationship between all the values we have.
Prediction is done on device: we feed it the trained model, and it will use previous results to make estimates about new data.
Steps:

Open the Create ML app on your Mac. 

Click New Document > choose Tabular Regression and press Next.

For the project name enter BetterFPT, then press Next, select your development folder, then press Create.

Import Data

For this app we exported data from FPT for the last 10 years of features marked as Done in CN COS&UDM IMS Product Development Program

exported it to xlsx




Next we refined for F-status estimates, Cost, and Turnaround Time in hours (Created Date - FG Date) as below:

F0

	

F1

	

F2

	

Cost

	

Turnaround




1300

	

780

	

600

	

550

	

16032




250

	

250

	

300

	

214

	

10296




Exported the data in CSV format:

F0,F1,F2,Cost,Turnaround
1300,780,600,550,16032
250,250,300,214,10296
...




Create Machine Learning Model

The first step is to provide Create ML with the training data. The data in the CSV fie was refined and extrapolated to create a training sample size of more than 2 million entries

Next, in Create ML look under the Training Data title and import the CSV file.




Choose Target

The next job is to decide the target, which is the value we want the computer to learn to predict, and the features, which are the values we want the computer to inspect in order to predict the target. 

In this instance, we chose “Cost” for the target, which means we want the computer to learn how to predict how much will be the F4 Cost burned at the end of the project, and for the input variables we chose F0, F1, F2 mhrs under Features – we want the computer to take all three of those into account when producing its predictions.




Below the Select Features button is a dropdown button for the algorithm, and there are five options: Automatic, Random Forest, Boosted Tree, Decision Tree, and Linear Regression.

We chose Boosted Tree with 1000 iterations of training 

Training Results

To see how the training went, select the Evaluation tab then choose Validation to see some result metrics. The value we care about is called Root Mean Squared Error

and we got value of 68.2.

This means on average the model was able to predict suggested accurate F4 Cost with an error of about 68 mhrs. This was the best result achieved after applying all permutations and combinations of training algorithms.

Create ML provides us with both Training and Validation statistics, and both are important. When we asked it to train using our data, it automatically split the data up: some to use for training its machine learning model, but then it held back a chunk for validation. This validation data is then used to check its model: it makes a prediction based on the input, then checks how far that prediction was off the real value that came from the data.

If you go to the Output tab you’ll see an our finished model has a file size of 88 bytes. Create ML has taken 13KB of data, and condensed it down to just 88 bytes.

The actual amount of space taken up by the hard data – how to predict the F4 cost based on our three variables – is well under 88 bytes. This is possible because Create ML doesn’t actually care what the values are, it only cares what the relationships are. So, it spent a couple of billion CPU cycles trying out various combinations of weights for each of the features to see which ones produce the closest value to the actual target, and once it knows the best algorithm it simply stores that.

Use the Model in an Application

Now that our model is trained, press the Get button to export it to your desktop, so we can use it in code.




Open up Xcode and create a new Project called BetterFPT. Then drag and drop the ML model file from the desktop to the Project Files:

Xcode will automatically create a Model Class that we can then import.

Similarly, we created another Model for Turnaround Time, and the Content of the application is as follows:

```
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
        NavigationStack {
            Form {
                VStack {
                    Section {
                        HStack {
                            Text("FPT Item ID:")
                            TextField("FPT Item ID", text: $fptID).bold()
                        }
                    }
                    Section {
                        DatePicker("Item Created on", selection: $createdDate, displayedComponents: [.date])
                    }
                    Section {
                        HStack {
                            Text("F0 estimate").bold()
                            TextField("F0 estimate", value: $f0, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.blue)
                        }
                    }
                    Section {
                        HStack {
                            Text("F1 estimate").bold()
                            TextField("F1 estimate", value: $f1, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.blue)
                        }
                    }
                    Section {
                        HStack {
                            Text("F2 estimate").bold()
                            TextField("F2 estimate", value: $f2, formatter: NumberFormatter()).keyboardType(.numberPad).foregroundColor(.blue)
                        }
                    }
                }
                .navigationTitle("Feature Predictor")
                .toolbar {
                    Button("Calculate", action: calculate)
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK") {}
                    Button("Copy",action: copyPrediction)
                } message: {
                    Text(alertMessage)
                }
                Section {
                    Text(alertMessage).fontWeight(.bold)
                    ShareLink(item: alertMessage)
                    
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
            alertMessage = "The FPT item \(fptID) created on \(cDay) has a projected turnaround time of \(turnaroundTime) days, which means that the item should be in FG status by \(dDay).\nImplementation is predicted to have a Final Cost of \(fE) Real Hours"
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem"
        }
        
        showingAlert = true
    }
    
    func copyPrediction() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = alertMessage
    }
    
}
       
```



Build and Run

The code will build and run on your device / simulator. It was tested on MacOS, and iOS - but it should also work for VisionOS  

Fill in the details and press the Calculate button.




The results appear as an Alert Box, with the option to Copy the results:

On dismissal, the results are also populated in the text area below, and can be shared using the system dialog:




Manual Validation

We can manually validate the results using the original exported data from FPT.

In the example below, we picked a random feature and entered the date it was created in FPT, the F0, F1, F2 hours and validated the prediction from the original data.



The error is in the range of ±1 day for turnaround time, and ±1 hour for Final Cost




















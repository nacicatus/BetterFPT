# Introduction

This is a quick and dirty primer on how we can create a machine learning model using Apple's Create ML framework and use it in an app. 

## What we used
- macOS 10.14 Mojave or later
- Xcode 10 or later
- Data set to train the model, extracted from F-state mhrs from FPT

## Preparation

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

exported it to xlsx, refined for F status estimates as below



The first step is to provide Create ML with some training data. This is the raw statistics for it to look at, which in our case consists of five values:

F0 mhrs
F1 mhrs
F2 mhrs
Cost mhrs
Turnaround (days)

## Create Machine Learning Model

In Create ML look under Data and choose “Select…” under the Training Data title and import the CSV file.


## Choose Target

The next job is to decide the target, which is the value we want the computer to learn to predict, and the features, which are the values we want the computer to inspect in order to predict the target. 

In this instance, we chose “Real Hours” for the target, which means we want the computer to learn how to predict how much will be the F4 Cost burned at the end of the project, and for the input variables we chose F0, F1, F2 mhrs under Features – we want the computer to take all three of those into account when producing its predictions.



Below the Select Features button is a dropdown button for the algorithm, and there are five options: Automatic, Random Forest, Boosted Tree, Decision Tree, and Linear Regression. Each takes a different approach to analyzing data, but helpfully there is an Automatic option that attempts to choose the best algorithm automatically. It’s not always correct, but for this project it’s more than good enough.


## Train the Model

Click the Train button in the window title bar. After a couple of seconds it will complete, and you’ll see a big checkmark telling you that everything went to plan.

To see how the training went, select the Evaluation tab then choose Validation to see some result metrics. The value we care about is called Root Mean Squared Error

and we got value around about 366.

This means on average the model was able to predict suggested accurate F4 cost with an error of about 366 mhrs. It's not the best, but with a small sample size as we used, it is to be expected.

### How it works on the inside 

Create ML provides us with both Training and Validation statistics, and both are important. When we asked it to train using our data, it automatically split the data up: some to use for training its machine learning model, but then it held back a chunk for validation. This validation data is then used to check its model: it makes a prediction based on the input, then checks how far that prediction was off the real value that came from the data.

If you go to the Output tab you’ll see an our finished model has a file size of 88 bytes. Create ML has taken 13KB of data, and condensed it down to just 88 bytes.

The actual amount of space taken up by the hard data – how to predict the F4 cost based on our three variables – is well under 88 bytes. This is possible because Create ML doesn’t actually care what the values are, it only cares what the relationships are. So, it spent a couple of billion CPU cycles trying out various combinations of weights for each of the features to see which ones produce the closest value to the actual target, and once it knows the best algorithm it simply stores that.

## Use the Model in an App

Now that our model is trained, press the Get button to export it to your desktop, so we can use it in code.

Open up Xcode and create a new Project called BetterFPT. Then drag and drop the ML model file from the desktop to the Project Files:

Xcode will automatically create a Model Class that we can then import:

```swift
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

```


## Build and Run on iPhone simulator, fill in the details and press the Calculate button:

In this example, we set

F0 cost to 1001 (our usual Large T-shirt size estimate),

F1 cost as 1234, and

F2 cost as 1440.

The app used the Machine Learning Model to calculate the projected F4 cost to be 1527 mhrs



Note: Our sample size only used 603 data points. We would need a much larger data set (> 10000) in order to make more accurate predictions

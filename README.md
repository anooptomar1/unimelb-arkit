# Unimelb ARKit
Author: chesdametrey SENG

## Overview

This application development is a part of software development project at The University of Mebourne. 3D visualisation of placing 3D virtual object in the scene is implemented in this application. Object tracking that allow tracking of QR code in real time. CoreML visual enables the user to detect and classify the main object in the camera frame. 3D meaurement is implemented with 2 different types of meaurement, either by press and hold the meauring button or tap the screen to specify the two points user want to measure.

## Running the source code

Unimelb ARKit app is built on ARKit framework that require iOS 11 with A9 (or later) processor. ARKit applications are not able to run on iOS Stimilator

*important:*
Training model name Resnet50 is used and can be downloaded from Apple developer website (Apple, 2017).
Link: https://developer.apple.com/machine-learning/
Direct link: https://docs-assets.developer.apple.com/coreml/models/Resnet50.mlmodel

If error occur that mean, Resnet50 model needs to be replaced with a new one. Simply  dowload the new Resnet50 model and copy it to Resources folder in the soruce code.
After imported, please click on the Resnet50 model on file navigator, and check UnimelbARKit  in target membership on the right view of XCode.


## Import third party 3D models

Apple prefers 3D model with extension of .scn. Other extension can be imported and convert to .scn extension.
Import Step:

- creat a new folder in Models.scnassets with the same name as your 3D model, place your 3D model and its associate files in that folder
- modify VirtualObjects.json file in Virtual Object folder with the name of your 3D model
- add a png image to Assets.xcassets (same name as your 3D model)
- the new object will now appear on the virtual object selection list in the app
* 3D model with different extension might need to be converted to .scn extension with some modification

## References
- Apple 2017, Model, "ResNet50",  https://developer.apple.com/machine-learning/
- Apple 2017 , "Get Started witth ARKit", https://developer.apple.com/arkit/





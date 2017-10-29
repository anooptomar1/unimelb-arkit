
//
//  ViewController .swift
//  UnimelbARKit
//
//  Main view controller for the AR experience.
//
//  Created by CHESDAMETREY on 05/08/17.
//  Copyright © 2017 com.chesdametrey. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import UIKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate,UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate{
    
    
    // MARK: - CoreML properties
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    // MARK: - Vision properties
    var detectedDataAnchor: ARAnchor?
    var processing = false
    
    // MARK: - Haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    // MARK: - ARKit Config Properties
    
    var screenCenter: CGPoint?
    let session = ARSession()
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    // MARK: - Virtual Object Manipulation Properties
    
    var dragOnInfinitePlanesEnabled = false
    var virtualObjectManager: VirtualObjectManager!
    
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.settingsButton.isEnabled = !self.isLoadingObject
                self.addObjectButton.isEnabled = !self.isLoadingObject
                self.restartExperienceButton.isEnabled = !self.isLoadingObject
            }
        }
    }
    
    // MARK: - Other Properties
    var textManager: TextManager!
    var restartExperienceButtonIsEnabled = true
    
    // MARK: - UI Elements
    var spinner: UIActivityIndicatorView?
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var restartExperienceButton: UIButton!
    
    // MARK: - measurement properties
    var measureNode : [SCNNode] = []
    var measure:Bool = false
    @IBOutlet weak var aimLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var meaureButton: UIButton!
    let vectorZero = SCNVector3()
    var measuring = false
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    
    // MARK: - Queues
    
    let serialQueue = DispatchQueue(label: "com.apple.arkitexample.serialSceneKitQueue")
    
    // MARK: - View Controller Life Cycle
    //var i = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add long guester to Measuring button
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        meaureButton.addGestureRecognizer(longPress)
        
        //add press guester to Measuring button
        let press = UITapGestureRecognizer(target: self, action: #selector(handlePress))
        meaureButton.addGestureRecognizer(press)
        
        Setting.registerDefaults()
        updateSetting()
        setupUIControls()
        setupScene()
        setupCoreML()
        setupCamera()
    }

    
    // call to generate a short haptic feedback
    func hapticFeedback(){
        generator.impactOccurred()
    }
    
    func setupCamera(){
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        //Enable HDR camera settings for the most realistic appearance
        //with environmental lighting and physically based materials.
 
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    func setupCoreML(){
        // Set up Vision Model
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: model, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]

    }
    
    // call when coreML button is press, take the current camera frame to classify object
    func updateCoreML(){
        
        // get the current frame from camera session
        let pixbuff : CVPixelBuffer? = (self.sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        
        // convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)

        // Prepare and handle image for CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    // handle 3D visual textnode for classified object
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {

            guard let observations = request.results as? [VNClassificationObservation], let resultIn = observations.first else {
                print("No results")
                return
            }
            let result = resultIn.identifier
            self.coreMLLabel.text = result
            let position = self.sceneView.realWorldVector(screenPos: self.view.center)!
            let color = self.getNewColor()
            self.sceneView.scene.rootNode.addChildNode(SCNText.text(distance: result, color: color,position: position))
            
        }
    }


    // MARK: - functions for handling meaurement button gestures
    @objc
    func handleLongPress (gestureReconizer: UILongPressGestureRecognizer){
        
        if (gestureReconizer.state == UIGestureRecognizerState.began){
            measuring = true
            hapticFeedback()
            self.meaureButton.setImage(#imageLiteral(resourceName: "shutterRed"), for: .normal)
        }
        if (gestureReconizer.state == UIGestureRecognizerState.ended){
            measuring = false
            hapticFeedback()
            self.meaureButton.setImage(#imageLiteral(resourceName: "buttonring"), for: .normal)
            
            // add the last sphere node when the touch is ended
            let endSphere = SphereNode(position: endValue, color: newColor)
            secondDot = endSphere
            sceneView.scene.rootNode.addChildNode(secondDot)
        }
    }
    @objc
    func handlePress (gestureReconizer: UILongPressGestureRecognizer){
        resetValues()
        removeAllMeaurementNode()
        hapticFeedback()
    }
    
    @IBOutlet weak var coreMLLabel: UILabel!
    @IBAction func coreMLButton(_ sender: Any) {
        hapticFeedback()
        self.coreMLBut.setImage(#imageLiteral(resourceName: "shutterPressed"), for: .highlighted)
        self.updateCoreML()
        
    }
    @IBOutlet weak var coreMLBut: UIButton!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        if ARWorldTrackingConfiguration.isSupported {
            // Start the ARSession.
            resetTracking()
        } else {
            // This device does not support 6DOF world tracking.
            let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
            "Please quit the application."
            displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    // MARK: - Setup
    
    func setupScene() {
        // Synchronize updates via the `serialQueue`.
        virtualObjectManager = VirtualObjectManager(updateQueue: serialQueue)
        virtualObjectManager.delegate = self
        
        // set up scene view
        sceneView.setup()
        sceneView.delegate = self
        sceneView.session = session
        
        // set session delegate to self other session frame is not working
        sceneView.session.delegate = self

        sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
        setupFocusSquare()

        // Progressivey update the posititon of aiming label for meauring
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
    }
    
    
    // MARK: - VISION
    // this delegate run analyse everyframe of the image, combine with vision to detect QR code, once the QR
    // code is detected, it will update  the "detectedDataAnchor" variable which will further pricess
    // at Func didAdd
    
    
    // Mark: - ARSession Delegate : processing every frames
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if enableQRTracking{
            // Only run one Vision request at a time
            if self.processing {
                return
            }
            self.processing = true
            
            // Create a Barcode Detection Request
            let request = VNDetectBarcodesRequest { (request, error) in
                
                
                // Get the first result out of the results, if there are any
                if let results = request.results, let result = results.first as? VNBarcodeObservation {
                    
                    // Get the bounding box for the bar code and find the center
                    var rect = result.boundingBox
                    
                    // Flip coordinates
                    rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                    rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
                    
                    // Get center
                    let center = CGPoint(x: rect.midX, y: rect.midY)
                    
                    // Go back to the main thread
                    DispatchQueue.main.async {
                        
                        // Perform a hit test on the ARFrame to find a surface
                        let hitTestResults = frame.hitTest(center, types: [.featurePoint] )
                        
                        // If we have a result, process it
                        if let hitTestResult = hitTestResults.first {
                            
                            // If we already have an anchor, update the position of the attached node
                            if let detectedDataAnchor = self.detectedDataAnchor,
                                let node = self.sceneView.node(for: detectedDataAnchor) {
                                
                                node.transform = SCNMatrix4(hitTestResult.worldTransform)
                                
                            } else {
                                // Create an anchor. The node will be created in delegate methods
                                self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                                self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                            }
                        }
                        
                        // Set processing flag off
                        self.processing = false
                    }
                    
                } else {
                    // Set processing flag off
                    self.processing = false
                }
            }
            
            // Process the request in the background
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Set it to recognize QR code only
                    request.symbologies = [.QR]
                    
                    // Create a request handler using the captured image from the ARFrame
                    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                    options: [:])
                    // Process the request
                    try imageRequestHandler.perform([request])
                } catch {
                    
                }
            }
        }
    }

    func setupUIControls() {
        textManager = TextManager(viewController: self)
        
        // Set appearance of message output panel
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
    }
    
    // Call to reset all value of meaurement operation
    func resetValues() {
        
        measuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
        updateResultLabel(0.0)
    }
    
    // Meaurement properties
    @IBOutlet weak var cmLabel: UILabel!
    @IBOutlet weak var inchLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    
    // format float number to CM and Inch
    func updateResultLabel(_ value: Float) {
        let cm = value * 100.0
        let inch = cm*0.3937007874
        // update distance label
        distanceLabel.text = String(format: "%.2f cm | %.2f\"", cm, inch)
        
        cmLabel.text = String(format: "%.2f cm",cm)
        inchLabel.text = String(format: "%.2f\"", inch)
    }
    
    // convert any float type to string type
    func convert(_ value: Float) -> String{
        let cm = value * 100.0
        
        let format = String(format: "%.2f cm", cm)
        return format
    }
    
    
    // Mark: - Tap measurement
    var tapMesure = false
    // Store two points of vector3
    var tapMeasureArray = [SCNVector3]()
    
    // MARK: - Gesture Recognizers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesBegan(touches, with: event, in: self.sceneView)
        
        // run this only camera tracking state is normal
        if isCameraTrackingNormal {
            
            // touch position of the screen convert to SCNVector 3
            let position = sceneView.realWorldVector(screenPos: (touches.first?.location(in: sceneView))!)!
            
            // check if tap measure feature is on, allow user to place point by touching
            if (tapMesure){
                hapticFeedback()
                
                // add a 3D visual dot when on touch
                let firstSphere = SphereNode(position: position, color: newColor)
                self.sceneView.scene.rootNode.addChildNode(firstSphere)
                
                // append the array of tap position
                tapMeasureArray.append(position)
                
                // if dotmeaureArray has two element, compute the distance and empty the array
                if tapMeasureArray.count == 2 {
                    let start = tapMeasureArray[0]
                    let end = tapMeasureArray[1]
                    
                    // update result label with the calculated distance
                    let distance = start.distance(from: end)
                    updateResultLabel(distance)
                    
                    // add a visual line between two points
                    let line = SCNGeometry.line(from:start, to:end)
                    line.materials.first?.diffuse.contents = newColor.withAlphaComponent(7.75)
                    let lineNode = SCNNode(geometry: line)
                    lineNode.position = SCNVector3Zero
                    
                    // add line and text to the scene
                    sceneView.scene.rootNode.addChildNode(lineNode)
                    sceneView.scene.rootNode.addChildNode(SCNText.text(distance: convert(distance), color: newColor,position: end))
                    
                    // empty array
                    tapMeasureArray.removeAll()
                    newColor = self.getNewColor()
                }
            }
        }
    }
    

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjectManager.virtualObjects.isEmpty {
            
            //uncomment this if want the object selection to apear when ever a tap is detected
            //chooseObject(addObjectButton)
            return
        }
        virtualObjectManager.reactToTouchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesCancelled(touches, with: event)
    }
    
    // MARK: - Planes
    
    var planes = [ARPlaneAnchor: Plane]()
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {

        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
        
        // Show plane visualisation if the switch in on
        if showPlaneVisual{
            
            //Construct plane material
            let planesss = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
            let material = SCNMaterial()
            let img = #imageLiteral(resourceName: "tron_grid")
            material.diffuse.contents = img
            
            // Set grid image to 1" per square (image is 0.4064 m)
            material.diffuse.wrapT = .repeat
            material.diffuse.wrapS = .repeat
            material.diffuse.contentsTransform = SCNMatrix4MakeScale(2.46062992 * anchor.extent.x, 2.46062992 * anchor.extent.z, 0)
            
            planesss.materials = [material]
            
            let planeNode = SCNNode(geometry: planesss)
            planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
            
            // SCNPlanes are vertically oriented in their local coordinate space.
            // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            // add plane with material to the node
            node.addChildNode(planeNode)
        }

        // schedule message
        textManager.cancelScheduledMessage(forType: .planeEstimation)
        textManager.showMessage("SURFACE DETECTED")
        if virtualObjectManager.virtualObjects.isEmpty {
            textManager.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
        }
    }
    
    // function to update existing plane
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
            
        }

    }
    
    // function to remove existing place
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    // function to reset tracking
    func resetTracking() {
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT",
                                    inSeconds: 7.5,
                                    messageType: .planeEstimation)
    }
    
    // MARK: - Focus Square
    
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        serialQueue.async {
            self.focusSquare?.isHidden = true
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
        }
        
        textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    
    func updateFocusSquare() {

        guard let screenCenter = screenCenter else { return }
        
        DispatchQueue.main.async {
            var objectVisible = false
            for object in self.virtualObjectManager.virtualObjects {
                if self.sceneView.isNode(object, insideFrustumOf: self.sceneView.pointOfView!) {
                    objectVisible = true
                    break
                }
            }
            //show focussqaure, if the switch is on
            if UserDefaults.standard.bool(for: .focusSquare){
                
                // hide focussqaure if 3D object is presented in the current camera frame
                if objectVisible {
                    self.focusSquare?.hide()
                } else {
                    self.focusSquare?.unhide()
                }
            }else{
                self.focusSquare?.hide()
            }
            
            
            let (worldPos, planeAnchor, _) = self.virtualObjectManager.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.simdPosition)
            if let worldPos = worldPos {
                self.serialQueue.async {
                    self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
                }
                self.textManager.cancelScheduledMessage(forType: .focusSquare)
            }
        }
        
        
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        // Blur the background.
        textManager.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
                self.restartExperience(self)
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateFocusSquare()
        
        // compute runMeasurement method continously if the meaurement button is triggered on
        DispatchQueue.main.async {
            if (!self.meaureButton.isHidden){
                self.runMeasurement()
            }
            
        }
        
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        if let lightEstimate = session.currentFrame?.lightEstimate {
            sceneView.scene.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40, queue: serialQueue)
        } else {
            sceneView.scene.enableEnvironmentMapWithIntensity(40, queue: serialQueue)
        }
        
        
    }
    
    // MARK: - Undo last measurement
    @IBOutlet weak var undoButton: UIButton!
    
    @IBAction func undoMeasureButton(_ sender: Any) {
        hapticFeedback()
        // measureNode.last
        lastLineNode.removeFromParentNode()
        lastTextNode.removeFromParentNode()
        firstDot.removeFromParentNode()
        secondDot.removeFromParentNode()
        resetValues()
        
    }
    
    // MARK: - Tap measurement function
    
    // tap measurement properties
    @IBOutlet weak var tapMButton: UIButton!
    var tapMeaureButtonFlag = true
    
    @IBAction func tapMeasureButton(_ sender: Any) {
        hapticFeedback()
        
        // set tapmeaurebutton to on and off
        if tapMeaureButtonFlag {
            let im = UIImage(named: "2MeasurePressed") as UIImage?
            tapMesure = true
            tapMButton.setImage(im, for: .normal)
            meaureButton.isHidden = true
            aimLabel.isHidden = true
            
            self.present(AlertView().showAlertView(title:"2 points measure",message: "Two points measure is ON, tap on the start point and end point"), animated: true, completion: nil)
            tapMeaureButtonFlag = false
        }else{
            let im = UIImage(named: "2Measure") as UIImage?
            tapMButton.setImage(im, for: .normal)
            meaureButton.isHidden = false
            aimLabel.isHidden = false
            tapMesure = false
            tapMeaureButtonFlag = true

        }
        
    }
    
    //MARK: - 2 Points measurment by holding measure button with the aim label as the staring point
    
    // Measurement properties
    var isStarted = false
    var lastLineNode = SCNNode()
    var firstDot = SCNNode()
    var secondDot = SCNNode()
    var lastTextNode = SCNNode()
    var newColor = UIColor.brown
    
    // Main function for meaurement, called continously when the measureButton is held
    func runMeasurement() {
        
        // pass the CGPoint of the center of the veiw and transform to SCNVector3
        if let worldPos = sceneView.realWorldVector(screenPos: view.center) {

            // while meauring
            if measuring {
                if startValue == vectorZero {
                    startValue = worldPos
                }
                endValue = worldPos
                
                // calcualte distance between start and end value
                let distance = startValue.distance(from: endValue)
                
                // update new calcualted distance result label
                updateResultLabel(distance)
                
                // Creat a text and return a node
                let textNode = SCNText.text(distance: convert(distance), color: newColor, position: endValue)
                let firstSphere = SphereNode(position: startValue, color: newColor)
                
                // add a visual line between the start and end point
                let line = SCNGeometry.line(from:startValue, to:endValue)
                line.materials.first?.diffuse.contents = newColor.withAlphaComponent(0.75)
                let lineNode = SCNNode(geometry: line)
                lineNode.position = SCNVector3Zero
                
                // if the meaurement has started
                if (!isStarted){
                    
                    // add line and point visual object to the scene
                    sceneView.scene.rootNode.addChildNode(lineNode)
                    sceneView.scene.rootNode.addChildNode(firstSphere)
                    lastLineNode = lineNode
                    firstDot = firstSphere

                    isStarted = true
                    
                    // add new meaurement node to this list
                    measureNode.append(lineNode)
                    
                    sceneView.scene.rootNode.addChildNode(textNode)
                    lastTextNode = textNode
                }
                else{
                    
                    // as the user is still meauring, we need to remove the lastnode and replace it with a new one
                    // at every update
                    sceneView.scene.rootNode.replaceChildNode(lastLineNode, with: lineNode)
                    lastLineNode = lineNode
                    
                    sceneView.scene.rootNode.replaceChildNode(lastTextNode, with: textNode)
                    lastTextNode = textNode
                }
                
            }
            else{
                
                // reset
                newColor = getNewColor()
                startValue = worldPos
                isStarted = false
            }
        }
    }
    
    // remove every childNode use during meaurement
    func removeAllMeaurementNode (){
        
        print ("Reset all measurement node called")
        sceneView.scene.rootNode.enumerateChildNodes{ (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }


    // if new node is added, check self detectedAnchor if it's equal to the new node anchor
    // -> update QRcode tracking node by updating 3D visual to the new node
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // if QR tracking is ON add 3d object to detected node
        //if enableQRTracking{
            if self.detectedDataAnchor?.identifier == anchor.identifier {
            
                // Preapre a 3D visuat to place on the anchor
                let virtualObjectScene = SCNScene(named: "globe.scn", inDirectory: "Models.scnassets/globe")
            
                for child in (virtualObjectScene?.rootNode.childNodes)! {
                    child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                    child.movabilityHint = .movable
                    node.addChildNode(child)
                }
            }
        //}
        
        // add generic node
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        serialQueue.async {
            
            print("Node call******")
            self.addPlane(node: node, anchor: planeAnchor)
            self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        serialQueue.async {
            self.updatePlane(anchor: planeAnchor)
            self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
            
        }

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        serialQueue.async {
            self.removePlane(anchor: planeAnchor)
        }
    }
    
    // MARK: - Track camera states and responds
    var isCameraTrackingNormal = false
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            coreMLBut.isEnabled = false
            isCameraTrackingNormal = false
            meaureButton.isEnabled = false
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            coreMLBut.isEnabled = true
            isCameraTrackingNormal = true
            meaureButton.isEnabled = true
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard let arError = error as? ARError else { return }
        
        let nsError = error as NSError
        var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
        if let recoveryOptions = nsError.localizedRecoveryOptions {
            for option in recoveryOptions {
                sessionErrorMsg.append("\(option).")
            }
        }
        
        let isRecoverable = (arError.code == .worldTrackingFailed)
        if isRecoverable {
            sessionErrorMsg += "\nYou can try resetting the session or quit the application."
        } else {
            sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
        }
        
        displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        textManager.blurBackground()
        textManager.showAlert(title: "Session Restarted", message: "The session will be reset after the interruption has ended.")
        resetValues()
        removeAllMeaurementNode()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        textManager.unblurBackground()
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        restartExperience(self)
        textManager.showMessage("RESETTING SESSION")
    }
    
    // MARK: - ARSCNViewDelegate

    
    // MARK: - ACTION
    enum SegueIdentifier: String {
        case showSettings
        case showObjects
    }
    
    // MARK: - Interface Actions
    
    @IBAction func chooseObject(_ button: UIButton) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        
        textManager.cancelScheduledMessage(forType: .contentPlacement)
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: button)
    }
    
    @IBAction func showSettingButton(_ sender: UIButton) {
        hapticFeedback()
        updateSetting()
    }
    
    // call to initialise and update setting properties
    private func updateSetting(){
        let defaults = UserDefaults.standard
        
        showDebugVisuals = defaults.bool(for: .debugVisual)
        show3DMeasure = defaults.bool(for: .measure)
        enableQRTracking = defaults.bool(for: .QRTracking)
        showCoreML = defaults.bool(for: .coreML)
        showPlaneVisual = defaults.bool(for: .planeVisual)
        
 
    }

    /// - Tag: restartExperience
    @IBAction func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled, !isLoadingObject else { return }
        
        resetValues()
        hapticFeedback()
        removeAllMeaurementNode()
        
        DispatchQueue.main.async {
            self.restartExperienceButtonIsEnabled = false
            
            self.textManager.cancelAllScheduledMessages()
            self.textManager.dismissPresentedAlert()
            self.textManager.showMessage("STARTING A NEW SESSION")
            
            self.virtualObjectManager.removeAllVirtualObjects()
            self.addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
            self.addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
            self.focusSquare?.isHidden = true
            
            self.resetTracking()
            
            self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])
            
            // Show the focus square after a short delay to ensure all plane anchors have been deleted.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.setupFocusSquare()
            })
            
            // Disable Restart button for a while in order to give the session enough time to restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                self.restartExperienceButtonIsEnabled = true
            })
        }
    }
    
    
    
    
    // MARK: - Settings properties
    
    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugVisual) {
        didSet {
            
            // planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            
            if showDebugVisuals {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
                //sceneView.showsStatistics = true
            } else {
                sceneView.debugOptions = []
                //sceneView.showsStatistics = false
            }
            
            // save preferences
            UserDefaults.standard.set(showDebugVisuals, for: .debugVisual)
        }
    }
    
    // MARK: - Extra features properties
    
    // variable for 3D meaurement feature
    var show3DMeasure: Bool = UserDefaults.standard.bool(for: .measure){
        
        didSet {
            
            // planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            // handle visibility of other features
            if show3DMeasure {
                
                aimLabel.isHidden = false
                distanceLabel.isHidden = true
                distanceView.isHidden = false
                meaureButton.isHidden = false
                addObjectButton.isHidden = true
                undoButton.isHidden = false
                tapMButton.isHidden = false
                
            } else {
                tapMesure = false
                meaureButton.isHidden = true
                distanceLabel.isHidden = true
                distanceView.isHidden = true
                aimLabel.isHidden = true
                addObjectButton.isHidden = false
                undoButton.isHidden = true
                updateFocusSquare()
                tapMButton.isHidden = true
                
            }
            
            // save pref
            UserDefaults.standard.set(show3DMeasure, for: .measure)
        }
        
    }
    
    // variable for QR code tracking feature
    var enableQRTracking: Bool = UserDefaults.standard.bool(for: .QRTracking){
        
        didSet{
            if enableQRTracking{
                print(" QR Tracking : on ")
            }else{
                print(" QR Tracking : off ")
            }
            
            // save preference
            UserDefaults.standard.set(enableQRTracking, for: .QRTracking)
            
        }
    }
    
    // variable for CoreML visual feature
    var showCoreML: Bool = UserDefaults.standard.bool(for: .coreML){
        
        didSet{
            // handle visibility of other features
            if showCoreML{
                coreMLBut.isHidden = false
                coreMLLabel.isHidden = false
            }else{
                coreMLBut.isHidden = true
                coreMLLabel.isHidden = true
            }
            // save preference
            UserDefaults.standard.set(showCoreML, for: .coreML)
            
        }
    }
    
    // variable for plane visualisation
    var showPlaneVisual: Bool = UserDefaults.standard.bool(for: .planeVisual){
        
        didSet{
            if showPlaneVisual{
                print(" Plane Visual : on ")
            }else{
                print(" Plane Visual : off ")
            }
            // save preference
            UserDefaults.standard.set(showPlaneVisual, for: .planeVisual)
            
        }
    }
    
    // variable for focus square visual
    var showFocusSquare: Bool = UserDefaults.standard.bool(for: .focusSquare){
        didSet{
            UserDefaults.standard.set(showFocusSquare, for: .focusSquare)
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // update setting when the pop over setting view is dismiss
        hapticFeedback()
        updateSetting()

    }
    
    // MARK : - prepare for segue to other view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // All popover segues should be popovers even on iPhone.
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier, let segueIdentifer = SegueIdentifier(rawValue: identifier) else { return }
        if segueIdentifer == .showObjects, let objectsViewController = segue.destination as? VirtualObjectSelectionViewController {
            objectsViewController.delegate = self
            hapticFeedback()
        }
        
        // if setting view is trigger on or off, update setting
        if segueIdentifer == .showSettings{
            updateSetting()
        }
    
    }
    
    // generate and return a random color
    func getNewColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 //
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    // MARK: - ACTION
}


//
//  SphereNode.swift
//  UnimelbARKit
//
//  Created by CHESDAMETREY on 22/9/17.
//  Copyright © 2017 com.chesdametrey. All rights reserved.
//

import SceneKit

class SphereNode: SCNNode {
    init(position: SCNVector3 , color: UIColor) {
        super.init()
        let sphereGeometry = SCNSphere(radius: 0.002)
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        sphereGeometry.materials = [material]
        self.geometry = sphereGeometry
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

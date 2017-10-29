//
//  GeometryExtensions.swift
//  UnimelbARKit
//
//  Created by CHESDAMETREY on 04/9/17.
//  Copyright © 2017 com.chesdametrey. All rights reserved.
//

import Foundation
import ARKit

// MARK: - scene geometry extensions
extension SCNGeometry{
    
    // Return a geomrey line with the length from vector 1 - vectior 2
    class func line (from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry{
        let indices: [Int32] = [0,1]
        let source = SCNGeometrySource (vertices: [vector1,vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension SCNText{

    class func text (distance: String, color: UIColor, position: SCNVector3) -> SCNNode {
     
        let text = SCNText(string: distance, extrusionDepth: 0.2)
        text.firstMaterial?.diffuse.contents = color
        text.firstMaterial?.specular.contents = UIColor.white
        text.firstMaterial?.lightingModel = .physicallyBased
        // text.flatness = 5
        
        text.font = UIFont(name: "Arial", size:0.5)
        //text.containerFrame = CGRect(x:-2,y:-4, width: 10, height:10)
        
        
        let textNode = SCNNode(geometry: text)
        //textNode.geometry = text
        textNode.position = SCNVector3(position.x - 0.02 ,position.y,position.z)
        textNode.scale = SCNVector3(0.05,0.05,0.05)
        
        /*
        let (min, max) = textNode.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        */
        
        
        
        // uncommented this ***************** October
        //textNode.orientation = SCNQuaternion(x: position.x,y: position.y,z: position.z, w:0)
        //textNode.constraints = [SCNBillboardConstraint()]
        
        return textNode
    }
    

    

    
    
}


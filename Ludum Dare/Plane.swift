//
//  Plane.swift
//  PlaneOverlaying
//
//  Created by Artem Novichkov on 22/07/2017.
//  Copyright © 2017 Artem Novichkov. All rights reserved.
//

import SceneKit
import ARKit

final class Plane: SCNNode {
    
    let anchor: ARPlaneAnchor
    var plane: SCNPlane?
    var planeNode: SCNNode?
    
    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(withAnchor anchor: ARPlaneAnchor) {
        plane?.width = CGFloat(anchor.extent.x)
        plane?.height = CGFloat(anchor.extent.z)
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    }
    
    private func setup() {
        plane = SCNPlane(width: CGFloat(anchor.extent.x),
                         height: CGFloat(anchor.extent.z))
        
        let material = SCNMaterial()
        material.diffuse.contents = #imageLiteral(resourceName: "overlay_grid")
        plane?.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2), 1, 0, 0)
        
        addChildNode(planeNode)
        self.planeNode = planeNode
    }
}

//
//  Utils.swift
//  Ludum Dare
//
//  Created by Nikita Ermolenko on 29/07/2017.
//  Copyright © 2017 Artem Novichkov. All rights reserved.
//

import Foundation
import SceneKit

extension Float {

    var toDegrees: Float {
        return self * 180 / Float.pi
    }

    var toRadians: Float {
        return self * Float.pi / 180 
    }
}

extension SCNVector3 {
    
    /**
     Calculates vector length based on Pythagoras theorem
     */
    var length: Float {
        return sqrtf(x*x + z*z)
    }
    
    /**
     Calculates dot product to vector
     */
    func dot(toVector: SCNVector3) -> Float {
        return x * toVector.x + z * toVector.z
    }
}

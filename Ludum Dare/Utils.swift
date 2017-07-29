//
//  Utils.swift
//  Ludum Dare
//
//  Created by Nikita Ermolenko on 29/07/2017.
//  Copyright © 2017 Artem Novichkov. All rights reserved.
//

import Foundation

extension Float {

    var toDegrees: Float {
        return self * 180 / Float.pi
    }

    var toRadians: Float {
        return self * Float.pi / 180 
    }
}

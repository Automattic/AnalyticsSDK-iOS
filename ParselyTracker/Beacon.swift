//
//  beacon.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class Beacon {
    let pixel: Pixel
    
    init() {
        self.pixel = Pixel()
    }

    func trackPageView(params: [String: Any], shouldNotSetLastRequest: Bool) {
        let data: [String: Any] = [
            "action": "pageview",
            "date": Date()
        ]
        let updateData = data.merging(
                params, uniquingKeysWith: { (old, _new) in old }
        )
        self.pixel.beacon(data: updateData, shouldNotSetLastRequest: shouldNotSetLastRequest)
    }
    
}

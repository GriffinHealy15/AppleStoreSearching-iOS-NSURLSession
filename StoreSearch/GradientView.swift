//
//  GradientView.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/18/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
class GradientView: UIView {
    override init(frame: CGRect) { // create gradient view instance
        super.init(frame: frame) // frame is passed from dimmingView.frame = containerView!.bounds  in DimmingPresentationController
        autoresizingMask = [.flexibleWidth , .flexibleHeight] // change size to match superview size when superview rotates, etc.
        backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autoresizingMask = [.flexibleWidth , .flexibleHeight]
        backgroundColor = UIColor.clear
    }
    override func draw(_ rect: CGRect) {
        // 1
        let components: [CGFloat] = [ 0, 0, 0, 0.3, 0, 0, 0, 0.7 ]  // rgb + opacity
        let locations: [CGFloat] = [ 0, 1 ]
        // 2
        let colorSpace = CGColorSpaceCreateDeviceRGB() // rgb color space
        let gradient = CGGradient(colorSpace: colorSpace, // gradient object with colors and locations of each gradient from 0% to 100%, we use beginning (0) and end (100)
                                  colorComponents: components,
                                  // 3
            locations: locations, count: 2) // give count of gradients to
        let x = bounds.midX // mid point x
        let y = bounds.midY // mid point y
        let centerPoint = CGPoint(x: x, y : y) // center using x and y
        let radius = max(x, y) // radius is max of x and y, if rectangle either x or y is biggest
        // 4
        let context = UIGraphicsGetCurrentContext() // get current graphics context
        context?.drawRadialGradient(gradient!, // draw the gradient defined
            // draw around the entire rectangle
                                    startCenter: centerPoint, startRadius: 0,
                                    endCenter: centerPoint, endRadius: radius,
                                    options: .drawsAfterEndLocation)
    } }

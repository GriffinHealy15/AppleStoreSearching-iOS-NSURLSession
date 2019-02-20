//
//   SlideOutAnimationController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/18/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
// Dismissing a view controller may use the -func animationController(forDismissed dismissed: ...)-
// protocol methods from (UIViewControllerTransitioningDelegate) (if our controller is delegate)
// animationController(forDismissed dismissed: asks us for a custom animation controller to use when it dismisses the view controller. We give it this, SlideOutAnimationController
class SlideOutAnimationController: NSObject,
UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3 // time of the animation
    }
    func animateTransition(using transitionContext: // the animation
        UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.view(forKey: // view to animate
            UITransitionContextViewKey.from) {
            let containerView = transitionContext.containerView
            let time = transitionDuration(using: transitionContext) // ask for 0.3 from above
            UIView.animate(withDuration: time, animations: {
                fromView.center.y -= containerView.bounds.size.height // take center y position and subtract container view height (406-812 = -406)
                // fromView.center.y has a new placement of -406 on the y pos
                fromView.transform = CGAffineTransform(rotationAngle: .pi)
                fromView.transform = CGAffineTransform(scaleX: 0.25,  y: 0.25) // reduce size to half
            }, completion: { finished in
            transitionContext.completeTransition(finished)
                    })
        }
    }
}


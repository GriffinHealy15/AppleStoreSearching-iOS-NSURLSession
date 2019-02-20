//
//  FadeOutAnimationController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/20/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
class FadeOutAnimationController: NSObject,
UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext:
        UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4 } // animation duration length
    func animateTransition(using transitionContext:
        UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.view( // view to animate during transition
            forKey: UITransitionContextViewKey.from) {
            let time = transitionDuration(using: transitionContext) // time 0.4 with view context
            UIView.animate(withDuration: time, animations: {
                fromView.alpha = 0 // animate to transparent
            }, completion: { finished in // completion handler
                transitionContext.completeTransition(finished) // notify system transition is done
            })
        } }
}

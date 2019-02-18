//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/18/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
// Animates the DetailViewController
// To become an animation controller, the object needs to extend NSObject and also implement the UIViewControllerAnimatedTransitioning protocol
class BounceAnimationController: NSObject,
UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext:
        UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5 } // length of animation
    func animateTransition(using transitionContext: // the actual animation
        UIViewControllerContextTransitioning) {
        if let toViewController = transitionContext.viewController( // reference to viewController
            forKey: UITransitionContextViewControllerKey.to),
            let toView = transitionContext.view(
                forKey: UITransitionContextViewKey.to) {
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
                containerView.addSubview(toView) // superview is containerView
            toView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1) // start view smaller
            UIView.animateKeyframes(withDuration: transitionDuration(
                using: transitionContext), delay: 0, options:
                .calculationModeCubic, animations: {
                  // tranformation animations are here
                    UIView.addKeyframe(withRelativeStartTime: 0.0,
                  relativeDuration: 0.20, animations: {
                   toView.transform = CGAffineTransform(scaleX: 0.15, y: 0.4)
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.20,
                    relativeDuration: 0.20, animations: {
                    toView.transform = CGAffineTransform(scaleX: 0.25, y: 0.7)
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.40,
                    relativeDuration: 0.20, animations: {
                    toView.transform = CGAffineTransform(scaleX: 0.45, y: 1.3)
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.60,
                    relativeDuration: 0.20, animations: {
                     toView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0.80,
                    relativeDuration: 0.20, animations: {
                    toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    })
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } }
}

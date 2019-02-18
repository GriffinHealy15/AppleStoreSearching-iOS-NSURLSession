//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/15/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
// Custom Presentation Controller
class DimmingPresentationController: UIPresentationController {
    override var shouldRemovePresentersView: Bool {
        return false // don't remove the presenter controller
    }
    // when 
    lazy var dimmingView = GradientView(frame: CGRect.zero) // set the dimming view (GradientView)
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds // set the frame so gradient view can calculate
        containerView!.insertSubview(dimmingView, at: 0) // insert the dimming newely created dimmingView above the container view, but below the DetailViewController view.
        
        // Animate background gradient view
        dimmingView.alpha = 0
        if let coordinator =
            presentedViewController.transitionCoordinator { // presentation controllers and animation controller, plus more
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1 // animate to fade in to 1 - 100%
            }, completion: nil)
        }
    }
    // animate gradient view out of sight when pop-up is dismissed
    override func dismissalTransitionWillBegin()  {
        if let coordinator =
            presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0 // animate gradient back to transparency
            }, completion: nil)
        } }
    
}

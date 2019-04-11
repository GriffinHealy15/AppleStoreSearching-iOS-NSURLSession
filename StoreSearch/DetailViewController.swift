//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/15/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//
//

import UIKit
import AudioToolbox
import MessageUI

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    var searchResult: SearchResult! {
        didSet { // after property SearchResult changes (given object), call upDateUI
            if isViewLoaded { // view is loaded for iPads because of split controllers
                updateUI() }
        } }// searchResult object set with prepareForSegue code
    var downloadTask: URLSessionDownloadTask?
    var soundID: SystemSoundID = 0
    var ispopup = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom // .custom means system calls presentationController method where it ask us the delegate (set in line below) if we have a custom presentation controller to use instead ( we use DimmingPresentationController)
        transitioningDelegate = self // set transitioningDelegate to this view controller now
    }
    
    deinit { // deinit is called whenever the object instance is deallocated and its memory is reclaimed. That happens after the user closes the DetailViewController and the animation to remove it from the screen has completed
        print("deinit \(self)")
        downloadTask?.cancel() // cancel downloadTask if view is deinitialized
    }
    
    enum AnimationStyle {
        case slide
        case fade }
    var dismissStyle = AnimationStyle.fade

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor(red: 20/255, green: 160/255, // change tint color on whole view
                                 blue: 160/255, alpha: 1)
        popupView.layer.cornerRadius = 10 // ask popupView for its layer and set corner radius
        
        if ispopup {
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(close))
            gestureRecognizer.cancelsTouchesInView = false
            gestureRecognizer.delegate = self
            view.addGestureRecognizer(gestureRecognizer)
            view.backgroundColor = UIColor.clear
        } else {
            if let displayName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
                title = displayName
            }
            view.backgroundColor = UIColor(patternImage:
                UIImage(named: "LandscapeBackground")!)
            popupView.isHidden = true
        }
        
        if searchResult != nil { // if we have searchResult obj, update the UI with what was passed
            updateUI()
        }
    }
    
    // MARK:- Helper Methods
    func updateUI() { // when segue happens, it sets this controllers searchResult object
        nameLabel.text = searchResult.name // set all the outlet properties with searchResult info
        if searchResult.artist.isEmpty {
            artistNameLabel.text = NSLocalizedString("Unknown", comment: "Localized Kind: Unknown")
        } else {
            artistNameLabel.text = searchResult.artist
        }
        kindLabel.text = searchResult.type
        genreLabel.text = searchResult.genre
        
        // Show price
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = searchResult.currency
        let priceText: String
        if searchResult.price == 0 {
            priceText = NSLocalizedString("Free", comment: "Localized kind: Free")
        } else if let text = formatter.string(
            from: searchResult.price as NSNumber) {
            priceText = text
        } else {
            priceText = ""
        }
        priceButton.setTitle(priceText, for: .normal)
        
        // Get image
        if let largeURL = URL(string: searchResult.imageLarge) {
            downloadTask = artworkImageView.loadImage(url: largeURL)//downloadTask lets deinitcancel
        }
        
        popupView.isHidden = false
    }
    
    // MARK:- Actions
    @IBAction func close() { // if close is tapped, button informs this action func to dismiss cntrl
        loadSoundEffect("swoosh.wav")
        playSoundEffect()
        dismissStyle = .slide
        dismiss(animated: true, completion: nil) // dismiss view controller presented modally
    }
    
    @IBAction func openInStore() {
        if let url = URL(string: searchResult.storeURL) { // get the searchResult object store url from trackViewUrl or collectionViewUrl
            loadSoundEffect("ching.wav")
            playSoundEffect()
            UIApplication.shared.open(url, options: [:], // product page will be opened for us
                                      completionHandler: nil)
        } }
    // MARK:- Sound effects
    func loadSoundEffect(_ name: String) {
        if let path = Bundle.main.path(forResource: name,
                                       ofType: nil) {
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(
                fileURL as CFURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound: \(path)")
            }
        } }
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0 }
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if segue.identifier == "ShowMenu" { // identifier is told to us when segue is about to happen
            // we get identifier and set dest and delegate of the controller we are about to open to us, this controller
            let controller = segue.destination as! MenuViewController
            controller.delegate = self
        }
    }
}

// we (this controller) are the delegate for transitions, so when when happens, we implement the functions where we say which
extension DetailViewController:
UIViewControllerTransitioningDelegate {
    // system calls this method because we use UIModalPresentationStyle.custom
    func presentationController( // system ask us, the delegate, for custom presentation controller
        forPresented presented: UIViewController,
        presenting: UIViewController?, source: UIViewController) ->
        UIPresentationController? {
            return DimmingPresentationController( // tell uikit to use dimmingpresentationcontroller
                presentedViewController: presented, presenting: presenting)
    }
    func animationController(forPresented presented: // ask us, the delegate, for the transition animator object when presenting a view controller
        UIViewController, presenting: UIViewController,
                          source: UIViewController) ->
        UIViewControllerAnimatedTransitioning? { // we implement this protocol method here
           // implementation of that protocol above must animate the appearance of the presented view controller’s view onscreen.
            return BounceAnimationController() // tell transition controller use this new animation controller instead of default
    }
    // Asks delegate (this controller) for the transition animator object to use when dismissing the view controller
    // This simply overrides the animation controller to be used when a view controller is dismissed.
    func animationController(forDismissed dismissed: // function called when dismissed() is called
        UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch dismissStyle {
        case .slide: // .slide is set everytime close() function is run
            return SlideOutAnimationController()
        case .fade: // default is .fade
            return FadeOutAnimationController()
        }
    }
}

extension DetailViewController: UIGestureRecognizerDelegate { // gesture recognizer delegate
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view) // self.view = DetailViewController
    } }

// Conform to new protocol by delclaring ourself, this class, the delegate of MenuViewController. We implement the methods of the protocol here
extension DetailViewController: MenuViewControllerDelegate {
    func menuViewControllerSendEmail(_: MenuViewController) {
        dismiss(animated: true) { // hide the popover
            // closure after animation of dismissing popover controller
            if MFMailComposeViewController.canSendMail() {
                let controller = MFMailComposeViewController() // bring up mail contrl
                controller.mailComposeDelegate = self // declare ourself delegate for the mail controller
                controller.setSubject(NSLocalizedString("Support Request",
                                                        comment: "Sending Email Through My App"))
                controller.setToRecipients(["griffinparkerhealy@gmail.com"])
                self.present(controller, animated: true, completion: nil)
            }
        }
    } }

// Here we delcare ourself a delegate of the MFMailComposeViewController
// So mail controller will send us the 'result' of email sending
extension DetailViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller:
        MFMailComposeViewController, didFinishWith result:
        MFMailComposeResult, error: Error?) {
        // after we press 'Send' or 'Cancel', doesn't matter the result of success sending, we dismiss the popover controller to show detail controller again
        dismiss(animated: true, completion: nil)
    } }

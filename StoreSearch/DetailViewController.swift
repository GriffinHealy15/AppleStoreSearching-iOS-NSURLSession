//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/15/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    var searchResult: SearchResult! // searchResult object set with prepareForSegue code
    var downloadTask: URLSessionDownloadTask?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self // set transitioningDelegate to this view controller
    }
    
    deinit { // deinit is called whenever the object instance is deallocated and its memory is reclaimed. That happens after the user closes the DetailViewController and the animation to remove it from the screen has completed
        print("deinit \(self)")
        downloadTask?.cancel() // cancel downloadTask if view is deinitialized
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor(red: 20/255, green: 160/255, // change tint color on whole view
                                 blue: 160/255, alpha: 1)
        popupView.layer.cornerRadius = 10 // ask popupView for its layer and set corner radius
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, // if true, dismiss the view
                                                       action: #selector(close))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self // delegate of gestureRecognizer is this controller
        view.addGestureRecognizer(gestureRecognizer)
        
        if searchResult != nil { // if we have searchResult obj, update the UI with what was passed
            updateUI()
        }
    }
    
    // MARK:- Helper Methods
    func updateUI() { // when segue happens, it sets this controllers searchResult object
        nameLabel.text = searchResult.name // set all the outlet properties with searchResult info
        if searchResult.artist.isEmpty {
            artistNameLabel.text = "Unknown"
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
            priceText = "Free"
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
    }
    
    // MARK:- Actions
    @IBAction func close() { // if close is tapped, button informs this action func to dismiss cntrl
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openInStore() {
        if let url = URL(string: searchResult.storeURL) { // get the searchResult object store url from trackViewUrl or collectionViewUrl
            UIApplication.shared.open(url, options: [:], // product page will be opened for us
                                      completionHandler: nil)
        } }
    
}

extension DetailViewController:
UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?, source: UIViewController) ->
        UIPresentationController? {
            return DimmingPresentationController( // tell uikit to use dimmingpresentationcontroller
                presentedViewController: presented, presenting: presenting)
    } }

extension DetailViewController: UIGestureRecognizerDelegate { // gesture recognizer delegate
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view) // self.view = DetailViewController
    } }

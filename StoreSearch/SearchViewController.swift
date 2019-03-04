//
//  ViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/8/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
import AudioToolbox

class SearchViewController: UIViewController {
    
    // weak vars prevented from deallocation by the superview (superview has strong reference)
    @IBOutlet weak var searchBar: UISearchBar! // connects to UISearchBar in storyboard
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // segment in storyboard tells this function their linked and for controller to run this method
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        loadSoundEffect("Tic.wav")
        playSoundEffect()
        //print(segmentedControl.selectedSegmentIndex)
        performSearch()
    }
    
    
    // Below: think of as empty array that can contain many SearchResult objects
    private let search = Search()
    var soundID: SystemSoundID = 0
    var landscapeVC: LandscapeViewController?
    weak var splitViewDetail: DetailViewController? 

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Search", comment: "split view master button")
        // if not iPad, open the keyboard right away
        if UIDevice.current.userInterfaceIdiom != .pad {
            searchBar.becomeFirstResponder()
        }
        // tell the tableView to add 20 point margin for status bar + 44 point margin for search bar + 44 point margin for navigation bar with segment control
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0,
                                              bottom: 0, right: 0)
        // load the nib file for use in code
        var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil)
        // register the nib for the tableView with reuse identifier "SearchResultCell"
        tableView.register(cellNib, forCellReuseIdentifier:
            TableView.CellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: // load the cell nib with identifier "NothingFoundCell"
            TableView.CellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: // tableView registers the new nib
            TableView.CellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableView.CellIdentifiers.loadingCell, // load the cell nib with the name "LoadingCell"
                        bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: // register the nib with tableview
            // tableView can now access the nib cell when asked to
            TableView.CellIdentifiers.loadingCell)
        
        // this makes it so whenever this controller opens we want to be notified of a content size change like bigger or smaller font
        listenForContentSizeChangeNotification() // when this view controller opens, call listen
    }
    
    override func willTransition(to newCollection:
        UITraitCollection, with coordinator:
        UIViewControllerTransitionCoordinator) {
        // for transitioning to iPhone plus models
        super.willTransition(to: newCollection, with: coordinator)
        let rect = UIScreen.main.bounds
        // if the bounds screen are as either below, then were using iPhone plus model
        if (rect.width == 736 && rect.height == 414) ||
            (rect.width == 414 && rect.height == 736) {
            if presentedViewController != nil { // dissmiss the popup
                dismiss(animated: true, completion: nil)
            }
            // portrait
            // landscape
            // else is for iPhones only
        } else if UIDevice.current.userInterfaceIdiom != .pad { // if not using iPad
            switch newCollection.verticalSizeClass {
            case .compact: // if vertical size class of going to be new orientation is .compact, then we are rotating to landscape, show we showLandscape()
                showLandscape(with: coordinator)
            case .regular, .unspecified: // if vertical size class is going to be .regular, we are switching to vertical and we hideLandscape()
                hideLandscape(with: coordinator)
            }
        } }
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }
    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if segue.identifier == "ShowDetail" { // if the segue has this identfier
            if case .results(let list) = search.state { // and state is .results
                let detailViewController = segue.destination
                    as! DetailViewController // this is our dest controller
                let indexPath = sender as! IndexPath // get index of row
                let searchResult = list[indexPath.row] // get item at the index
                detailViewController.ispopup = true
                detailViewController.searchResult = searchResult // set searchResult
            } }
    }
    
    func showNetworkError() {
        let alert = UIAlertController(title: NSLocalizedString("Whoops...", comment: "Error alert: title"), // obj alert controller that displays msg
                                      message: "There was an error accessing the iTunes Store." +
            " Please try again.", preferredStyle: .alert) // action taken when button pressed
        let action = UIAlertAction(title: "OK", style: .default,
                                   handler: nil)
        present(alert, animated: true, completion: nil) // present alert
        alert.addAction(action) // attaches action object to alert or action sheet
    }
    // automatically called with willTransition
    func showLandscape(with coordinator: // add landscape view controller as subview to parent
        // 1
        UIViewControllerTransitionCoordinator) {
        guard landscapeVC == nil else { return } // landscape nil, if has value then return
        // 2
        landscapeVC = storyboard!.instantiateViewController(
            withIdentifier: "LandscapeViewController") // find scene with identifier to instantiate
            as? LandscapeViewController
        if let controller = landscapeVC { // unwrap the optional
            // 3
            controller.view.frame = view.bounds // the frame of landscapeVC is size of SearchView
            controller.view.alpha = 0 // start alpha as transparent
            controller.search = search // set LandscapeVC with searchResults object
            // 4
            // Landscape screen “contained” in its parent view controller, and therefore owned and managed by the parent — it isn't independent like a modal screen.
            view.addSubview(controller.view) // add landscapeVC as subview on top of table, search
            addChild(controller)
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder() // hide keyboard
                if (self.presentedViewController != nil) {
                    self.dismiss(animated: true, completion: nil) // dismisses the pop-up
                }
            }, completion: { _ in // completion handler after animation is complete
                controller.didMove(toParent: self) // tell landscapeVC its parent is SearchView
            })
        } }
    func hideLandscape(with coordinator: // remove subview from the parent
        UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC { // if has value, continue to hiding
            controller.willMove(toParent: nil) // tell landscapeVC it is leaving and has no parent
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0 // set from 1 to 0 (transparent)
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: { _ in // completion handler after animation is complete
                controller.view.removeFromSuperview() // remove the view from the screen here
                controller.removeFromParent() // dispose of view controller
                self.landscapeVC = nil // remove strong references to landscapeVC
            })
        } }
    
    private func hideMasterPane() { // hide master pane for portrait mode
        UIView.animate(withDuration: 0.25, animations: {
            /*Every view controller has a built-in splitViewController property that is non-nil if the view controller is currently inside a UISplitViewController.*/
            self.splitViewController!.preferredDisplayMode =
                .primaryHidden // animate, .primaryHidden hides main view (master)
        }, completion: { _ in
            self.splitViewController!.preferredDisplayMode = .automatic // restore master pane
        }) }
    
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
    
    // MARK:- Notification listen for size change
    func listenForContentSizeChangeNotification() {
        NotificationCenter.default.addObserver( // tell notification center we want to be notified whenever a UIContentSizeCategory.didChangeNotification is posted. didChangeNotification is posted when user changes preffered content size setting, and we are told about it
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.tableView.reloadData()
                print("*** FontSizeDidChange. Reloaded tableView")
        }
    }
}

// SearchBarDelegate extension methods
// this (SearchViewController) declares itself a delegate for the search bar
// whenever the search bar is clicked, this controller implements searchBarSearchButtonClicked as to abide to the delegate protocol. The search bar passes the clicked (searched) text to this delegate method
extension SearchViewController: UISearchBarDelegate {
    // search bar tells us when it is clicked because we (controller) are its delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    func performSearch() {
        // take the index selected and convert raw value to value i.e. "Software", then pass category to performSearch function below
        if let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) {
        search.performSearch(for: searchBar.text!,
         category: category,
         // pass closure to performSearch in Search.swift class
         completion: { success in // completion depending on success true or false
         if !success { // if no success
          self.showNetworkError()
          }
        self.tableView.reloadData()
        // below line ignored if still in portrait mode after search completes
        self.landscapeVC?.searchResultsReceived() // inform landscape we have results
        })
        }
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached // status bar same as search bar color
    }
}
// this extension of SearchViewController to declare itself the delegate for the tableview in the storyboard. If we are the delegate, then tableview can pass us information, as long as we implement the delegate protocol methods.
// In previous apps: UITableViewController already conforms to these protocols by necessity.
// SearchViewController however, is a regular view controller and therefore you have to hook up the data source and delegate protocols yourself.
extension SearchViewController: UITableViewDelegate,
UITableViewDataSource {
    // below are required protocol methods, those that you need to implement to say "hey, i want to be your delegate, so you can pass me information. Tableview: "if you implement my methods, data is passed in them", is how it works really
    // override not used like in previous apps we built because were using a regular view controller which does not have any tableView methods to override. We just say were the delegate of a tableview and were implementing the tableview delegate methods, UITableViewController has tableview delegate built in with tableView methods in the controller itself
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        switch search.state { // get current state
        case .notSearchedYet: // if state is set to this, we have done no search
            return 0 // return 0 cells to display
        case .loading: // is .loading return the one loading cell
            return 1
        case .noResults: // no results, return one cell with "Nothing Found" displayed
            return 1
        case .results(let list): // bind results array to temp variable list
            return list.count // get count of the list array (results array)
        }
    }
    
    //func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      //  return 100
   // }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch search.state { // get current state
        case .notSearchedYet:
            fatalError("Should never get here")
        case .loading: // show loading cell
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableView.CellIdentifiers.loadingCell,
                for: indexPath)
            let spinner = cell.viewWithTag(100) as!
            UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        case .noResults: // show nothing found cell
            return tableView.dequeueReusableCell(
                withIdentifier: TableView.CellIdentifiers.nothingFoundCell,
                for: indexPath)
        case .results(let list): // show results cells
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableView.CellIdentifiers.searchResultCell,
                for: indexPath) as! SearchResultCell
            let searchResult = list[indexPath.row]
            cell.configure(for: searchResult)
            return cell
        } }
    
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch search.state { // if row selected, first find state
        case .notSearchedYet, .loading, .noResults:
            return nil
        case .results: // if results (.results only when an item + in array)
            return indexPath // return path of the index
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        loadSoundEffect("key.wav")
        playSoundEffect()
        searchBar.resignFirstResponder()
        if view.window!.rootViewController!.traitCollection
            .horizontalSizeClass == .compact { // iPhone's open pop-up view
            tableView.deselectRow(at: indexPath, animated: true)
            performSegue(withIdentifier: "ShowDetail",
                         sender: indexPath)
        } else {
            if case .results(let list) = search.state {
                // .allVisible applys to landscape, so if not all visible (in portrait, also using iPad) hide the master pane
                if splitViewController!.displayMode != .allVisible {
                    hideMasterPane() // hide the master pane. This is for when your using the iPad and select an item. Then the pane is hidden, and the popup view is shown
                }
                // iPad's set DetailViewController searchresult with correct object
                // basically says, hey splitViewDetail (DetailViewController), I have a reference to you and I am setting your searchResult object with the selected rows cell's object
                splitViewDetail?.searchResult = list[indexPath.row]
            }
        } }
}


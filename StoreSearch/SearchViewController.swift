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
    var searchResults = [SearchResult]() // hold instances of SearchResult (several SearchResult())
    var hasSearched = false // bool to see if we tried a search yet
    var isLoading = false // bool to see if we are in a network search
    //var count : Int = 0
    var dataTask: URLSessionDataTask?
    var soundID: SystemSoundID = 0
    var landscapeVC: LandscapeViewController?


    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.becomeFirstResponder() // open the keyboard right away
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
    
    override func willTransition( // called whenever size change (i.e. horizontal orientaiton mode)
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        switch newCollection.verticalSizeClass {
        case .compact: // if vertical size class is .compact we are transitioning to horizontal
            showLandscape(with: coordinator) // show landscape by calling the method
        case .regular, .unspecified: // if vertical size class is about to be .regular
            hideLandscape(with: coordinator) // then we are going into portrait mode, so hide
        }
    }
    
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
        if segue.identifier == "ShowDetail" { // if segue about to trigger is linked with "ShowDetail" identifier, that means the identifier leads to DetailViewController
            let detailViewController = segue.destination
                as! DetailViewController
            let indexPath = sender as! IndexPath // segue sends along index path of selected row
            let searchResult = searchResults[indexPath.row] //get searchResult object at index path
            detailViewController.searchResult = searchResult // pass searchResult object to DetailView controller. We access searchResult property of DetailView controller with the above line and set it
        }
    }
    // MARK:- Helper Methods
    func iTunesURL(searchText: String, category: Int) -> URL {
        let kind: String
        switch category {
        case 1: kind = "musicTrack"
        case 2: kind = "software"
        case 3: kind = "ebook"
        default: kind = ""
        }
        let encodedText = searchText.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = "https://itunes.apple.com/search?" +
        "term=\(encodedText)&limit=70&entity=\(kind)"
        let url = URL(string: urlString)
        return url! }
    
    func parse(data: Data) -> [SearchResult] { // with retrieved data, parse the retrieved data, return searchresult object
        do {
            let decoder = JSONDecoder()
            // use a JSONDecoder object to convert the response data from the server to a temporary ResultArray object from which you exctract the results property
            let result = try decoder.decode(ResultArray.self, from:data)
            return result.results // with the decoded data, we look at results property and get each result object from the data
        } catch {
            print("JSON Error: \(error)")
            return [] }
    }
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", // obj alert controller that displays msg
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
            controller.searchResults = searchResults // set LandscapeVC with searchResults object
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
            }, completion: { _ in // completion handler after animation is complete
                controller.view.removeFromSuperview() // remove the view from the screen here
                controller.removeFromParent() // dispose of view controller
                self.landscapeVC = nil // remove strong references to landscapeVC
            })
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
    // tells delegate 'Search' button was pressed
    func performSearch() {
        if !searchBar.text!.isEmpty { // if searchBar has text in it when 'Search' clicked
            searchBar.resignFirstResponder() // hide keyboard
            dataTask?.cancel() // cancel active dataTask, thanks to optional chaining if no search has been done yet and dataTask is still nil, cancel() call is ignored
            isLoading = true  // set isLoading to true because we now are going to network search
            tableView.reloadData() // reload the tableView, tableView will be asked to be reloaded
            hasSearched = true
            searchResults = []
            // 1 create url object
            let url = iTunesURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            // 2 get a shared url session instance
            let session = URLSession.shared
            // 3 // create a dataTask for fetching the contents of a url
            dataTask = session.dataTask(with: url,
            // urlsession calls closure on background thread
                completionHandler: { data, response, error in // completion handler is invoked once the data task has response from the server
                    //print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                    
                    if let error = error as NSError?, error.code == -999 {
                      return  // Search was cancelled
                    }
                    else if let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 {
                        if let data = data {
                            self.searchResults = self.parse(data: data) // parse the dictionary contents into SearchResult objects
                            self.searchResults.sort(by: <) // sort a...z
                            DispatchQueue.main.async { // switch back to main thread
                                // ui updating, so isLoading = False,
                                self.isLoading = false
                                self.tableView.reloadData() // reload the tableView
                            }
                            return
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.hasSearched = false
                            self.isLoading = false
                            self.tableView.reloadData() // reload table with nothing in it
                            self.showNetworkError() // show error message
                        }
                        print("Failure! \(response!)")
                    }
            })
            // 5
            dataTask?.resume()
        }
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
        if(isLoading == true) { // if loading is true, we are loading searches
            return 1 // we want to display 1 row with 1 cell that will show the "LoadingCell"
        }
        else if (hasSearched != true) { // if haven't searched, return 0, so no cells created then
            return 0
        }
         else if searchResults.count == 0 { // if zero in searchResults[], then return 1 to put "Nothing"
            return 1
        } else {
            return searchResults.count // return the amount of objects in searchResults[]
        }
    }
    
    //func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      //  return 100
   // }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading { // if loading searches, isLoading is set to true
            let cell = tableView.dequeueReusableCell(withIdentifier: // prepare "LoadingCell"
                TableView.CellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as!
            UIActivityIndicatorView // look at cells tag 100, which is indicatorview
            spinner.startAnimating() // we tell spinner (indicatorview) to start spinning animation
            return cell }
        else if searchResults.count == 0 { // if no results, put cell with text 'Nothing Found' in table
            return tableView.dequeueReusableCell(withIdentifier:
                TableView.CellIdentifiers.nothingFoundCell,
                                                 for: indexPath)
        } else { // otherwise, get the 'SearchResultCell' and set labels in the custom 'SearchResultCell.swift', which will update the SearchResultCell.nib we are displaying in the tableView
            let cell = tableView.dequeueReusableCell(withIdentifier:
                TableView.CellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row] // get array value at indexes 0,1,2..
            cell.configure(for: searchResult)
            return cell
        } }
    func tableView(_ tableView: UITableView, // tableView tells us index of row selected
                   didSelectRowAt indexPath: IndexPath) {
        loadSoundEffect("key.wav")
        playSoundEffect()
        tableView.deselectRow(at: indexPath, animated: true) // deselect the row of that index
        performSegue(withIdentifier: "ShowDetail", sender: indexPath) // when a row is selected, trigger a segue with "ShowDetail" identifier. Send the indexPath along
    }
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading { // if no results or is loading, don't allow row to be selected
            return nil
        } else {
            return indexPath
        }
    }
}


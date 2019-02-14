//
//  ViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/8/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    // weak vars prevented from deallocation by the superview (superview has strong reference)
    @IBOutlet weak var searchBar: UISearchBar! // connects to UISearchBar in storyboard
    @IBOutlet weak var tableView: UITableView!
 
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // segment in storyboard tells this function their linked and for controller to run this method
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    
    // Below: think of as empty array that can contain many SearchResult objects
    var searchResults = [SearchResult]() // hold instances of SearchResult (several SearchResult())
    var hasSearched = false // bool to see if we tried a search yet
    var isLoading = false // bool to see if we are in a network search
    //var count : Int = 0
    var dataTask: URLSessionDataTask?


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
    }
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
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
        "term=\(encodedText)&limit=200&entity=\(kind)"
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
            cell.nameLabel.text = searchResult.name
            if searchResult.artist.isEmpty { // if artist is nil, meaning artistName not set
                cell.artistNameLabel.text = "Unknown"
            } else { // otherwise, set the label with artist + type
                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artist, searchResult.type)
            }
            //print("count \(count)")
            //print("index \(indexPath)")
            //count = count + 1;
            return cell
        } }
    func tableView(_ tableView: UITableView, // tableView tells us index of row selected
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // deselect the row of that index
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


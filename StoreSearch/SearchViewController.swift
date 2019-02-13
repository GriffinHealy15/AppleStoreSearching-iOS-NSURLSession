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
 
    // Below: think of as empty array that can contain many SearchResult objects
    var searchResults = [SearchResult]() // hold instances of SearchResult (several SearchResult())
    var hasSearched = false // bool to see if we tried a search yet
    //var count : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.becomeFirstResponder() // open the keyboard right away
        // tell the tableView to add 20 point margin for status bar + 44 point margin for search bar
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0,
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
    }
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
        }
    }
    // MARK:- Helper Methods
    func iTunesURL(searchText: String) -> URL { // get url
        let encodedText = searchText.addingPercentEncoding( // encode the search text with UTF-8
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: // use encoded text as the itunes url + encoded string
            "https://itunes.apple.com/search?term=%@", encodedText)
        let url = URL(string: urlString)
        return url!
    }
    func performStoreRequest(with url: URL) -> Data? { // perform network search, return data
        do {
            return try Data(contentsOf:url) // get contents of url as a Data format
            //return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Download Error: \(error.localizedDescription)")
            showNetworkError() // when don't have data contents from the url
            return nil
        } }
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
    // tells delegate 'Search' button was pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty { // if searchBar has text in it when 'Search' clicked
            searchBar.resignFirstResponder() // hide keyboard
            hasSearched = true
            searchResults = []
            let url = iTunesURL(searchText: searchBar.text!) // get the itunes.com + /search
            //print("URL: '\(url)'")
            if let data = performStoreRequest(with: url) { // retrieve json data
                searchResults = parse(data: data) // parse the json data, place the returned array into searchResults array which is really [SearchResult]()
                searchResults.sort { $0 < $1 } // searchResults calls sort with overloaded <
            }
            tableView.reloadData()
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
        if (hasSearched != true) { // if haven't searched, return 0, so no cells created then
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
        if searchResults.count == 0 { // if no results, put cell with text 'Nothing Found' in table
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
        if searchResults.count == 0 { // if no results, don't allow row to be selected
            return nil
        } else {
            return indexPath
        }
    }
}


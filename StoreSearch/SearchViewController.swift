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
}

// SearchBarDelegate extension methods
// this (SearchViewController) declares itself a delegate for the search bar
// whenever the search bar is clicked, this controller implements searchBarSearchButtonClicked as to abide to the delegate protocol. The search bar passes the clicked (searched) text to this delegate method
extension SearchViewController: UISearchBarDelegate {
    // tells delegate 'Search' button was pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() //close keyboard when 'Search' clicked
        searchResults = []
        // add a bunch of fake searchResult() objs to searchResults[]
        if searchBar.text! != "justin bieber" {
            
        for i in 0...2 {
            let searchResult = SearchResult() // create a single instance of SearchResult object
            searchResult.name = String(format: "Fake Result %d for", i)
            searchResult.artistName = searchBar.text! // single instance object to add to the array that can contain many SearchResult instances
            searchResults.append(searchResult)
        }
        }
        hasSearched = true // search bar tells us it was clicked, so we set hasSearched = true
        tableView.reloadData()
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
                TableView.CellIdentifiers.searchResultCell,
                                                     for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            cell.artistNameLabel.text = searchResult.artistName
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


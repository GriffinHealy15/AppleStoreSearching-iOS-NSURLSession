//
//  Search.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/22/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit
import Foundation

typealias SearchComplete = (Bool) -> Void // convient name for data type
class Search {
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult])
    }
    private(set) var state: State = .notSearchedYet // (set) means only readable, writable from Search.swift class
    private var dataTask: URLSessionDataTask? = nil
    
    // Everything that has to do with categories lives inside its own enum, Category
    enum Category: Int {
        // looks at index (compares to raw value) selected & gives value (i.e. "all") based on it
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3
        // looks at value and returns a string that is set to type
        var type: String {
            switch self { // switches on self, the current value of the enum object
            case .all: return ""
            case .music: return "musicTrack"
            case .software: return "software"
            case .ebooks: return "ebook"
            }
        }
    }
    
    func performSearch(for text: String, category: Category, completion: @escaping SearchComplete) {
        if  !text.isEmpty { // if searchBar has text in it when 'Search' clicked
            dataTask?.cancel() // cancel active dataTask, thanks to optional chaining if no search has been done yet and dataTask is still nil, cancel() call is ignored
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            state = .loading // state becomes .loading when search just starts
            // 1 create url object
            let url = iTunesURL(searchText: text, category: category)
            // 2 get a shared url session instance
            let session = URLSession.shared
            // 3 // create a dataTask for fetching the contents of a url
            dataTask = session.dataTask(with: url,
                                        // urlsession calls closure on background thread
                completionHandler: { data, response, error in // completion handler is invoked once the data task has response from the server
                    //print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                    var newState = State.notSearchedYet // not searched yet
                    var success = false // no success just yet
                    
                    if let error = error as NSError?, error.code == -999 {
                        return  // Search was cancelled
                    }
                    if let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 {
                        var searchResults = self.parse(data: data!)//parse if get data
                        if searchResults.isEmpty { // if no search results found then
                            newState = .noResults // newState becomes .noResults
                        } else {
                            searchResults.sort(by: <) // else sort
                            newState = .results(searchResults) //newState becomes .results and associates SearchResult objects with it in newState (don't need seperate instance variable to keep track of the array)
                        }
                        success = true
                    }
                    
                    // UIThread runs completion after the search (with success bool)
                    DispatchQueue.main.async {
                        self.state = newState
                        completion(success)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
            })
            // 5
            dataTask?.resume()
        }
    }

    // MARK:- Helper Methods
    private func iTunesURL(searchText: String, category: Category) -> URL {
        
        let locale = Locale.autoupdatingCurrent // users current locale pref's
        let language = locale.identifier // get local language
        let countryCode = locale.regionCode ?? "en_US" // get local country code
        
        let kind = category.type // category type value passed and set for kind
        let encodedText = searchText.addingPercentEncoding( // encoded search text
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = "https://itunes.apple.com/search?" +
            "term=\(encodedText)&limit=200&entity=\(kind)" +
        "&lang=\(language)&country=\(countryCode)"
        let url = URL(string: urlString)
        print("URL: \(url!)")
        return url! }
    
    private func parse(data: Data) -> [SearchResult] { // with retrieved data, parse the retrieved data, return searchresult object
        do {
            let decoder = JSONDecoder()
            // use a JSONDecoder object to convert the response data from the server to a temporary ResultArray object from which you exctract the results property
            let result = try decoder.decode(ResultArray.self, from:data)
            return result.results // with the decoded data, we look at results property and get each result object from the data
        } catch {
            print("JSON Error: \(error)")
            return [] }
    }
}

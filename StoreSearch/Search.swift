//
//  Search.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/22/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import Foundation

typealias SearchComplete = (Bool) -> Void // convient name for data type
class Search {
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    private var dataTask: URLSessionDataTask? = nil
    
    func performSearch(for text: String, category: Int, completion: @escaping SearchComplete) {
        if  !text.isEmpty { // if searchBar has text in it when 'Search' clicked
            dataTask?.cancel() // cancel active dataTask, thanks to optional chaining if no search has been done yet and dataTask is still nil, cancel() call is ignored
            isLoading = true  // set isLoading to true because we now are going to network search
            hasSearched = true
            searchResults = []
            // 1 create url object
            let url = iTunesURL(searchText: text, category: category)
            
            // 2 get a shared url session instance
            let session = URLSession.shared
            // 3 // create a dataTask for fetching the contents of a url
            dataTask = session.dataTask(with: url,
                                        // urlsession calls closure on background thread
                completionHandler: { data, response, error in // completion handler is invoked once the data task has response from the server
                    //print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                    var success = false
                    
                    if let error = error as NSError?, error.code == -999 {
                        return  // Search was cancelled
                    }
                    if let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 {
                        if let data = data {
                            self.searchResults = self.parse(data: data) // parse the dictionary contents into SearchResult objects
                            self.searchResults.sort(by: <) // sort a...z
                            print("Success!")
                            self.isLoading = false
                            success = true
                        }
                    }
                    
                    if (!success) { // if no success, set searched to false & not load
                            self.hasSearched = false
                            self.isLoading = false
                    } // UIThread runs completion after the search (with success bool)
                    DispatchQueue.main.async {
                        completion(success)
                    }
            })
            // 5
            dataTask?.resume()
        }
    }

    // MARK:- Helper Methods
    private func iTunesURL(searchText: String, category: Int) -> URL {
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

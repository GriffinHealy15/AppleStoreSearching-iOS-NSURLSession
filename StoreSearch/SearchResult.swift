//
//  SearchResult.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/8/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import Foundation
// class is a blueprint to hold the SearchResult data we retrieve from the network
// Main idea -> searchResults = [SearchResult]() = [SearchResult(), SearchResult(), ..., n]
// ResultArray is the model object
class ResultArray:Codable { // JSONdecoder decodes in this { } format with two keys
    var resultCount = 0
    var results = [SearchResult]() // place results in here
}
// individual SearchResult object that is parsed and placed into [SearchResult]() array

private let typeForKind = [
    "album": NSLocalizedString("Album",
                               comment: "Localized kind: Album"),
    "audiobook": NSLocalizedString("Audio Book",
                                   comment: "Localized kind: Audio Book"),
    "book": NSLocalizedString("Book",
                              comment: "Localized kind: Book"),
    "ebook": NSLocalizedString("E-Book",
                               comment: "Localized kind: E-Book"),
    "feature-movie": NSLocalizedString("Movie",
                                       comment: "Localized kind: Feature Movie"),
    "music-video": NSLocalizedString("Music Video",
                                     comment: "Localized kind: Music Video"),
    "podcast": NSLocalizedString("Podcast",
                                 comment: "Localized kind: Podcast"),
    "software": NSLocalizedString("App",
                                  comment: "Localized kind: Software"),
    "song": NSLocalizedString("Song",
                              comment: "Localized kind: Song"),
    "tv-episode": NSLocalizedString("TV Episode", comment: "Localized kind: TV Episode"),]


class SearchResult:Codable, CustomStringConvertible { // CustomStringConvertible allows objs to have strings describing the object, or its contents
    var kind: String? = ""
    var artistName: String? = ""
    var trackName: String? = ""
    var name: String {
        return trackName ?? collectionName ?? ""
    }
    var storeURL: String { // if trackViewUrl has a value, populate storeURL = trackViewUrl
        return trackViewUrl ?? collectionViewUrl ?? "" // else, collectionViewUrl
    }
    var price: Double {
        return trackPrice ?? collectionPrice ?? itemPrice ?? 0.0
    }
    var genre: String {
        if let genre = itemGenre {
            return genre
        } else if let genres = bookGenre { // if bookGenre has a value
            return genres.joined(separator: ", ")
        }
        return "" }
    
   
    var type: String { // set the media type
        let kind = self.kind ?? "audiobook"
        return typeForKind[kind] ?? kind
    }
    
    var artist: String {
        return artistName ?? ""
    }
    
    var trackPrice: Double? = 0.0
    var currency = ""
    var imageSmall = ""
    var imageLarge = ""
    
    var trackViewUrl: String?
    var collectionName: String?
    var collectionViewUrl: String?
    var collectionPrice: Double?
    var itemPrice: Double?
    var itemGenre: String?
    var bookGenre: [String]?
   
    enum CodingKeys: String, CodingKey {
        case imageSmall = "artworkUrl60" // imageSmall = (real key) artworkUrl60
        case imageLarge = "artworkUrl100"
        case itemGenre = "primaryGenreName"
        case bookGenre = "genres"
        case itemPrice = "price"
        case kind, artistName, currency
        case trackName, trackPrice, trackViewUrl
        case collectionName, collectionViewUrl, collectionPrice
    }
    
    var description: String { // for conforming to CustomStringConvertible
        return "\nKind: \(kind ?? "None"), Name: \(name), Artist Name: \(artist)\n"
    }
}
// compares first array index value and second, so on. If A < B, return true. Sorts ascending order
func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
}


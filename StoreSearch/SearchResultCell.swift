//
//  SearchResultCell.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/11/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    var downloadTask: URLSessionDownloadTask?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedView = UIView(frame: CGRect.zero) // get the view
        selectedView.backgroundColor = UIColor(red: 20/255, // set the view background color
                                               green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // if a cell is being reusesd, this is automatically called, and we cancel the image download
    override func prepareForReuse() {
        super.prepareForReuse()
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    // MARK:- Public Methods
    func configure(for result: SearchResult) {
        nameLabel.text = result.name
        if result.artist.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = String(format: "%@ (%@)", result.artist, result.type)
            artworkImageView.image = UIImage(named: "Placeholder")
            if let smallURL = URL(string: result.imageSmall) {
                downloadTask = artworkImageView.loadImage(url: smallURL)
            }
        } }
}

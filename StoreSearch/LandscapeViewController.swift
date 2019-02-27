//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 2/19/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit

// landscape
class LandscapeViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView! // outlet to scrollView
    @IBOutlet weak var pageControl: UIPageControl! // outlet to pageControl
    var search: Search! // array of SearchResult objects
    private var firstTime = true
    private var downloads = [URLSessionDownloadTask]() // keep track of download tasks
    
    deinit {
        print("deinit \(self)")
        for task in downloads { // cancel any tasks in downloads, remember we added a task in downloadImage
            task.cancel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Remove constraints from main view
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true // allows to position views manually by changing their frame property
        view.backgroundColor = UIColor(patternImage:
            UIImage(named: "LandscapeBackground")!)
        // Remove constraints for page control
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        // Remove constraints for scroll view
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        pageControl.numberOfPages = 0 // hide page controller initially when no searches
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        scrollView.frame = safeFrame
        //scrollView.backgroundColor = UIColor.blue
        pageControl.frame = CGRect(x: safeFrame.origin.x,
                                   y: safeFrame.size.height - pageControl.frame.size.height,
                                   width: safeFrame.size.width,
                                   height: pageControl.frame.size.height)
        if firstTime {
            firstTime = false // set to false, as it won't be first time next time
            switch search.state { // get current state, case depending on state
            case .notSearchedYet:
                break
            case .loading:
                showSpinner() // show spinner
            case .noResults:
                showNothingFoundLabel() // show "Nothing Found" label
            case .results(let list): // if we got .results, set tiles up for all list
                tileButtons(list)
            }
        }
    }
    
    // MARK:- Actions
    // pageControll informs this function it was tapped
    @IBAction func pageChanged(_ sender: UIPageControl) { // get page tapped (current page)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations:
            { self.scrollView.contentOffset = CGPoint( // animate scrollview moving
            // set x to width * currentPage (i.e. 768 * 2 = 1536)
            x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0) }, completion: nil)
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowDetail", sender: sender)
    }
    
    // MARK:- Public Methods
    // this is invoked in SearchViewController incase closure executes and were already rotated to landscape, tell landscape search results are available
    func searchResultsReceived() {
        hideSpinner() // call hideSpinner
        switch search.state { // get search object and states, .results contains objs
        case .notSearchedYet, .loading:
            break
        case .noResults:
            showNothingFoundLabel()
        case .results(let list): // after tableView is reloaded in SearchController, we call this method to let LandscapeViewController set up its tile view
            tileButtons(list) // set up tiles
        }
    }
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.center = CGPoint(x: scrollView.bounds.midX + 0.5,
                                 y: scrollView.bounds.midY + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    private func hideSpinner() {
        view.viewWithTag(1000)?.removeFromSuperview() // find this view, and remove
    }
    
    private func showNothingFoundLabel() {
        let label = UILabel(frame: CGRect.zero) // create label
        label.text = "Nothing Found" // give text, color, background color
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.clear
        label.sizeToFit() // resize label to optimal size
        var rect = label.frame // get rect of label frame
        rect.size.width = ceil(rect.size.width/2) * 2 //to get even # when positioning
        rect.size.height = ceil(rect.size.height/2) * 2  // make even
        label.frame = rect // re-frame label with even bounds
        label.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
                               view.addSubview(label)
    }
    
    // MARK:- Private Methods
    private func tileButtons(_ searchResults: [SearchResult]) { // pass search results
        var columnsPerPage = 6
        var rowsPerPage = 3
        var itemWidth: CGFloat = 94
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 2
        var marginY: CGFloat = 20
        // Button size
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        let viewWidth = scrollView.bounds.size.width
        switch viewWidth {
        case 568:
            // 4-inch device
            break
        case 667:
            // 4.7-inch device
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            // 5.5-inch device
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
            marginX = 0
        case 724:
            // iPhone X
            columnsPerPage = 8
            rowsPerPage = 3
            itemWidth = 90
            itemHeight = 98
            marginX = 2
            marginY = 29
        default:
            break
        }
        // Add the buttons
        var row = 0
        var column = 0
        var x = marginX
        // contains next index, and the result object
        for (index, result) in searchResults.enumerated() { // loop through all indexes and creates button for them
            // 1
            let button = UIButton(type: .custom) // create button
            button.tag = 2000 + index // give it a tag with index (so to know to the SearchResult object to pass to the pop-up, then the right item, song, etc. displays)
            button.addTarget(self, action: #selector(buttonPressed),
                        for: .touchUpInside)//button calls buttonPressed when tapped
            downloadImage(for: result, andPlaceOn: button) // set buttons background image
            // 2 set frame for the button
            button.frame = CGRect(x: x + paddingHorz,
                                  y: marginY + CGFloat(row)*itemHeight + paddingVert,
                                  width: buttonWidth, height: buttonHeight)
            //print("Button frame \(button.frame)\n")
            // 3
            scrollView.addSubview(button) // add button to scrollView as its subview
            // 4
            row += 1 // each loop, increase rows + 1 to move y down (to create next button below)
            if row == rowsPerPage { // when at row 3, and max is 3
                row = 0; x += itemWidth; column += 1 // set row to 0, but move to column 1
                if column == columnsPerPage { // when gone through all columns, were finished
                    column = 0
                    x += marginX * 2 // add leftover space to x
                }
            } }
        
        // Set scroll view content size
        let buttonsPerPage = columnsPerPage * rowsPerPage
        // i.e (1 + (SearchResult.count of 18 - 1)) / 18 = 1, so we need only one page
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage // calculate # of pages needed
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages) * viewWidth, // iPhoneX scroll view is 768 points, multiplied by i.e 9 pages, we get 6,912 points, we want to scroll through that many points
            height: scrollView.bounds.size.height)
        print("Number of pages: \(numPages)")
        pageControl.numberOfPages = numPages // set page to numPages found
        pageControl.currentPage = 0
    }
    
    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if segue.identifier == "ShowDetail" { // if segue triggered has this identfier
            if case .results(let list) = search.state { // and state has .results
                let detailViewController = segue.destination // set dest as detailview
                    as! DetailViewController
                // if button selected tag is 2007, we say 2007-2000 = 7, and that is the 7th index, where it stored the 7th object
                let searchResult = list[(sender as! UIButton).tag - 2000] // get the list object at index of the button - 2000
                detailViewController.searchResult = searchResult // set searchResult with the object at selected index
            }
        } }
    
    private func downloadImage(for searchResult: SearchResult,
                               andPlaceOn button: UIButton) {
        if let url = URL(string: searchResult.imageSmall) { // url instance with link to image
            let task = URLSession.shared.downloadTask(with: url) { // task to download image
                [weak button] url, response, error in // weak button incase deallocat
                if error == nil, let url = url,
                    let data = try? Data(contentsOf: url), // get data of image saved to disk
                    let image = UIImage(data: data) { // put data into a uIImage
                    DispatchQueue.main.async { // main queue
                        if let button = button {
                            button.setImage(image, for: .normal) // place image as buttons image
                        }
                    } }
            }
            task.resume()
            downloads.append(task) // add task to downloads (list of download objs)
        }
    }
}

// extension to declare LandscapeViewController a delegate to UIScrollView
extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        // i.e. starts at point 364, when scroll 364 more points (were half way in current page)
        let page = Int((scrollView.contentOffset.x + width / 2) / width) // when content offset is halfway or more on the page it's on, it moves to next page
            pageControl.currentPage = page // tell pageControl of current page continuously
    }
}

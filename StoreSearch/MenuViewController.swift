//
//  MenuViewController.swift
//  StoreSearch
//
//  Created by Griffin Healy on 3/4/19.
//  Copyright © 2019 Griffin Healy. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {
    
    weak var delegate: MenuViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK:- Table View Delegates
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // if tableView selected at row 0, tell our delegate (the DetailViewController) to run the menuViewControllerSendEmail method it implemented through our protocol method (shown below)
        if indexPath.row == 0 {
            delegate?.menuViewControllerSendEmail(self)
        }
    }
    
}

protocol MenuViewControllerDelegate: class {
    func menuViewControllerSendEmail(_ controller: MenuViewController)
}


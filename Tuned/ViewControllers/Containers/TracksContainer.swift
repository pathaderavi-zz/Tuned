//
//  TracksContainer.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

class TracksContainer:UIViewController, UITableViewDataSource, UITableViewDelegate{
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noTracksFoundLabel: UILabel!
    @IBOutlet weak var tableVIew: UITableView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if allTracks.count == 0 {
            noTracksFoundLabel.alpha = 1
            self.tableVIew.alpha = 0
            self.noTracksFoundLabel.text = "No Tracks Found"
        }else{
            noTracksFoundLabel.alpha = 0
            self.tableVIew.alpha = 1
            self.noTracksFoundLabel.text = ""
        }
        self.loadingIndicator.stopAnimating()
        return allTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableVIew.dequeueReusableCell(withIdentifier: "cellTracks") as! UITableViewCell
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = allTracks[indexPath.row]
        print(allTracks[indexPath.row])
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    
    var allTracks = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableVIew.delegate = self
        tableVIew.dataSource = self
        tableVIew.tableFooterView = UIView()
        tableVIew.bounces = false
        tableVIew.indicatorStyle = .white
        tableVIew.reloadData()
    }
    
}

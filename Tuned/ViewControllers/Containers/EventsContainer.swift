//
//  EventsContainer.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

class EventsContainer:UIViewController,UITableViewDelegate,UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let key = Array(allEvents.keys)[indexPath.row]
        let values = Array(allEvents.values)[indexPath.row]
        if values == true {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "sub")
            cell.backgroundColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.red
            cell.detailTextLabel?.text = "Cancelled"
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "eventsCell") as! UITableViewCell
        }
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = key
        cell.detailTextLabel?.removeFromSuperview()
     
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    var allEvents = [String:Bool]()
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.indicatorStyle = .white
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }
}

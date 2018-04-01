//
//  TracksContainer.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
//UITableViewDelegate,UITableViewDataSource
class TracksContainer:UIViewController, UITableViewDataSource, UITableViewDelegate{
    @IBOutlet weak var tableVIew: UITableView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTracks.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        return
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableVIew.dequeueReusableCell(withIdentifier: "cellTracks") as! UITableViewCell
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = allTracks[indexPath.row]
        print(allTracks[indexPath.row])
        return cell
    }
    
    
    var allTracks = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableVIew.delegate = self
        tableVIew.dataSource = self
//        tableVIew.rowHeight = 28
//        tableVIew.tableFooterView = UIView()
        tableVIew.bounces = false
        tableVIew.indicatorStyle = .white
        tableVIew.reloadData()
    }

}

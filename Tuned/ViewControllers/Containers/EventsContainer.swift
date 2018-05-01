//
//  EventsContainer.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class EventsContainer:UIViewController,UITableViewDelegate,UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noEventsFoundLabel: UILabel!
    var allSongKickEvents : [[String:AnyObject]]!
    let eventStore = EKEventStore()
    var calendarEvents : [String:Date]!
    var calendarEventsName = [String]()
    var calendarEventsDate = [Date]()
    var parentController: ArtistDetailViewController!
    var delegateContainer:CustomViewContainerDelegate!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tableView != nil{
            tableView.reloadData()
        }
    }
    func enableLabels() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            if self.allSongKickEvents != nil {
                if self.allSongKickEvents.count != 0 {
                    self.noEventsFoundLabel.alpha = 0
                    self.tableView.alpha = 1
                    self.noEventsFoundLabel.text = ""
                }else{
                    self.noEventsFoundLabel.alpha = 1
                    self.tableView.alpha = 0
                    self.noEventsFoundLabel.text = "No Events Found"
                }
            }else {
                self.noEventsFoundLabel.alpha = 1
                self.tableView.alpha = 0
                self.noEventsFoundLabel.text = "No Events Found"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if allSongKickEvents != nil {
            if allSongKickEvents.count == 0 {
                return 0
            }else{
                return allSongKickEvents.count
                
            }
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "eventsCell") as! EventsCell
        cell.calendarButton.imageView?.image = #imageLiteral(resourceName: "calendar_add")
        cell.delegateTap = self
        let eventLocation = allSongKickEvents[indexPath.row]["location"] as? String
        //cell.selectionStyle = UITableViewCellSelectionStyle.none
        let eventDate = allSongKickEvents[indexPath.row]["date"] as? Date
        
        if let checkDate = calendarEvents[eventLocation!] as? Date {
            if checkDate == eventDate{
                cell.calendarButton.imageView?.image = #imageLiteral(resourceName: "calendar_tick")
                cell.eventPresent = true
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd,yyyy"
        let dateS = dateFormatter.string(from: eventDate!)
        
        cell.subTitle.text = dateS
        cell.parentController = self
        cell.eventNameLabel.text =  eventLocation!
        cell.currentEvent = allSongKickEvents[indexPath.row]
        return cell
        
    }
    var allEvents = [String:Bool]()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    fileprivate func loadTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.tableFooterView = UIView()
        
        let calendar = eventStore.calendars(for: .event)
        DispatchQueue.global(qos: .userInitiated).async {
            self.calendarEvents = [String:Date]()
            for c in calendar{
                let endDate = Date(timeIntervalSinceNow: 60*60*24*365*2*2)
                let eventPredicate = self.eventStore.predicateForEvents(withStart: Date() - (60*60*24), end: endDate, calendars: [c])
                let events = self.eventStore.events(matching: eventPredicate)
                for e in events{
                    if let eventNotes = e.notes {
                        if  eventNotes == "Tunies / SongKick" { //Error
                            self.calendarEvents[e.title] = e.startDate
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.indicatorStyle = .white
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTable()
    }
    
    
}
protocol CustomViewContainerDelegate: class {
    func openUrl(string:String)
}

extension EventsContainer: CustomCellDelegate {
    func sharePressed(cell: EventsCell,string:String) {
        delegateContainer.openUrl(string: string)
    }
}

//
//  EventsCell.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 4/16/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class EventsCell:UITableViewCell{
    
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var bookOnlineButton: UIButton!
    var parentController:EventsContainer!
    var currentEvent = [String:AnyObject]()
    var delegate: UIViewController?
    var eventPresent:Bool = false
    var delegateTap: CustomCellDelegate?
    var delegateEvent: EventPress?
    @IBAction func bookOnlineTapped(_ sender: Any) {
        let url = currentEvent["uri"] as? String
        delegateTap?.sharePressed(cell: self,string:url!)
        
    }
    @IBOutlet weak var subTitle: UILabel!
    @IBAction func calendarButtonTapped(_ sender: Any) {
        
        let status = EKEventStore.authorizationStatus(for: .event) == EKAuthorizationStatus.authorized
        
        if status {
            let eventStore = EKEventStore()
            let eDate = currentEvent["date"] as? Date
            let eLocation = currentEvent["location"] as? String
            let event:EKEvent = EKEvent(eventStore: eventStore)
            event.title = currentEvent["location"] as? String
            event.startDate = currentEvent["date"] as? Date
            event.endDate = currentEvent["date"] as? Date
            event.notes = "Tunies / SongKick"
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            if !eventPresent {
                do {
                    try eventStore.save(event, span: .thisEvent)
                    DispatchQueue.main.async {
                        self.calendarButton.imageView?.image = nil
                        self.calendarButton.imageView?.image = #imageLiteral(resourceName: "calendar_tick")
                        self.eventPresent = true
                    }
                    parentController.calendarEvents[eLocation!] = eDate!
                    //Event Has Been Added Alert
                    showAlert(title: "Event Added", message: "Event has been added to your calendar.")
                }catch let e {
                    print(e.localizedDescription)
                }
            }else{
                let calendar = eventStore.calendars(for: .event)
                let endDate = Date(timeIntervalSinceNow: 60*60*24*365*2*2)
                var eventToDelete = EKEvent(eventStore: eventStore)
                DispatchQueue.global(qos: .userInitiated).async {
                    for c in calendar{
                        let eventPredicate = eventStore.predicateForEvents(withStart: Date() - (60*60*24), end: endDate, calendars: [c])
                        let events = eventStore.events(matching: eventPredicate)
                        for e in events{
                            if e.startDate == eDate { // Add More conditions
                                eventToDelete = e
                                continue
                            }
                        }
                    }
                    do {
                        try eventStore.remove(eventToDelete, span: .thisEvent, commit:true)
                        self.parentController.calendarEvents.removeValue(forKey: eLocation!)
                        self.showAlert(title: "Event Removed", message: "Event has been removed from your calendar.")
                        DispatchQueue.main.async {
                            self.calendarButton.imageView?.image = nil
                            self.calendarButton.imageView?.image = #imageLiteral(resourceName: "calendar_add")
                            self.eventPresent = false
                        }
                    }catch let e {
                        print(e.localizedDescription)
                    }
                }
                
                
                
            }
        }else{
            // Please Grant Access to add event to the calendar
            delegateEvent?.eventPressed(cell:self)
        }
        
        
    }
    
    func showAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        //present(alert, animated: true, completion: nil)
    }
    
    
}
protocol CustomCellDelegate: class {
    func sharePressed(cell: EventsCell,string:String)
}

protocol EventPress: class{
    func eventPressed(cell: EventsCell)
}

//
//  EventsMapViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 4/25/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import EventKit

class EventsMapViewController: UIViewController, MKMapViewDelegate{
    var allSongKickEvents = [[String:AnyObject]]()
    @IBOutlet weak var mapView: MKMapView!
    var artistName:String!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var previousController:ArtistDetailViewController!
    var buttonArray = [UIButton]()
    var allTunies = [EKEvent]()
    let eventStore = EKEventStore()
    
    
    fileprivate func fetchTuniesEvens() {
        let calendar = eventStore.calendars(for: .event)
        allTunies = [EKEvent]()
        for c in calendar{
            let endDate = Date(timeIntervalSinceNow: 60*60*24*365*2*2)
            let eventPredicate = eventStore.predicateForEvents(withStart: Date() - (60*60*24), end: endDate, calendars: [c])
            let events = eventStore.events(matching: eventPredicate)
            for e in events{
                if  e.notes == "Tunies / SongKick" {
                    self.allTunies.append(e)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTuniesEvens()
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.mapView.delegate = self
                self.mapView.removeAnnotations(self.mapView.annotations)
                var annotations = [MKPointAnnotation]()
                for events in self.allSongKickEvents {
                    let lat = events["lat"] as? Double
                    let lng = events["lng"] as? Double
                    let eventDate = events["date"] as? Date
                    let subtitleString = events["venue"] as? String
                    let eventName = events["location"] as? String
                    if (lat == nil) || (lng == nil) {
                        continue
                    }
                    let dateFormatterLabel = DateFormatter()
                    dateFormatterLabel.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    let rawDateString = dateFormatterLabel.string(from: eventDate!)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM dd,yyyy"
                    let dateS = dateFormatter.string(from: eventDate!)
                    let coordinate = CLLocationCoordinate2D(latitude:CLLocationDegrees(lat!),longitude:CLLocationDegrees(lng!))
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = events["location"] as? String
                    annotation.subtitle = "(" + dateS + ")  " + (events["venue"] as? String)!
                    let buttonAnnot = UIButton(frame: CGRect.init(x: 0, y: 0, width: 32, height: 32))
                    buttonAnnot.restorationIdentifier = rawDateString + "|" + eventName! + "|" + subtitleString!
                    self.buttonArray.append(buttonAnnot)
                    annotations.append(annotation)
                }
                self.mapView.addAnnotations(annotations)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    self.loadingIndicator.stopAnimating()
                })
            }
        }
        // DispatchQueue.global(qos: .userInitiated).async {
        //Zoom to user location 
        //        let noLocation = CLLocationCoordinate2D()
        //        let viewRegion = MKCoordinateRegionMakeWithDistance(noLocation, 0, 0)
        //        mapView.setRegion(viewRegion, animated: false)
        //self.mapView.showsUserLocation = true
        
        //loadingIndicator.stopAnimating()
        // }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reusedPin = "eventPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusedPin) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedPin)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = false
        }else{
            pinView?.annotation = annotation
        }
  
        let t:String = ((pinView?.annotation?.title)!)!
        var calendarB = UIButton()
        var dataArray = [Substring]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "yyyy-MM-dd HH:mm:ss Z"
        var completeDate:Date!
        var completeTitle:String!
        
        for b in self.buttonArray {
            if ((b.restorationIdentifier?.range(of: t)) != nil) {
                let rId = b.restorationIdentifier!
                dataArray = rId.split(separator: "|")
                completeTitle = String(dataArray[1])
                if completeTitle == pinView?.annotation?.title{
                    calendarB = b
                    completeDate = dateFormatter.date(from: String(dataArray[0]))
                    break
                }
            }
        }
        
        pinView!.rightCalloutAccessoryView = calendarB
        calendarB.addTarget(self, action: #selector(action(sender:)), for: .touchUpInside)
        
        calendarB.setBackgroundImage(#imageLiteral(resourceName: "calendar_black"), for: .normal)


        for e in allTunies{
            if  e.notes == "Tunies / SongKick" && e.startDate == completeDate && completeTitle == e.title{ //try to add artistname for better comparison
                DispatchQueue.main.async {
                    calendarB.setBackgroundImage(#imageLiteral(resourceName: "calendar_tick"), for: .normal)
                }
            }
        }
        
        //might have to modify this
        return pinView
    }
    
    var boolPin:Bool = false

    @objc fileprivate func action(sender: UIButton) {
        let pTest = sender.restorationIdentifier
        eventStore.requestAccess(to: .event) { (success, error) in
        }
        let arr = pTest?.split(separator: "|")
        let allMapAnnotations = mapView.annotations
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        var eventDate:Date!
        var eventName:String!

        for event in allSongKickEvents {
            let eDate = event["date"] as? Date
            let dateS = dateFormatter.date(from: String(arr![0]))
            let eventLoc = event["location"] as? String
            let eventVenue = event["venue"] as? String
            let annotSub = String(arr![2])

            if dateS == eDate &&  annotSub == eventVenue {
                eventDate = eDate
                eventName = eventLoc
                break
            }
        }

        let status = EKEventStore.authorizationStatus(for: .event) == EKAuthorizationStatus.authorized

        let event:EKEvent = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        if sender.currentBackgroundImage == #imageLiteral(resourceName: "calendar_black") {
            if status{
                sender.setBackgroundImage(#imageLiteral(resourceName: "calendar_tick"), for: .normal)
                event.notes = "Tunies / SongKick"
                event.startDate = eventDate
                event.endDate = eventDate
                event.title = eventName
                do {
                    try eventStore.save(event, span: .thisEvent,commit:true)
                    DispatchQueue.main.async {
                        self.showAlert(title: "Event Added", message: "Event has been added to your calendar.")
                    }
                }catch let e {
                    print(e.localizedDescription)
                }
            }else{
                //request calendar access
                self.showAlertForAccess()
            }

            for annot in allMapAnnotations {
                if annot.title == eventName {
                    fetchTuniesEvens()
                    mapView.removeAnnotation(annot)
                    mapView.addAnnotation(annot)
                }
            }
        }else{
            if status {
                sender.setBackgroundImage(#imageLiteral(resourceName: "calendar_black"), for: .normal)
                fetchTuniesEvens()
                var eventToDelete = EKEvent(eventStore: eventStore)
                for ev in allTunies {
                    if ev.startDate == eventDate {
                        eventToDelete = ev
                        break
                    }
                }
                do {
                    try eventStore.remove(eventToDelete, span: .thisEvent, commit:true)
                    DispatchQueue.main.async {
                        self.showAlert(title: "Event Removed", message: "Event has been removed from your calendar.")
                    }
                }catch let e {
                    print(e.localizedDescription)
                }
                for annot in allMapAnnotations {
                    if annot.title == eventName {
                        fetchTuniesEvens()
                        mapView.removeAnnotation(annot)
                        mapView.addAnnotation(annot)
                    }
                }
            }else{
                //request access
                self.showAlertForAccess()
            }
        }
    }
    var removePin = false
    func showAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    func showAlertForAccess(){
        let alertController = UIAlertController (title: "Need Calendar Access", message: "The App needs access to calendar to add events.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previousController.allSongKickEvents = allSongKickEvents
    }
}



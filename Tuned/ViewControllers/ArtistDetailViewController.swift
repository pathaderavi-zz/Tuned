//
//  ArtistDetailViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/28/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//
// TODO Border

import Foundation
import UIKit
import CoreData
import EventKit

class ArtistDetailViewController: UIViewController,UIScrollViewDelegate,NSFetchedResultsControllerDelegate{
    var artistName:String!
    var imageData:Data!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var eventsContainer: UIView!
    @IBOutlet weak var onTour: UILabel!
    var dataController:DataController!
    var currentArtist:Artist!
    @IBOutlet weak var c2: UIView! // bioContainer
    @IBOutlet weak var c1: UIView! // tracksContainer
    var tracksController:TracksContainer!
    var eventsController:EventsContainer!
    var allSocialHandles = [String:AnyObject]()
    @IBOutlet weak var youtubeButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var activeContainer:Int = 1
    var mbidStatus:Bool = false
    var artistUrlFromMain:String!
    var allSongKickEvents = [[String:AnyObject]]()
    let eventStore = EKEventStore()
    //CoreData variables
    var artist:Artists!
    var events:Events!
    var tracks:Tracks!
    var socials:Socials!
    @IBOutlet weak var eventsMapButton: UIBarButtonItem!
    var fetchedResultController:NSFetchedResultsController<Artists>!
    var fetchTracks = [String]()
    var fetchEvents = [String:Bool]()
    var fetchedEventsController:NSFetchedResultsController<Events>!
    var fetchedTracksController:NSFetchedResultsController<Tracks>!
    var fetchedSocialsController:NSFetchedResultsController<Socials>!
    var borderBool:Bool = false
    var eventUrl:String!
    


    @IBAction func eventsMapButton(_ sender: Any) {
        performSegue(withIdentifier: "eventsMap", sender: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        fetchedResultController = nil
        super.viewDidDisappear(animated)
    }
    fileprivate func fetchArtist() {
        let fetchRequest:NSFetchRequest<Artists> = Artists.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchRequest.predicate = NSPredicate(format:"(name == %@)",artistName)
        // try? dataController.viewContext.fetch(fetchRequest)
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
            if fetchedResultController.fetchedObjects?.count != 0 {
                artist = fetchedResultController.fetchedObjects![0]
                fetchSocials()
                fetchAllTracks()
                fetchAllEvents()
            }
        }catch{
            fatalError("Cannot Fetch")
        }
    }

    override func viewDidLayoutSubviews() {
        if !borderBool{
            activateBorder(button: bioButton)
            borderBool = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchArtist()
        setupFavButton()
        disableButtons()
      
        tracksController = self.storyboard!.instantiateViewController(withIdentifier: "tracksContainer") as! TracksContainer
        eventsController = self.storyboard?.instantiateViewController(withIdentifier: "eventsContainer") as! EventsContainer
        eventsController.delegateContainer = self
//        if(UIDevice.current.orientation == .portrait  || UIDevice.current.orientation == .portraitUpsideDown || (UIDevice.current.orientation == .faceUp)){
//            imageView.contentMode = .scaleAspectFit
//        }else{
//            imageView.contentMode = .scaleAspectFill
//        }
        
        scrollView.bounces = false
        scrollView.delegate = self
        self.navigationItem.title = artistName
        self.onTour.isHidden = true
        onTour.layer.cornerRadius = onTour.frame.width/2
        onTour.layer.masksToBounds = true
        
        let updatedName = artistName.replacingOccurrences(of: " " , with: "+")
        imageView.image = UIImage(data:imageData)
        imageFit()
        if fetchedResultController.fetchedObjects?.count != 0 {
            if let result = fetchedResultController.fetchedObjects?[0] {
                currentArtist = Artist(dictionary: [String:AnyObject].init())
                currentArtist.bioContent = result.bio!
                currentArtist.name = result.name!
                currentArtist.mbid = result.mbid!
                currentArtist.onTour = result.ontour!
                mbidStatus = (currentArtist.mbid == "")
                let controller = self.storyboard!.instantiateViewController(withIdentifier: "bioContainer") as! BioContainer
                if result.ontour == "0"{
                    self.onTour.isHidden = true
                }else{
                    self.onTour.isHidden = false
                }
                controller.bioLabelText = currentArtist.bioContent
                controller.lastFmUrl = NSMutableAttributedString(string:result.bio!)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.c2.addSubview(controller.view)
                }
                
            }
            loadingIndicator.stopAnimating()
            enableButtons()
        }
        else{
            //  DispatchQueue.global(qos:.userInitiated).async {
            //                artistDataDownload(artist: updatedName, completionHadler: { (success,artist,noneFound) in
            //                    if success{
            //                        self.currentArtist = artist
            self.mbidStatus = (self.currentArtist.mbid == "")
            DispatchQueue.main.async {
                let controller = self.storyboard!.instantiateViewController(withIdentifier: "bioContainer") as! BioContainer
                if self.currentArtist.onTour == "0"{
                    self.onTour.isHidden = true
                }else{
                    self.onTour.isHidden = false
                }
                controller.bioLabelText = self.currentArtist.bioContent
                controller.lastFmUrl = NSMutableAttributedString(string:self.currentArtist.bioContent)
                self.c2.addSubview(controller.view)
            }
            
            getTopTracks(artistName: self.artistName, completionHandler: { (success, result) in
                if success {
                    self.fetchTracks = result
                }else{
                    DispatchQueue.main.async {
                        self.showAlert(title: "No Internet Connection", message: "Error Downloading Data. Please Try Again.")
                    }
                    
                }
            })
            getSongKickEvents(mbid: self.currentArtist.mbid, name: self.currentArtist.name, completionHandler: {success,result in
                if success{
                        self.allSongKickEvents = result
                        //Add to datacontroller and save
                }else{
                    DispatchQueue.main.async {
                        self.showAlert(title: "No Internet Connection", message: "Error Downloading Data. Please Try Again.")
                    }
                }
                DispatchQueue.main.async {
                    self.enableButtons()
                }
            })
            getSocialHandles(mbid: currentArtist.mbid) { (success, result, error) in
                if success{
                    
                    self.allSocialHandles = result
               
                }
                if error {
                    self.showAlert(title: "No Internet Connection", message: "Unable to Connect to the Internet. Please try again.")
                }else{
                    DispatchQueue.main.async {
                        self.enableButtons()
                    }
                }
                
                
            }
            //                    }
            //                })
            
            // }
        }
        self.setupContaiers()
        activateBorder(button: bioButton)
    }
    @IBAction func youtubeButtonClicked(_ sender: Any) {
        
        if let youtubeUrl = allSocialHandles["youtube"] as? String{
            var appUrl:String
            if (youtubeUrl.range(of: "https") != nil){
                appUrl = youtubeUrl.replacingOccurrences(of: "https", with: "youtube")
            }else{
                appUrl = youtubeUrl.replacingOccurrences(of: "http", with: "youtube")
            }
            if UIApplication.shared.canOpenURL(URL(string:appUrl)!){
                UIApplication.shared.open(URL(string:appUrl)!, options: [:], completionHandler: { (success) in
                    
                })
            }else{
                UIApplication.shared.open(URL(string:youtubeUrl)!, options: [:], completionHandler: { (success) in
                    
                })         }
            
        }    }
    @IBAction func twitterButtonClicked(_ sender: Any) {
        if let url = allSocialHandles["twitter"] as? String {
            var appUrl:String
            
            if (url.range(of: "https") != nil){
                appUrl = url.replacingOccurrences(of: "https", with: "twitter")
            }else{
                appUrl = url.replacingOccurrences(of: "http", with: "twitter")
            }
            
            if (appUrl.range(of: "www.twitter.com") != nil) {
                appUrl = appUrl.replacingOccurrences(of: "www.twitter.com/", with: "user?screen_name=")
            }else{
                appUrl = appUrl.replacingOccurrences(of: "twitter.com/", with: "user?screen_name=")
            }
            if appUrl.last == "/"{
                appUrl.removeLast()
            }
            if UIApplication.shared.canOpenURL(URL(string:appUrl)!){
                UIApplication.shared.open(URL(string:appUrl)!, options: [:], completionHandler: { (success) in
                    
                })
            }else{
                UIApplication.shared.open(URL(string:url)!, options: [:], completionHandler: { (success) in
                    
                })
                
            }
        }else{
            //Show alert
        }
    }
    @IBAction func instagramButtonClicked(_ sender: Any) {
        if let url = allSocialHandles["instagram"] as? String {
            var appUrl:String
            
            if (url.range(of: "https") != nil){
                appUrl = url.replacingOccurrences(of: "https", with: "instagram")
            }else{
                appUrl = url.replacingOccurrences(of: "http", with: "instagram")
            }
            
            if (appUrl.range(of: "www.instagram.com") != nil) {
                appUrl = appUrl.replacingOccurrences(of: "www.instagram.com/", with: "user?username=")
            }else{
                appUrl = appUrl.replacingOccurrences(of: "instagram.com/", with: "user?username=")
            }
            if appUrl.last == "/"{
                appUrl.removeLast()
            }
            if UIApplication.shared.canOpenURL(URL(string:appUrl)!){
                UIApplication.shared.open(URL(string:appUrl)!, options: [:], completionHandler: { (success) in
                    
                })
            }else{
                UIApplication.shared.open(URL(string:url)!, options: [:], completionHandler: { (success) in
                    
                })
                
            }
        }else{
            //Show alert
        }
        
    }
    @IBAction func facebookButtonClicked(_ sender: Any) {
        if let facebookUrl = allSocialHandles["facebook"] as? String {
            UIApplication.shared.open(URL(string:facebookUrl)!, options: [:], completionHandler: { (success) in
                
            })
            
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let verticalIndicator = scrollView.subviews.last as? UIImageView
        verticalIndicator?.backgroundColor = UIColor.gray
    }
    
    @objc func imageFit(){
        let iPad = ( UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .unspecified)
        if activeContainer == 1 {
            activateBorder(button: bioButton)
        }else if activeContainer == 2 {
            activateBorder(button: tracksButton)
        }else {
            activateBorder(button: eventsButton)
        }
        if iPad {
              imageView.contentMode = UIViewContentMode.scaleAspectFit
        }
        else {
        if (view.frame.height > view.frame.width) {
            imageView.contentMode = UIViewContentMode.scaleAspectFill
        }else{
            imageView.contentMode = UIViewContentMode.scaleAspectFit
        }
        }
        
    }
    
    @IBOutlet weak var eventsButton: UIButton!
    @IBOutlet weak var tracksButton: UIButton!
    @IBOutlet weak var bioButton: UIButton!
    @IBOutlet weak var yelloFav: UIButton!
    @IBOutlet weak var favButton: UIButton!
    let border = CALayer()
    var rotateBool:Bool = true
    fileprivate func activateBorder(button:UIButton) {
        if let count = (button.layer.sublayers?.count) {
            if count > 1{
                // return
            }
        }
        if rotateBool{
        let appearAnimation = CABasicAnimation(keyPath: "opacity")
        appearAnimation.fromValue = 0
        appearAnimation.toValue = button.frame.size.width
        appearAnimation.duration = 10
        button.layer.add(appearAnimation, forKey: "opacity")
            rotateBool = false
        }
        self.border.frame = CGRect(x: 0, y: button.frame.origin.y + button.frame.height - 1, width: button.frame.size.width, height: 1)
        self.border.backgroundColor = UIColor.white.cgColor
        if self.border.superlayer != nil {
            self.border.removeFromSuperlayer()
        }
        button.layer.addSublayer(self.border)
    }
    
    @IBAction func bioButtonClicked(_ sender: Any) {
        activeContainer = 1
        rotateBool = true
        self.activateBorder(button:self.bioButton)
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: .transitionFlipFromRight,
            animations: {
                self.setupContaiers()
        }) { (completed) in
            
        }
    }
    @IBAction func topTracksButtonClicked(_ sender: Any) {
        activeContainer = 2
        rotateBool = true
        self.activateBorder(button:self.tracksButton)
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: .transitionFlipFromRight,
            animations: {
                self.eventsContainer.alpha = 0
                self.c1.alpha = 1
                self.c2.alpha = 0
                
        }) { (completed) in
            if self.fetchTracks.count == 0 {
                DispatchQueue.global(qos: .userInitiated).async {
                    getTopTracks(artistName: self.currentArtist.name, completionHandler: { (success, allTracks) in
                        if success {
                            DispatchQueue.main.async {
                                self.tracksController.allTracks = allTracks
                                self.fetchTracks = allTracks
                                self.c1.addSubview(self.tracksController.view)
                                self.tracksController.loadingIndicator.stopAnimating()
                            }
                        }
                    })
                }
            }else{
                self.tracksController.allTracks = self.fetchTracks
                self.c1.addSubview(self.tracksController.view)
            }
        }
    }
    func showAlertEvent(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Allow", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if UIApplication.shared.canOpenURL(settingsUrl!) {
                UIApplication.shared.open(settingsUrl!, completionHandler: { (success) in
                })
            }
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(imageFit), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        if eventsContainer.alpha == 1 {
            if eventsController != nil {
                eventsController.allSongKickEvents = allSongKickEvents
                eventsController.viewDidLoad()
            }
        }
    }
    @IBAction func eventsButtonClicked(_ sender: Any) {
        activeContainer = 3
        rotateBool = true
        self.activateBorder(button:self.eventsButton)
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: .transitionFlipFromRight,
            animations: {
                self.eventsContainer.alpha = 1
                self.c2.alpha = 0
                self.c1.alpha = 0
        }) { (completed) in
            
            self.eventsContainer.addSubview(self.eventsController.view)
            self.eventsController.noEventsFoundLabel.alpha = 0
            self.eventsController.loadingIndicator.startAnimating()
            
            if self.allSongKickEvents.count == 0 {
                DispatchQueue.global(qos: .userInitiated).async {
                    getSongKickEvents(mbid: self.currentArtist.mbid, name: self.currentArtist.name, completionHandler: {success,result in
                        if success{
                            DispatchQueue.main.async {
                                self.eventsController.allSongKickEvents = result
                                self.eventsController.parentController = self
                                self.allSongKickEvents = result
                                self.eventsController.tableView.reloadData()
                                self.eventsController.enableLabels()
                            }
                        }else{
                            self.eventsController.tableView.reloadData()
                            self.eventsController.enableLabels()
                        }
                    })
                }
            }else{
                self.eventsController.allSongKickEvents = self.allSongKickEvents
                self.eventsController.parentController = self
                self.eventsController.tableView.reloadData()
                self.eventsController.enableLabels()
            }
        }
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { (success, error) in
            if self.eventsController != nil && self.eventsController.tableView != nil {
                DispatchQueue.main.async {
                    self.eventsController.tableView.reloadData()
                    self.eventsController.enableLabels()
                }
            }
            
        }
//        let status = EKEventStore.authorizationStatus(for: .event) == EKAuthorizationStatus.authorized
//        if !status{
//            self.showAlertForAccess()
//        }
        
    }
    
    func setupFavButton(){
        if fetchedResultController.fetchedObjects?.count == 0 {
            yelloFav.isHidden = true
            favButton.isHidden = false
        }else{
            yelloFav.isHidden = false
            favButton.isHidden = true
        }
    }
    
    fileprivate func saveArtist() {
        //Save Changes
        artist = Artists(context:dataController.viewContext)
        artist.name = artistName
        artist.bio = currentArtist.bioContent
        artist.image = UIImageJPEGRepresentation(imageView.image!, 1)
        if let mb = currentArtist?.mbid {
            artist.mbid = mb
        }
        artist.ontour = currentArtist.onTour
        artist.creationDate = Date() // Can be done with awakefrominsert
        
        do{
            try dataController.viewContext.save()
        }catch let e{
            print(e.localizedDescription)
        }
        
        if fetchTracks.count == 0  {
            DispatchQueue.global(qos: .userInitiated).async {
                getTopTracks(artistName: self.artistName, completionHandler: { (success, topTracks) in
                    if success{
                        self.artist = Artists(context:self.dataController.viewContext)
                        DispatchQueue.main.async {
                            for track in topTracks{
                                self.tracks = Tracks(context:self.dataController.viewContext)
                                self.tracks.name = track
                                self.tracks.artist = self.artist
                                do{
                                    try self.dataController.viewContext.save()
                                }catch let e{
                                    print(e.localizedDescription)
                                }
                                
                            }
                            
                        }
                        getSongKickEvents(mbid: self.currentArtist.mbid, name: self.currentArtist.name, completionHandler: { (success, events) in
                            DispatchQueue.main.async {
                                self.allSongKickEvents = events
                                for event in events{
                                    self.events = Events(context:self.dataController.viewContext)
                                    if let eventDate = event["date"] as? Date {
                                        self.events.date = eventDate
                                    }
                                    if let eventLocation = event["location"] as? String {
                                        self.events.location = eventLocation
                                    }
                                    if let eventLocLng = event["lng"] as? Double{
                                        self.events.lng = eventLocLng
                                    }
                                    if let eventLocLat = event["lat"] as? Double{
                                        self.events.lat = eventLocLat
                                    }
                                    if let eventUri = event["uri"] as? String{
                                        self.events.uri = eventUri
                                    }
                                    if let eventVenue = event["venue"] as? String{
                                        self.events.venue = eventVenue
                                    }
                                    
                                    self.events.artistEvents = self.artist
                                    do {
                                        try self.dataController.viewContext.save()
                                    }catch{
                                        fatalError("4")
                                    }
                                }
                                
                            }
                        })
                        if self.currentArtist.mbid != "" {
                                getSocialHandles(mbid: self.currentArtist.mbid, completionHandler: { (success, handles, error) in
                                    self.socials = Socials(context:self.dataController.viewContext)
                                    self.socials.socialsArtist = self.artist
                                    if let fb = handles["facebook"] as? String {
                                        self.socials.facebook = fb
                                    }
                                    if let twitter = handles["twitter"] as? String {
                                        self.socials.twitter = twitter
                                    }
                                    if let ig = handles["instagram"] as? String {
                                        self.socials.instagram = ig
                                    }
                                    if let youtube = handles["youtube"] as? String {
                                        self.socials.yotutube = youtube
                                    }
                                    DispatchQueue.main.async {
                                        do {
                                            try self.dataController.viewContext.save()
                                        }catch{
                                            fatalError(error.localizedDescription)
                                        }
                                    }
                                })
                                
                          
                        }
                        
                    }
                })
                
            }
        }else{
            //Save Tracks
            for track in fetchTracks{
                self.tracks = Tracks(context:self.dataController.viewContext)
                self.tracks.name = track
                self.tracks.artist = self.artist
                do{
                    try self.dataController.viewContext.save()
                }catch let e{
                    print(e.localizedDescription)
                }
            }
            //Needs to change
            for event in allSongKickEvents{
                self.events = Events(context:self.dataController.viewContext)
                if let eventDate = event["date"] as? Date {
                    self.events.date = eventDate
                }
                if let eventLocation = event["location"] as? String {
                    self.events.location = eventLocation
                }
                if let eventLocLng = event["lng"] as? Double{
                    self.events.lng = eventLocLng
                }
                if let eventLocLat = event["lat"] as? Double{
                    self.events.lat = eventLocLat
                }
                if let eventUri = event["uri"] as? String{
                    self.events.uri = eventUri
                }
                if let eventVenue = event["venue"] as? String{
                    self.events.venue = eventVenue
                }
                self.events.artistEvents = self.artist
                do {
                    try self.dataController.viewContext.save()
                }catch let e{
                    print(e.localizedDescription)
                }
            }
            
            if !mbidStatus{
                //Save Socials
                self.socials = Socials(context:self.dataController.viewContext)
                self.socials.socialsArtist = self.artist
                if let fb = allSocialHandles["facebook"] as? String {
                    self.socials.facebook = fb
                }
                if let twitter = allSocialHandles["twitter"] as? String {
                    self.socials.twitter = twitter
                }
                if let ig = allSocialHandles["instagram"] as? String {
                    self.socials.instagram = ig
                }
                if let youtube = allSocialHandles["youtube"] as? String {
                    self.socials.yotutube = youtube
                }
                
                do {
                    try self.dataController.viewContext.save()
                }catch let er{
                    fatalError(er.localizedDescription)
                }
            }
        }
        
        fetchArtist()
        
    }
    
    fileprivate func deleteArtist() {
        
        self.favButton.isEnabled = false
        self.yelloFav.isEnabled = false
        self.fetchArtist()
        self.dataController.viewContext.delete(self.fetchedResultController.fetchedObjects![0])
        do {
            try self.dataController.viewContext.save()
        }catch{
            fatalError("2")
        }
        self.fetchArtist()
        
    }
    
    @IBAction func favoriteButton(_ sender: Any) {
        if favButton.isHidden {
            yelloFav.isHidden = true
            favButton.isHidden = false
        }else{
            yelloFav.isHidden = false
            favButton.isHidden = true
        }
    }
}
extension ArtistDetailViewController{
    func enableButtons(){
        
        if mbidStatus == false{
            if allSocialHandles["facebook"] != nil {
                facebookButton.isEnabled = true
            }
            if allSocialHandles["twitter"] != nil {
                twitterButton.isEnabled = true
            }
            if allSocialHandles["instagram"] != nil {
                instagramButton.isEnabled = true
            }
            if allSocialHandles["youtube"] != nil {
                youtubeButton.isEnabled = true
            }
        }
        enableFavorites()
        bioButton.isEnabled = true
        tracksButton.isEnabled = true
        eventsButton.isEnabled = true
        if allSongKickEvents.count != 0 {
            eventsMapButton.isEnabled = true
        }
        loadingIndicator.stopAnimating()
    }
    
    func disableButtons(){
        facebookButton.isEnabled = false
        twitterButton.isEnabled = false
        instagramButton.isEnabled = false
        youtubeButton.isEnabled = false
        eventsMapButton.isEnabled = false
        disableFavorites()
        bioButton.isEnabled = false
        tracksButton.isEnabled = false
        eventsButton.isEnabled = false
    }
    func setupContaiers(){
        self.eventsContainer.alpha = 0
        self.c2.alpha = 1
        self.c1.alpha = 0
    }
    fileprivate func saveonDisappear() {
        fetchArtist()
        if yelloFav.isHidden{
            if fetchedResultController.fetchedObjects?.count != 0 {
                deleteArtist()
            }
        }else{
            if (fetchedResultController.fetchedObjects?.count)! < 1 {
                saveArtist()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.removeObserver(self)
        do {
            try saveonDisappear()
        }catch let e {
            print(e.localizedDescription)
        }
        super.viewWillDisappear(animated)
    }
    func showAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
            self.viewDidLoad()
        }))
        alert.addAction(UIAlertAction(title: "Go Back", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
extension ArtistDetailViewController {
    fileprivate func fetchAllTracks() {
        let fetchRequest:NSFetchRequest<Tracks> = Tracks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        fetchRequest.predicate = NSPredicate(format:"(artist == %@)",fetchedResultController.fetchedObjects![0])
        
        fetchedTracksController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedTracksController.delegate = self
        do {
            try fetchedTracksController.performFetch()
            if fetchedTracksController.fetchedObjects?.count != 0 {
                for t in fetchedTracksController.fetchedObjects!{
                    fetchTracks.append(t.name!)
                }
            }
        }catch {
            print(error.localizedDescription)
        }
    }
    fileprivate func fetchAllEvents() {
        let fetchRequest:NSFetchRequest<Events> = Events.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format:"(artistEvents == %@)",artist)
        var addEvent = [String:AnyObject]()
        fetchedEventsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedEventsController.delegate = self
        do {
            try fetchedEventsController.performFetch()
            if fetchedEventsController.fetchedObjects?.count != 0 {
//                print(fetchedEventsController.fetchedObjects)
                if allSongKickEvents.count != 0{
                for e in fetchedEventsController.fetchedObjects! {
                    if let date = e.date as? Date{
                        if date <= (Date() - 24*60*60) {
                            self.dataController.viewContext.delete(e)
                            do {
                                try self.dataController.viewContext.save()
                            }catch let e{
                                print(e.localizedDescription)
                            }
                            continue
                        }
                        addEvent["date"] = date as AnyObject
                    }
                    if let location = e.location{
                        addEvent["location"] = location as AnyObject
                    }
                    if let lat = e.lat as? Double{
                        addEvent["lat"] = lat as AnyObject
                    }
                    if let lng = e.lng as? Double{
                        addEvent["lng"] = lng as AnyObject
                    }
                    if let venue = e.venue {
                        addEvent["venue"] = venue as AnyObject
                    }
                    if let location = e.uri {
                        addEvent["uri"] = location as AnyObject
                    }
                    allSongKickEvents.append(addEvent)
                }
            }
            }
        }catch{
            fatalError("Cannot Fetch")
        }
    }
    
    func enableFavorites(){
        if !yelloFav.isHidden{
            yelloFav.isEnabled = true
        }
        if !favButton.isHidden{
            favButton.isEnabled = true
        }
        
    }
    func disableFavorites(){
        if !yelloFav.isHidden{
            yelloFav.isEnabled = false
        }
        if !favButton.isHidden{
            favButton.isEnabled = false
        }
    }
    
    fileprivate func fetchSocials() {
        let fetchRequest:NSFetchRequest<Socials> = Socials.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "facebook", ascending: false)]
        fetchRequest.predicate = NSPredicate(format:"(socialsArtist == %@)",artist)
        // try? dataController.viewContext.fetch(fetchRequest)
        
        fetchedSocialsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedSocialsController.delegate = self
        do {
            try fetchedSocialsController.performFetch()
            if fetchedSocialsController.fetchedObjects?.count != 0 {
                for ab in fetchedSocialsController.fetchedObjects! {
                    if let fb = ab.facebook {
                        allSocialHandles["facebook"] = fb as AnyObject
                    }
                    if let ig = ab.instagram  {
                        allSocialHandles["instagram"] = ig as AnyObject
                    }
                    if let youtube = ab.yotutube  {
                        allSocialHandles["youtube"] = youtube as AnyObject
                    }
                    if let twitter = ab.twitter {
                        allSocialHandles["twitter"] = twitter as AnyObject
                    }
                    
                }
            }
        }catch let er{
            print(er.localizedDescription)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != nil && segue != nil {
            if segue.identifier! == "eventsMap"{
                if let eventsMapController = segue.destination as? EventsMapViewController{
                    print(allSongKickEvents)
                    eventsMapController.allSongKickEvents = allSongKickEvents
                    eventsMapController.previousController = self
                }
            }
        }
    }
}
extension ArtistDetailViewController:CustomViewContainerDelegate{
 
    func openUrl(string: String) {
        //eventUrl = string
        //self.performSegue(withIdentifier: "bookEvent", sender: self)
        if UIApplication.shared.canOpenURL(URL(string:string)!){
            UIApplication.shared.open(URL(string:string)!, options: [:], completionHandler: { (success) in
                
            })
        }
    }
}

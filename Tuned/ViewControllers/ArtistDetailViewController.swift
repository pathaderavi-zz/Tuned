//
//  ArtistDetailViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/28/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
import CoreData

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
    
    //CoreData variables
    var artist:Artists!
    var events:Events!
    var tracks:Tracks!
    var socials:Socials!
    var fetchedResultController:NSFetchedResultsController<Artists>!
    var fetchTracks = [String]()
    var fetchEvents = [String:Bool]()

    override func viewDidDisappear(_ animated: Bool) {
        fetchedResultController = nil
        super.viewDidDisappear(animated)
    }
    fileprivate func fetchArtist() {
        let fetchRequest:NSFetchRequest<Artists> = Artists.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchRequest.predicate = NSPredicate(format:"(name == %@)",artistName)
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            print(result.count)
        }
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
            if fetchedResultController.fetchedObjects?.count != 0 {
                artist = fetchedResultController.fetchedObjects![0]
            }
        }catch{
            fatalError("Cannot Fetch")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchArtist()
        setupFavButton()
        disableButtons()
        tracksController = self.storyboard!.instantiateViewController(withIdentifier: "tracksContainer") as! TracksContainer
        eventsController = self.storyboard?.instantiateViewController(withIdentifier: "eventsContainer") as! EventsContainer
        scrollView.bounces = false
        scrollView.delegate = self
        self.navigationItem.title = artistName
        self.onTour.isHidden = true
        onTour.layer.cornerRadius = onTour.frame.width/2
        onTour.layer.masksToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(imageFit), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        let updatedName = artistName.replacingOccurrences(of: " " , with: "+")
        imageView.image = UIImage(data:imageData)
        imageFit()
        activateBorder(button: bioButton)
        //yelloFav.isHidden = true
        DispatchQueue.global(qos:.userInitiated).async {
            
            artistDataDownload(artist: updatedName, completionHadler: { (success,artist) in
                self.currentArtist = artist
                self.mbidStatus = (artist.mbid == "")
                DispatchQueue.main.async {
                    let controller = self.storyboard!.instantiateViewController(withIdentifier: "bioContainer") as! BioContainer
                    if artist.onTour == "0"{
                        self.onTour.isHidden = true
                    }else{
                        self.onTour.isHidden = false
                    }
                    controller.bioLabelText = artist.bioContent
                    controller.lastFmUrl = NSMutableAttributedString(string:artist.bioContent)
                    self.c2.addSubview(controller.view)
                }
                
                getSocialHandles(mbid: artist.mbid) { (success, result) in
                    if success{
                        self.allSocialHandles = result
                        
                    }
                    DispatchQueue.main.async {
                        self.enableButtons()
                    }
                    
                }
            })
            
        }
        self.setupContaiers()
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
            
        }else{
            //Show alert , does not contain url
        }
    }
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
        
        if(UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
            imageView.contentMode = UIViewContentMode.scaleAspectFit
            if activeContainer == 1 {
                activateBorder(button: bioButton)
            }else if activeContainer == 2 {
                activateBorder(button: tracksButton)
            }else {
                activateBorder(button: eventsButton)
            }
            
        }else if(UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown){
            imageView.contentMode = UIViewContentMode.scaleAspectFill
        }
    }
    
    @IBOutlet weak var eventsButton: UIButton!
    @IBOutlet weak var tracksButton: UIButton!
    @IBOutlet weak var bioButton: UIButton!
    @IBOutlet weak var yelloFav: UIButton!
    @IBOutlet weak var favButton: UIButton!
    let border = CALayer()
    fileprivate func activateBorder(button:UIButton) {
        
        if let count = (button.layer.sublayers?.count) {
            if count > 1{
                // return
            }
        }
        let appearAnimation = CABasicAnimation(keyPath: "opacity")
        appearAnimation.fromValue = 0
        appearAnimation.toValue = button.frame.size.width
        appearAnimation.duration = 10
        button.layer.add(appearAnimation, forKey: "opacity")
        self.border.frame = CGRect(x: 0, y: button.frame.origin.y + button.frame.height - 1, width: button.frame.size.width, height: 1)
        self.border.backgroundColor = UIColor.white.cgColor
        self.border.removeFromSuperlayer()
        button.layer.addSublayer(self.border)
        
    }
    
    @IBAction func bioButtonClicked(_ sender: Any) {
        activeContainer = 1
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
            DispatchQueue.global(qos: .userInitiated).async {
                getTopTracks(artistName: self.currentArtist.name, completionHandler: { (success, allTracks) in
                    if success {
                        DispatchQueue.main.async {
                            self.tracksController.allTracks = allTracks
                            self.fetchTracks = allTracks
                            self.c1.addSubview(self.tracksController.view)
                            // self.tracksController.loadingIndicator.stopAnimating()
                        }
                    }
                })
                
                
                
            }
        }
    }
    @IBAction func eventsButtonClicked(_ sender: Any) {
        activeContainer = 3
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
            DispatchQueue.global(qos: .userInitiated).async {
                getLatestEvents(artistMbid: self.currentArtist.mbid, completionHandler: { (success, some) in
                    if success{
                        DispatchQueue.main.async {
                            self.eventsController.allEvents = some
                            self.fetchEvents = some
                            self.eventsContainer.addSubview(self.eventsController.view)
                            self.eventsController.tableView.reloadData()
                            self.eventsController.loadingIndicator.stopAnimating()
                            
                        }
                    }
                })
            }
        }
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
        artist.image = imageData
        if let mb = currentArtist?.mbid {
            artist.mbid = mb
        }
        artist.ontour = currentArtist.onTour
        artist.creationDate = Date() // Can be done with awakefrominsert
        
        if fetchTracks.count == 0 || fetchTracks.count == 0{
            DispatchQueue.global(qos: .userInitiated).async {
                getTopTracks(artistName: self.artistName, completionHandler: { (success, topTracks) in
                    if success{
                        DispatchQueue.main.async {
                            
                            for track in topTracks{
                                self.tracks = Tracks(context:self.dataController.viewContext)
                                self.tracks.name = track
                                self.tracks.artist = self.artist
                                try? self.dataController.viewContext.save()
                            }
                        
                        }
                        if self.currentArtist.mbid != "" {
                            getLatestEvents(artistMbid: self.currentArtist.mbid, completionHandler: { (success, events) in
                                DispatchQueue.main.async {
                                
                                    for event in events{
                                        self.events = Events(context:self.dataController.viewContext)
                                        self.events.name = event.key
                                        self.events.artistEvents = self.artist
                                        try? self.dataController.viewContext.save()
                                    }
                                   
                                }
                                getSocialHandles(mbid: self.currentArtist.mbid, completionHandler: { (success, handles) in
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
                                    do {
                                        try self.dataController.viewContext.save()
                                    }catch{
                                        fatalError(error.localizedDescription)
                                    }
                                })
                            })
                        }
              
                    }
                })
            }
        }
        
        try? dataController.viewContext.save()
        fetchArtist()
        print(fetchedResultController.fetchedObjects?.count)
        
        favButton.isHidden = true
        yelloFav.isHidden = false
    }
    
    fileprivate func extractedFunc() {
        dataController.viewContext.delete(artist)
        try? dataController.viewContext.save()
        fetchArtist()
        print(fetchedResultController.fetchedObjects?.count)
        favButton.isHidden = false
        yelloFav.isHidden = true
    }
    
    @IBAction func favoriteButton(_ sender: Any) {
        if yelloFav.isHidden{
            saveArtist()
        }else{
            extractedFunc()
            //Delete Changes
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
        bioButton.isEnabled = true
        tracksButton.isEnabled = true
         eventsButton.isEnabled = false
        loadingIndicator.stopAnimating()
    }
    
    func disableButtons(){
        facebookButton.isEnabled = false
        twitterButton.isEnabled = false
        instagramButton.isEnabled = false
        youtubeButton.isEnabled = false
        
        bioButton.isEnabled = false
        tracksButton.isEnabled = false
        eventsButton.isEnabled = false
    }
    func setupContaiers(){
        self.eventsContainer.alpha = 0
        self.c2.alpha = 1
        self.c1.alpha = 0
    }
}


//
//  ArtistDetailViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/28/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

class ArtistDetailViewController: UIViewController{
    var artistName:String!
    var imageData:Data!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var eventsContainer: UIView!
    @IBOutlet weak var onTour: UILabel!
    var currentArtist:Artist!
    @IBOutlet weak var c2: UIView! // bioContainer
    @IBOutlet weak var c1: UIView! // tracksContainer
    var tracksController:TracksContainer!
    override func viewDidLoad() {
        super.viewDidLoad()
        tracksController = self.storyboard!.instantiateViewController(withIdentifier: "tracksContainer") as! TracksContainer
        scrollView.bounces = false
        self.onTour.isHidden = true
        self.navigationItem.title = artistName
        onTour.layer.cornerRadius = onTour.frame.width/2
        onTour.layer.masksToBounds = true
       
        NotificationCenter.default.addObserver(self, selector: #selector(imageFit), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        let updatedName = artistName.replacingOccurrences(of: " " , with: "+")
        imageView.image = UIImage(data:imageData)
        imageFit()
        activateBorder(button: bioButton)
        yelloFav.isHidden = true
        DispatchQueue.global(qos:.userInitiated).async {
            artistDataDownload(artist: updatedName, completionHadler: { (success,artist) in
                self.currentArtist = artist
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
            })
            
        }
        self.setupContaiers()
    }
    @objc func imageFit(){
        //toDO if position is at 0, scroll to 2nd stack
        if(UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
            imageView.contentMode = UIViewContentMode.scaleAspectFit
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
                return
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
                            self.c1.addSubview(self.tracksController.view)
                        }
                    }
                })
                
                
                
            }
        }
    }
    @IBAction func eventsButtonClicked(_ sender: Any) {
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
                    print(success)
                })
            }
        }
    }
    
    
    
    @IBAction func favoriteButton(_ sender: Any) {
        if yelloFav.isHidden{
            favButton.isHidden = true
            yelloFav.isHidden = false
        }else{
            favButton.isHidden = false
            yelloFav.isHidden = true
        }
    }
}
extension ArtistDetailViewController{
    func setupContaiers(){
        self.eventsContainer.alpha = 0
        self.c2.alpha = 1
        self.c1.alpha = 0
    }
}


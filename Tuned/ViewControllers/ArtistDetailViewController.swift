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
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var onTour: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = artistName
        onTour.layer.cornerRadius = onTour.frame.width/2
        onTour.layer.masksToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(imageFit), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        let updatedName = artistName.replacingOccurrences(of: " " , with: "+")
        imageView.image = UIImage(data:imageData)
        imageFit()
        yelloFav.isHidden = true
        DispatchQueue.global(qos:.userInitiated).async {
            artistDataDownload(artist: updatedName, completionHadler: { (success,test) in
                if success{
                    DispatchQueue.main.async(execute: {
                        let updatedTest = test.components(separatedBy: "<a")
                    })
                }
            })
        }
        
    }
    @objc func imageFit(){
        //toDO if position is at 0, scroll to 2nd stack
        if(UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
            imageView.contentMode = UIViewContentMode.scaleAspectFit
        }else if(UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown){
            imageView.contentMode = UIViewContentMode.scaleAspectFill
        }
    }
    
    @IBOutlet weak var yelloFav: UIButton!
    @IBOutlet weak var favButton: UIButton!
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


//
//  Artist.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation

class Artist{
    var name = ""
    var lastFmUrl = ""
    var mbid = ""
    var imageUrl = ""
    var onTour = ""
    //var similarArtists = "" // Use Dictionary Here
    //var tags = "" // Use array/Dictionary here
    //var bioLink = "" //Append +Wiki
    var summary = ""
    var bioContent = ""
    
    
    init(dictionary:[String:AnyObject]) {
        if let n = dictionary["name"] as? String {
               name = n
        }
        if let mb = dictionary["mbid"] as? String{
            mbid = mb
        }
        if let oT = dictionary["ontour"] as? String {
            onTour = oT
        }
        if let fmUrl = dictionary["url"] as? String {
            lastFmUrl = fmUrl
        }
        
        if let set2 = dictionary["bio"]{
            if let bioContent = set2["summary"] as? String{
                self.bioContent = bioContent
            }
        }

        if let imageSet = dictionary["image"] as? [[String:AnyObject]]{
     
            for i in imageSet{
                if i["size"] as! String == "large"{
                    self.imageUrl = i["#text"] as! String
                }
            }
            
        }
    }

    
}

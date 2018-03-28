//
//  Requests.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation

func getTopArtists(completionHandler:@escaping(_ allImages:[String:String])->Void) {
    var topArtistUrl = "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    var all = [String:String]()
    let session = URLSession.shared
    let request = URLRequest(url:URL(string:topArtistUrl)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        guard error == nil else{
            print(error?.localizedDescription)
            return
        }
        let parsedResult : [String:AnyObject]!
        do {
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
        }catch{
            fatalError("Cannot deserialize")
        }
        if let allArtists = parsedResult["artists"] as? [String:AnyObject]{
            if let artists = allArtists["artist"] as? [[String:AnyObject]]{
                for a in artists{
                    if let b = a ["image"] as? [[String:AnyObject]]{
                        for b1 in b {
                            if let medium = b1["size"] as? String {
                                if medium == "large"{
                                    //print(b1["#text"] as Any)
                                    if let name = a["name"] as! String? {
                                        if let imageUrl = b1["#text"] as! String?{
                                            all[name as String] = imageUrl as String
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
        completionHandler(all)
    }
    task.resume()
}

func imageDownload(imageUrl:String,completionHandler:@escaping(_ success:Bool,_ imageData:Data)->Void){
    let session = URLSession.shared
    let url = NSURL(string:imageUrl)
    let request = NSURLRequest(url: url as! URL)
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
        if data == nil {
            completionHandler(false,data!)
            return
        }else{
            completionHandler(true,data!)
        }
    }
    task.resume()
}




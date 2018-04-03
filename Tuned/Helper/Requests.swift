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
            //completionHandler(false,error as! Data)
            return
        }else{
            completionHandler(true,data!)
        }
    }
    task.resume()
}

func artistDataDownload(artist:String,completionHadler:@escaping(_ success:Bool,_ artist:Artist)->Void){
    let session = URLSession.shared
    let updatedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let stringUrl = "https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=\(updatedArtist)&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    let request = URLRequest(url:URL(string:stringUrl)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        if error != nil {
            return
        }
        let parsedResult:[String:AnyObject]!
        do {
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
            
        }catch{
            fatalError("Cannot Deserialize")
        }
        if let set1 = parsedResult["artist"] as? [String:AnyObject]{
            
            let result = Artist.init(dictionary: set1)

            completionHadler(true,result)
        }
       
        
    }
    task.resume()
}

func getTopTracks(artistName:String,completionHandler:@escaping(_ success:Bool,_ result: [String])->Void){
    var result = [String]()
    let updatedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let url = "https://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&limit=20&artist=\(updatedArtist)&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    let request = URLRequest(url: URL(string:url)!)
    let sesssion = URLSession.shared
    
    let task = sesssion.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
            return
        }
        let parsedResult:[String:AnyObject]
        do {
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
        }catch{
            fatalError("Cannot parse")
        }
        if let topTracks = parsedResult["toptracks"] as? [String:AnyObject] {
            if let tracks = topTracks["track"] as? [[String:AnyObject]]{
                for track in tracks{
                    if let trackName = track["name"]{
                        result.append(trackName as! String)
                    }
                }
                completionHandler(true,result)
            }
        }
    }
    task.resume()
}

func getLatestEvents(artistMbid:String,completionHandler:@escaping(_ success:Bool,_ result:[String:Bool])->Void){
    var result = [String:Bool]()
    let url = "https://musicbrainz.org/ws/2/artist/\(artistMbid)?inc=event-rels&fmt=json&limit=20"
    let request = URLRequest(url:URL(string:url)!)
    let session = URLSession.shared
    let task = session.dataTask(with: request) { (data, response, error) in
        guard error == nil else{
            return
        }
        let parsedResult:[String:AnyObject]!
        do {
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
        }catch{
            fatalError("Cannot Parse")
        }
        if let relations = parsedResult["relations"] as? [Any]{
            for p in relations{
                if let dict = p as? [String:AnyObject]{
                    if let events = dict["event"] as? [String:AnyObject]{
                        if let eventName = events["name"] as? String, let cancelled = events["cancelled"] as? Bool{
                            result[eventName] = cancelled
                        }
                        
                    }
                }
            }
            completionHandler(true,result)
        }
    }
    task.resume()
}

func getSocialHandles(mbid:String,completionHandler:@escaping(_ success:Bool,_ result:[String:AnyObject])->Void){
    var result = [String:AnyObject]()
    let url = "https://musicbrainz.org/ws/2/artist/\(mbid)?inc=url-rels&fmt=json"
    let session = URLSession.shared
    let request = URLRequest(url:URL(string:url)!)

    let task = session.dataTask(with: request) { (data, response, error) in
        
        guard error == nil else{
            return
        }
        let parsedResult:[String:AnyObject]!
        
        do{
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
        }catch{
            fatalError("Cannot parse")
        }
        if let relations = parsedResult["relations"] as? [Any]{
            for r in relations{
             
                if let dict = r as? [String:AnyObject]{
                    if let urlDict = dict["url"] as? [String:AnyObject]{
                        if let urlString = urlDict["resource"] as? String {
                            if (urlString.range(of: "youtube") != nil){
                                result["youtube"] = urlString as AnyObject
                            }
                            if (urlString.range(of: "instagram") != nil){
                                result["instagram"] = urlString as AnyObject
                            }
                            if (urlString.range(of: "twitter") != nil){
                                result["twitter"] = urlString as AnyObject
                            }
                            if (urlString.range(of: "facebook") != nil){
                                result["facebook"] = urlString as AnyObject
                            }
                        }
                      
                    }
                    
                }
            }
             completionHandler(true,result)
        }else{
            completionHandler(false,result)
        }
    }
    task.resume()
}




//
//  Requests.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

func getTopArtists(completionHandler:@escaping(_ success:Bool, _ allImages:[String:String])->Void) {
    var topArtistUrl = "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    var all = [String:String]()
    let session = URLSession.shared
    let request = URLRequest(url:URL(string:topArtistUrl)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        guard error == nil else{
            // if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
            completionHandler(false,all)
            //}
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
                                //                                if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .unspecified {
                                //                                    if medium == "extralarge" {
                                //                                        if let name = a["name"] as! String? {
                                //                                            if let imageUrl = b1["#text"] as! String?{
                                //                                                all[name as String] = imageUrl as String
                                //                                            }
                                //                                        }
                                //                                    }
                                //                                }
                            }
                        }
                    }
                }
            }
        }
        completionHandler(true,all)
    }
    task.resume()
}

func imageDownload(imageUrl:String,completionHandler:@escaping(_ success:Bool,_ imageData:Data)->Void){
    let session = URLSession.shared
    let url = NSURL(string:imageUrl)
    let request = NSURLRequest(url: url as! URL)
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
        if data == nil {
            if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
                completionHandler(false,Data())
            }
            
            return
        }else{
            completionHandler(true,data!)
        }
    }
    task.resume()
}

func artistDataDownload(artist:String,completionHadler:@escaping(_ success:Bool,_ artist:Artist,_ noneFound:Bool)->Void){
    let session = URLSession.shared
    let updatedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let stringUrl = "https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=\(updatedArtist)&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    
    let request = URLRequest(url:URL(string:stringUrl)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        if error != nil {
            if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
                completionHadler(false,Artist(dictionary: [:]),false)
            }
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
            
            completionHadler(true,result,false)
        }else{
            completionHadler(true,Artist(dictionary: [:]),true)
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
            if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
                completionHandler(false,result)
                
            }
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
            if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
                completionHandler(false,result)
            }
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

func getSocialHandles(mbid:String,completionHandler:@escaping(_ success:Bool,_ result:[String:AnyObject],_ error:Bool)->Void){
    var result = [String:AnyObject]()
    let url = "https://musicbrainz.org/ws/2/artist/\(mbid)?inc=url-rels&fmt=json"
    let session = URLSession.shared
    let request = URLRequest(url:URL(string:url)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        
        guard error == nil else{
            if (error?.localizedDescription as! String) == "The Internet connection appears to be offline."{
                completionHandler(false,result,true)
            }
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
            completionHandler(true,result,false)
        }else{
            completionHandler(false,result,false)
        }
    }
    task.resume()
}

func searchArtists(search:String, completionHandler:@escaping(_ success:Bool,_ searchArtists:[String:String],_ allSearchUrls:[String:String])->Void){
    let sesssion = URLSession.shared
    let updatedName = search.replacingOccurrences(of: " " , with: "+")
    let updatedArtist = updatedName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let url = "https://ws.audioscrobbler.com/2.0/?method=artist.search&artist=\(updatedArtist)&api_key=63bc85712ced4b9c92bed61d2e60441e&format=json"
    let request = URLRequest(url:URL(string:url)!)
    var allLastFmUrls = [String:String]()
    let task = sesssion.dataTask(with: request, completionHandler: { (data, response, error) in
        var result = [String:String]()
        guard error == nil else {
            //Handle error Condition
            completionHandler(false,result,allLastFmUrls)
            print(error?.localizedDescription)
            return
        }
        let parsedResult : [String:AnyObject]!
        
        do{
            try parsedResult = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
            
        }catch{
            fatalError("Cannot parse")
        }
        
        if let res = parsedResult["results"] as? [String:AnyObject]{
            if let artistMatches = res["artistmatches"] as? [String:AnyObject]{
                if let artistArray = artistMatches["artist"] as? [[String:AnyObject]] {
                    for a in artistArray {
                        if let name = a["name"] as? String{
                            if let image = a["image"] as? [[String:AnyObject]]{
                                for i in image {
                                    if i["size"] as? String == "large" {
                                        let u = (i["#text"] as? String) != ""
                                        if u {
                                            result[name] = i["#text"] as? String
                                            allLastFmUrls[name] = a["url"] as? String
                                        }
                                    }
                                    //                                    if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .unspecified {
                                    //                                        if i["size"] as? String == "extralarge" {
                                    //                                            let u = (i["#text"] as? String) != ""
                                    //                                            if u {
                                    //                                                result[name] = i["#text"] as? String
                                    //                                                allLastFmUrls[name] = a["url"] as? String
                                    //                                            }
                                    //                                        }
                                    //                                    }
                                }
                            }
                        }
                    }
                    completionHandler(true,result,allLastFmUrls)
                }
            }
        }
        
    })
    task.resume()
}

let SONGKICK_API_KEY:String = "SONGKICK_API_KEY"
let locationKey = "location"
let urlKey = "url"
let venueName = "venuename"

func getSongKickEvents(mbid:String,name:String,completionHandler:@escaping(_ success:Bool,_ events:[[String:AnyObject]])->Void){
    let session = URLSession.shared
    let updatedName = name.replacingOccurrences(of: " " , with: "+")
    let updatedArtist = updatedName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    var url:String = ""
    if mbid != "" {
        url = "https://api.songkick.com/api/3.0/artists/mbid:\(mbid)/calendar.json?apikey=\(SONGKICK_API_KEY)"
    }else{
        url = "https://api.songkick.com/api/3.0/search/artists.json?apikey=\(SONGKICK_API_KEY)&query=\(updatedArtist)"
    }
    var result = [String:AnyObject]()
    var finalResult = [[String:AnyObject]]()
    let request = URLRequest(url:URL(string:url)!)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        guard error == nil else{
            completionHandler(false,finalResult)
            return
        }
        let parsedResult:[String:AnyObject]!
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
            
        }catch {
            fatalError()
        }
        //AgeRestriction,Location,URL, VenueName
        //Trim Event Displaly Name
        if let resultsPage = parsedResult["resultsPage"] as? [String:AnyObject]{
            if let results = resultsPage["results"] as? [String:AnyObject]{
                if let event = results["event"] as? [[String:AnyObject]] {
                    for e in event{
                        if let eventName = e["ageRestriction"] as? Bool{
                            result["agerestriction"] = eventName as AnyObject
                        }else{
                            result["agerestriction"] = nil
                        }
                        if let event_uri = e["uri"] as? String{
                            result["uri"] = event_uri as AnyObject
                        }
                        if let event_start = e["start"] as? [String:AnyObject]{
                            let dateFormatter = DateFormatter()
                            if let event_date = event_start["datetime"] as? String{
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                                let date = dateFormatter.date(from: event_date)!
                                result["date"] = date as AnyObject
                            }else if let event_date = event_start["date"] as? String{
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                let date = dateFormatter.date(from: event_date)!
                                result["date"] = date as AnyObject
                            }
                            
                        }
                        if let location = e["location"] as? [String:AnyObject]{
                            if let cityName = location["city"] as? String{
                                result["location"] = cityName as AnyObject
                            }
                        }
                        
                        if let venue = e["venue"] as? [String:AnyObject]{
                            if let lat = venue["lat"] as? Double{
                                result["lat"] = lat as AnyObject
                            }
                            if let lng = venue["lng"] as? Double{
                                result["lng"] = lng as AnyObject
                            }
                            if let displayName = venue["displayName"] as? String{
                                result["venue"] = displayName as AnyObject
                            }
                        }
                        finalResult.append(result)
                    }
                    completionHandler(true,finalResult)
                }else if  let artistResult = results["artist"] as? [[String:AnyObject]] {
                    var searchArtist = [String]()
                    for a in artistResult {
                        if let identifier = a["identifier"] as? [AnyObject]{
                            for i in identifier {
                                if let mbid2 = i["mbid"] as? String{
                                    searchArtist.append(mbid2)
                                }
                            }
                            
                        }
                    }
                }
            }
        }
        if finalResult.count == 0  {
            if finalResult.count == 0  {
                url = "https://api.songkick.com/api/3.0/search/artists.json?apikey=\(SONGKICK_API_KEY)&query=\(updatedArtist)"
                let request2 = URLRequest(url:URL(string:url)!)
                let task2 = session.dataTask(with: request2) { (data2, response2, error2) in
                    guard error2 == nil else{
                        completionHandler(false,finalResult)
                        return
                    }
                    let parsedResult2:[String:AnyObject]!
                    
                    do {
                        parsedResult2 = try JSONSerialization.jsonObject(with: data2!, options: .allowFragments) as! [String:AnyObject]
                    }catch {
                        fatalError()
                    }
                    var searchArtist = [String]()
                    if let r1 = parsedResult2["resultsPage"] as? [String:AnyObject]{
                        if let r2 = r1["results"] as? [String:AnyObject]{
                            if let resultsPageFirst = r2["artist"] as? [[String:AnyObject]]{
                                for a in resultsPageFirst {
                                    if let skId = a["id"] as? Int {
                                        let url3 = "https://api.songkick.com/api/3.0/artists/\(skId)/calendar.json?apikey=\(SONGKICK_API_KEY)"
                                        let request3 = URLRequest(url:URL(string:url3)!)
                                        let task3 = session.dataTask(with: request3, completionHandler: { (data3, response3, error3) in
                                            guard error3 == nil else{
                                                completionHandler(false,finalResult)
                                                return
                                            }
                                            let parsedResult3:[String:AnyObject]!
                                            
                                            do {
                                                parsedResult3 = try JSONSerialization.jsonObject(with: data3!, options: .allowFragments) as! [String:AnyObject]
                                            }catch {
                                                fatalError()
                                            }
                                            
                                            if let resultsPage = parsedResult3["resultsPage"] as? [String:AnyObject]{
                                                
                                                if let results = resultsPage["results"] as? [String:AnyObject]{
                                                    if let event = results["event"] as? [[String:AnyObject]] {
                                                        for e in event{
                                                            if let eventName = e["ageRestriction"] as? Bool{
                                                                result["agerestriction"] = eventName as AnyObject
                                                            }else{
                                                                result["agerestriction"] = nil
                                                            }
                                                            if let event_uri = e["uri"] as? String{
                                                                result["uri"] = event_uri as AnyObject
                                                            }
                                                            if let event_start = e["start"] as? [String:AnyObject]{
                                                                let dateFormatter = DateFormatter()
                                                                if let event_date = event_start["datetime"] as? String{
                                                                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                                                                    let date = dateFormatter.date(from: event_date)!
                                                                    result["date"] = date as AnyObject
                                                                }else if let event_date = event_start["date"] as? String{
                                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                                    let date = dateFormatter.date(from: event_date)!
                                                                    result["date"] = date as AnyObject
                                                                }
                                                                
                                                            }
                                                            if let location = e["location"] as? [String:AnyObject]{
                                                                if let cityName = location["city"] as? String{
                                                                    result["location"] = cityName as AnyObject
                                                                }
                                                            }
                                                            
                                                            if let venue = e["venue"] as? [String:AnyObject]{
                                                                if let lat = venue["lat"] as? Double{
                                                                    result["lat"] = lat as AnyObject
                                                                }
                                                                if let lng = venue["lng"] as? Double{
                                                                    result["lng"] = lng as AnyObject
                                                                }
                                                                if let displayName = venue["displayName"] as? String{
                                                                    result["venue"] = displayName as AnyObject
                                                                }
                                                            }
                                                            finalResult.append(result)
                                                        }
                                                        
                                                    }
                                                }
                                                completionHandler(true,finalResult)
                                            }
                                        })
                                        task3.resume()
                                        break
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        
                    }
                    
                }
                task2.resume()
            }
        }
    }
    task.resume()
}



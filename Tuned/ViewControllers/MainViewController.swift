//
//  ViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {
    
    //-----All Variables
    
    var homeTappedBool:Bool = true
    @IBOutlet weak var homeButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mainLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noArtistsSavedLabel: UILabel!
    var allArtists = [String:String]()
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    var artistName:String!
    @IBOutlet weak var searchTableView: UITableView!
    var allImageData = [IndexPath:Data]()
    var imageData:Data!
    var dataController:DataController!
    var imageCache = NSCache<AnyObject, AnyObject>()
    var imageURLString : String?
    var showSavedBool: Bool = false
    var fetchedResultsController:NSFetchedResultsController<Artists>!
    var sendUrl:String = ""
    var allUrlsLastFm = [String:String]()
    @IBOutlet weak var showSavedButton: UIBarButtonItem!
    
    //---- Lifecycle Callbacks
    
    override func viewDidDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print(UIColor.red)
        self.navigationItem.title = "Tunies"
        searchTableView.alpha = 0
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.bounces = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(setupFlowLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(visibleCollectionViewCellsReload), name: .UIApplicationDidBecomeActive, object: nil)
        searchBar.delegate = self
        searchBar.setValue("Show All", forKey:"_cancelButtonText")
        searchBar.placeholder = "Showing Top Artists"
        showSavedButton.isEnabled = false
        DispatchQueue.global(qos: .userInitiated).async {
            getTopArtists { success , ab in
                DispatchQueue.main.async {
                    self.collectionView.delegate = self
                    self.collectionView.dataSource = self
                    if success {
                        self.allArtists = ab
                        self.collectionView.reloadData()
                        
                    }else{
                        self.showAlert(title: "Unable to Fetch Data", message: "Please Retry Again.")
                    }
                    self.mainLoadingIndicator.stopAnimating()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showSavedButton.isEnabled = true
                }
                
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupFlowLayout()
        super.viewWillAppear(animated)
        if !showSavedBool{
            if collectionView != nil {
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            }
            
        }else{
            fetchAllArtists()
            collectionView.reloadData()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                noArtistsSavedLabel.alpha = 1
            }else{
                noArtistsSavedLabel.alpha = 0
            }
        }
        
        
        self.setupFlowLayout()
    }
    
    //--- Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let sb = searchBar
        searchBar.text = UserDefaults.standard.string(forKey: "lastSearch")
        searchBarSearchButtonClicked(sb!)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let check = UserDefaults.standard.string(forKey: "lastSearch") == nil
        if !check{
            cell.textLabel?.text = "Previously Searched for \""+UserDefaults.standard.string(forKey: "lastSearch")!+"\""
        }
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        return cell
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            self.searchBar.resignFirstResponder()
        }
        
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let check = UserDefaults.standard.string(forKey: "lastSearch") == nil
        if check {
            
        }else{
            searchTableView.frame = CGRect(x: searchTableView.frame.origin.x, y: searchTableView.frame.origin.y, width: searchTableView.frame.size.width, height: searchTableView.contentSize.height)
            UIView.animate(
                withDuration: 0.2,
                delay: 0.0,
                options: .transitionCurlUp,
                animations: {
                    self.searchTableView.alpha = 1
                    self.searchTableView.reloadData()
            }) { (completed) in
                
            }
            if showSavedBool{
                
            }
        }
    }
    
    var prevFetch = false
    var goHome = false
    var searchStringFav:String!
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let userDefaults = UserDefaults.standard
        if showSavedBool{
            //Search Saved
            if searchBar.text?.count != 0 {
                userDefaults.set(searchBar.text, forKey: "lastSearch")
                prevFetch = true
                if prevFetch{
                    homeButton.isEnabled = true
                    searchStringFav = searchBar.text
                    fetchAllArtists()
                    prevFetch = false
                    goHome = true
                    if fetchedResultsController.fetchedObjects?.count == 0 {
                        self.noArtistsSavedLabel.text = "No Artists Found"
                        self.noArtistsSavedLabel.alpha = 1
                    }else{
                        self.noArtistsSavedLabel.alpha = 0
                    }
                    collectionView.reloadData()
                }
            }else{
                
            }
        }else{
            if searchBar.text?.count != 0 {
                userDefaults.set(searchBar.text, forKey: "lastSearch")
                showSavedButton.isEnabled = false
                self.mainLoadingIndicator.startAnimating()
                //navigationItem.rightBarButtonItem?.isEnabled = false
                navigationItem.leftBarButtonItem?.isEnabled = true
                homeTappedBool = false
                let q = searchBar.text!
                searchBar.text = ""
                searchBar.placeholder = "Showing Results for " + q
                
                DispatchQueue.global(qos: .userInitiated).async {
                    searchArtists(search: q, completionHandler: {success, res , lastFmUrl in
                        if success {
                            self.allArtists = res
                            self.imageCache = NSCache<AnyObject, AnyObject>()
                            self.allUrlsLastFm = lastFmUrl
                            DispatchQueue.main.async {
                                if self.allArtists.count == 0 {
                                    self.noArtistsSavedLabel.alpha = 1
                                    self.collectionView.alpha = 0
                                    self.view.backgroundColor = UIColor.black
                                    self.noArtistsSavedLabel.text = "No Artists Found"
                                }else{
                                    self.noArtistsSavedLabel.alpha = 0
                                    self.collectionView?.setContentOffset(CGPoint.zero, animated: false)
                                    self.collectionView.alpha = 1
                                    self.collectionView.reloadData()
                                }
                                self.mainLoadingIndicator.stopAnimating()
                                
                                
                                
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.mainLoadingIndicator.stopAnimating()
                                self.showAlert(title: "Unable to Search", message: "Please Try Again")
                            }
                        }
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showSavedButton.isEnabled = true
                    }
                }
            }else{
                searchBar.text = ""
                searchBar.placeholder = "Please enter some text"
            }
            
        }
        
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: .transitionCurlDown,
            animations: {
                self.searchTableView.alpha = 0
                self.searchBar.resignFirstResponder()
        }) { (completed) in
            
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        if showSavedBool{
        }
    }
    //--- IBAction Functions
    
    @IBAction func homeButtonTapped(_ sender: Any) {
        
        if !homeTappedBool {
            if showSavedBool{
                showSavedBool = false
                homeButtonTapped(self)
                noArtistsSavedLabel.alpha = 0
                navigationItem.rightBarButtonItem?.title = "Show Saved"
                navigationItem.rightBarButtonItem?.tintColor = UIColor.white
                return
            }
            if collectionView.alpha == 0 {
                collectionView.alpha = 1
                noArtistsSavedLabel.alpha = 0
            }
            searchBar.text = ""
            homeTappedBool = true
            UIView.animate(withDuration: 0.8, delay: 0, options: .transitionFlipFromTop
                , animations: {
                    self.collectionView.isScrollEnabled = false
                    self.imageCache = NSCache<AnyObject, AnyObject>()
                    DispatchQueue.main.suspend()
                    DispatchQueue.global(qos: .userInitiated).suspend()
                    self.self.collectionView.delegate = nil
                    self.collectionView.dataSource = nil
                    
                    
                    self.imageCache = NSCache<AnyObject, AnyObject>()
                    self.allArtists = [String:String]()
                    self.allUrlsLastFm = [String:String]()
                    
                    self.collectionView.delegate = self
                    self.collectionView.dataSource = self
                    self.collectionView?.setContentOffset(CGPoint.zero, animated: false)
                    self.viewDidLoad()
                    self.collectionView.isScrollEnabled = true
            }) { (success) in
                
            }
            
        }else{
        }
    }
    
    @IBAction func showSavedButtonTapped(_ sender: Any) {
        //another boolean
        if goHome{
            fetchAllArtists()
            goHome = false
            showSavedBool = false
            if fetchedResultsController.fetchedObjects?.count == 0 {
                self.noArtistsSavedLabel.text = "No Artists Found"
                self.noArtistsSavedLabel.alpha = 1
            }else{
                self.noArtistsSavedLabel.alpha = 0
            }
            showSavedButtonTapped(self)
            return
        }
        
        if self.showSavedBool {
            self.noArtistsSavedLabel.alpha = 0
            self.showSavedButton.title = "Show Saved"
            searchBar.placeholder = "Search Here"
            navigationItem.rightBarButtonItem?.tintColor = UIColor.white
            
            //
        }else{
            
            navigationItem.rightBarButtonItem?.tintColor = UIColor.red
            self.fetchAllArtists()
            searchBar.placeholder = ""
            for d in self.fetchedResultsController.fetchedObjects! {
                if d.name == nil {
                    self.dataController.viewContext.delete(d)
                    try? self.dataController.viewContext.save()
                }
            }
            searchBar.text = ""
            let count = String(self.fetchedResultsController.fetchedObjects!.count)
            searchBar.placeholder = "Showing \(count) Favorites"
            if self.fetchedResultsController.fetchedObjects?.count == 0 {
                self.noArtistsSavedLabel.text = "No Artists Saved"
                self.noArtistsSavedLabel.alpha = 1
            }
            
            //navigationItem.leftBarButtonItem?.isEnabled = true
            homeTappedBool = false
            self.showSavedButton.title = "Previous"
        }
        
        UIView.animate(withDuration: 0.8, delay: 0, options: .transitionCurlUp , animations: {
            if self.showSavedBool {
                self.fetchAllArtists()
                //                if self.allArtists.count == 0 {
                //                    if self.collectionView.alpha == 0 {
                //                        self.collectionView.alpha = 1
                //                        self.noArtistsSavedLabel.alpha = 0
                //                    }
                //                    self.viewDidLoad()
                //                }
                self.showSavedBool = false
                // self.showSavedButton.title = "Show Saved"
            }else{
                self.fetchAllArtists()
                
                if self.fetchedResultsController.fetchedObjects?.count == 0 {
                    self.noArtistsSavedLabel.alpha = 1
                }else{
                    self.collectionView?.setContentOffset(CGPoint.zero, animated: false)
                }
                
                self.showSavedBool = true
                // self.showSavedButton.title = "Show Latest"
            }
            self.collectionView.reloadData()
        }) { (success) in
            
        }
        if allArtists.count < 40 {
            navigationItem.leftBarButtonItem?.isEnabled = true
        }else{
            navigationItem.leftBarButtonItem?.isEnabled = false
        }
        if allArtists.count == 0 {
            if !showSavedBool{
                self.noArtistsSavedLabel.text = "No Artists Found"
            }
            noArtistsSavedLabel.alpha = 1
        }
        
    }
    
    fileprivate func fetchAllArtists() {
        let fetchRequest:NSFetchRequest<Artists> = Artists.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //var searchAsked = true
        if prevFetch {
            let words = searchStringFav.components(separatedBy: " ")
            var predicateArray = [NSPredicate]()
            for word in words {
                let predicate = NSPredicate(format: "(name contains[cd] %@)", word)
                predicateArray.append(predicate)
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:predicateArray)
            //searchAsked = false
        }
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? fetchedResultsController.performFetch()
        
    }
    
    
    @objc func visibleCollectionViewCellsReload(){
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    
    @objc func setupFlowLayout(){
        let iPad = (UIDevice.current.userInterfaceIdiom == .pad) || (UIDevice.current.userInterfaceIdiom == .unspecified)
        let faceUp = (UIDevice.current.orientation == .faceDown)
        if iPad /*&& !faceUp*/{
//            if(UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
//                
//                let space:CGFloat = 4.0
//                let dimension = (view.frame.size.width) / 3.0
//                let dimenHeight = (view.frame.size.height) / 2.5
//                flowLayout.minimumInteritemSpacing = 0
//                flowLayout.minimumLineSpacing = 0
//                flowLayout.itemSize = CGSize(width: dimension, height: dimenHeight)
//            }else if(UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown) {
//                
//                
//                let space:CGFloat = 3.0
//                let dimension = (UIScreen.main.bounds.width) / 3.0
//                let dimenHeight = (UIScreen.main.bounds.height) / 4
//                flowLayout.minimumInteritemSpacing = 0
//                flowLayout.minimumLineSpacing = 0
//                flowLayout.itemSize = CGSize(width: dimension, height: dimenHeight)
//            }
            
        }else{
            if(UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
                let space:CGFloat = 3.0
                let dimension = (view.frame.size.width - (2 * space)) / 3.0
                
                flowLayout.minimumInteritemSpacing = space
                flowLayout.minimumLineSpacing = space
                flowLayout.itemSize = CGSize(width: dimension, height: dimension*1.6)
            }else if(UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown){
                let space:CGFloat = 3.0
                let dimension = (view.frame.size.width - (2 * space)) / 2.0
                
                flowLayout.minimumInteritemSpacing = space
                flowLayout.minimumLineSpacing = space
                flowLayout.itemSize = CGSize(width: dimension, height: dimension*1.60)
            }
            
        }
    }
    
}
extension MainViewController{
    //---- CollectionView Delegates
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showSavedBool{
            return (fetchedResultsController.fetchedObjects?.count)!
        }else{
            return allArtists.count
            
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Artist", for: indexPath) as! ArtistListCell
        
        if showSavedBool{
            let currentArtist = fetchedResultsController.fetchedObjects![indexPath.row]
            imageData = currentArtist.image
            artistName = currentArtist.name
            performSegue(withIdentifier: "artistDetail", sender: cell)
        }else{
            let key = Array(allArtists.keys)[indexPath.row]
            let array = allArtists[key]
            
            if let imageFromCache = imageCache.object(forKey: array as AnyObject) as? UIImage {
                imageData = UIImageJPEGRepresentation(imageFromCache, 1)
                artistName = key
                self.mainLoadingIndicator.startAnimating()
                collectionView.isUserInteractionEnabled = false
                DispatchQueue.global(qos: .userInitiated).async {
                    if self.allUrlsLastFm.count != 0 {
                        self.sendUrl = self.allUrlsLastFm[self.artistName]!
                        artistDataDownload(artist: self.artistName, completionHadler: { (success, artist, notAble) in
                            
                            if !success {
                                let alert = UIAlertController(title: "title", message: "message", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action) in
                                    alert.dismiss(animated: true, completion: nil)
                                }))
                                alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: {(action) in
                                    alert.dismiss(animated: true, completion: nil)
                                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                                }))
                                
                                self.present(alert, animated: true, completion: nil)
                                DispatchQueue.main.async {
                                    self.collectionView.isUserInteractionEnabled = true
                                    self.mainLoadingIndicator.stopAnimating()
                                }
                                return
                            }
                            if notAble{
                                self.showAlertUnableToFetch(title: "Unable to fetch", message: "Would you like to see details on Last.fm webpage ?")
                                DispatchQueue.main.async {
                                    self.collectionView.isUserInteractionEnabled = true
                                    self.mainLoadingIndicator.stopAnimating()
                                }
                                return
                            }
                            if success{
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "artistDetail", sender: cell)
                                }
                            }
                            DispatchQueue.main.async {
                                self.collectionView.isUserInteractionEnabled = true
                                self.mainLoadingIndicator.stopAnimating()
                            }
                            
                        })
                    }else{
                        
                        artistDataDownload(artist: self.artistName, completionHadler: { (success, artist, notAble) in
                            if !success {
                                let alert = UIAlertController(title: "title", message: "message", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action) in
                                    alert.dismiss(animated: true, completion: nil)
                                }))
                                alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: {(action) in
                                    alert.dismiss(animated: true, completion: nil)
                                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                                }))
                                
                                self.present(alert, animated: true, completion: nil)
                                DispatchQueue.main.async {
                                    self.collectionView.isUserInteractionEnabled = true
                                    self.mainLoadingIndicator.stopAnimating()
                                }
                                return
                            }
                            if notAble{
                                self.showAlertUnableToFetch(title: "Unable to fetch", message: "Would you like to see details on Last.fm webpage ?")
                                DispatchQueue.main.async {
                                    self.collectionView.isUserInteractionEnabled = true
                                    self.mainLoadingIndicator.stopAnimating()
                                }
                                return
                            }
                            if success{
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "artistDetail", sender: cell)
                                }
                            }
                            DispatchQueue.main.async {
                                self.collectionView.isUserInteractionEnabled = true
                                self.mainLoadingIndicator.stopAnimating()
                            }
                        })
                    }
                }
            }else{
                cell.isUserInteractionEnabled = true
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //Can implement to download a chunk of images
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Artist", for: indexPath) as! ArtistListCell
        cell.isUserInteractionEnabled = true
        
        if showSavedBool{
            do {
                if (fetchedResultsController.fetchedObjects![indexPath.row].image != nil){
                    cell.artistImage.image = UIImage(data:fetchedResultsController.fetchedObjects![indexPath.row].image!)
                }
                cell.artistName.text = fetchedResultsController.fetchedObjects![indexPath.row].name
            }catch{
                fatalError(error.localizedDescription)
            }
            cell.loadingIndicator.stopAnimating()
        }else{
            
            cell.loadingIndicator.startAnimating()
            cell.prepareForReuse()
            let key = Array(allArtists.keys)[indexPath.row]
            let array = allArtists[key]
            imageURLString = array
            cell.artistName.text = key as String
            if let imageFromCache = imageCache.object(forKey: array as AnyObject) as? UIImage {
                cell.artistImage.image = imageFromCache
                cell.loadingIndicator.stopAnimating()
                return cell
            }
            else{
                DispatchQueue.global(qos: .userInitiated).async {
                    imageDownload(imageUrl: array as! String, completionHandler: { (success, data) in
                        if success{
                            if let imgaeToCache = UIImage(data: data){
                                DispatchQueue.main.async {
                                    if self.imageURLString == array {
                                        cell.artistImage.image = imgaeToCache
                                    }
                                    cell.loadingIndicator.stopAnimating()
                                    self.imageCache.setObject(imgaeToCache, forKey: array as AnyObject)
                                    if !self.showSavedBool{
                                        if indexPath.row < self.allArtists.count{
                                            collectionView.reloadItems(at: [indexPath])
                                        }
                                    }
                                }
                                
                            }
                        }else{
                            DispatchQueue.main.async {
                                cell.loadingIndicator.stopAnimating()
                                cell.artistImage.image = #imageLiteral(resourceName: "no_network")
                                cell.artistImage.backgroundColor = UIColor.white
                                self.showAlert(title: "Unable to Fetch Data", message: "Please Choose")
                                cell.isUserInteractionEnabled = false
                            }
                            
                        }
                        
                    })
                    
                    
                }
                
            }
        }
        
        return cell
    }
    
}

extension MainViewController{
    
    //--- Other Functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "artistDetail"{
            if let detailController = segue.destination as? ArtistDetailViewController{
                detailController.artistName = artistName
                detailController.imageData = imageData
                detailController.dataController = dataController
                if allUrlsLastFm.count != 0 {
                    //detailController.artistUrlFromMain = sendUrl
                }
            }
        }
    }
    
    func showAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
            self.mainLoadingIndicator.startAnimating()
            self.viewDidLoad()
            
        }))
        alert.addAction(UIAlertAction(title: "View Saved", style: UIAlertActionStyle.default, handler: {(action) in
            if !self.showSavedBool{
                self.showSavedButtonTapped(self)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    func showAlertUnableToFetch(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "View Online", style: UIAlertActionStyle.default, handler: {(action) in
            if self.sendUrl != nil && UIApplication.shared.canOpenURL(URL(string:self.sendUrl)!) {
                UIApplication.shared.open(URL(string:self.sendUrl)!, options: [:], completionHandler: { (sucess) in
                    
                })
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

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
    @IBAction func homeButtonTapped(_ sender: Any) {
        collectionView?.setContentOffset(CGPoint.zero, animated: false)
        collectionView.isScrollEnabled = false
     
        imageCache = NSCache<AnyObject, AnyObject>()
        DispatchQueue.main.suspend()
        DispatchQueue.global(qos: .userInitiated).suspend()
        collectionView.delegate = nil
        collectionView.dataSource = nil
      
    
        imageCache = NSCache<AnyObject, AnyObject>()
        allArtists = [String:String]()
        allUrlsLastFm = [String:String]()
 
        collectionView.delegate = self
        collectionView.dataSource = self
        self.viewDidLoad()
        collectionView.isScrollEnabled = true

    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "Example"
        return cell
    }
    
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
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
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
        
    }
    
    @IBAction func showSavedButtonTapped(_ sender: Any) {
        if showSavedBool {
            fetchAllArtists()
            if allArtists.count == 0 {
                viewDidLoad()
            }
            noArtistsSavedLabel.alpha = 0
            showSavedBool = false
            showSavedButton.title = "Show Saved"
        }else{
            fetchAllArtists()
            for d in fetchedResultsController.fetchedObjects! {
                if d.name == nil {
                    dataController.viewContext.delete(d)
                    try? dataController.viewContext.save()
                }
            }
            if fetchedResultsController.fetchedObjects?.count == 0 {
                noArtistsSavedLabel.alpha = 1
            }else{
                collectionView.scrollToItem(at: [0,1], at: .top, animated: false)
            }
            
            showSavedBool = true
            showSavedButton.title = "Show Latest"
        }
        collectionView.reloadData()
    }
    
    @IBOutlet weak var showSavedButton: UIBarButtonItem!
    fileprivate func fetchAllArtists() {
        let fetchRequest:NSFetchRequest<Artists> = Artists.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? fetchedResultsController.performFetch()
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    @objc func visibleCollectionViewCellsReload(){
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
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
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.count != 0 {
            collectionView?.setContentOffset(CGPoint.zero, animated: false)
            let q = searchBar.text!
            DispatchQueue.global(qos: .userInitiated).async {
                var search = searchArtists(search: q, completionHandler: {success, res , lastFmUrl in
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
                            self.collectionView.alpha = 1
                            self.collectionView.reloadData()
                        }
                    }
                })
                
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        allUrlsLastFm = [String:String]()
        //        allArtists = [String:String]()
        searchTableView.alpha = 0
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.bounces = false
        NotificationCenter.default.addObserver(self, selector: #selector(setupFlowLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(visibleCollectionViewCellsReload), name: .UIApplicationDidBecomeActive, object: nil)
        searchBar.delegate = self
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
                
            }
        }
        
    }
    
    
    
    @objc func setupFlowLayout(){ 
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
extension MainViewController{
    
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
            var currentArtist = fetchedResultsController.fetchedObjects![indexPath.row]
            imageData = currentArtist.image
            artistName = currentArtist.name
            performSegue(withIdentifier: "artistDetail", sender: cell)
        }else{
            let key = Array(allArtists.keys)[indexPath.row]
            let array = allArtists[key]
            
            if let imageFromCache = imageCache.object(forKey: array as AnyObject) as? UIImage {
                imageData = UIImageJPEGRepresentation(imageFromCache, 1)
                artistName = key as! String
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
                                    print(self.artistName)
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
            self.showSavedButtonTapped(self)
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

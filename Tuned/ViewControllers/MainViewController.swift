//
//  ViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mainLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noArtistsSavedLabel: UILabel!
    var allArtists = [String:String]()
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    var artistName:String!
    var allImageData = [IndexPath:Data]()
    var imageData:Data!
    var dataController:DataController!
    let imageCache = NSCache<AnyObject, AnyObject>()
    var imageURLString : String?
    var showSavedBool: Bool = false
    var fetchedResultsController:NSFetchedResultsController<Artists>!
    
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
            if fetchedResultsController.fetchedObjects?.count == 0 {
                noArtistsSavedLabel.alpha = 1
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
    override func viewWillAppear(_ animated: Bool) {
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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupFlowLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
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
                cell.isUserInteractionEnabled = true
                imageData = UIImageJPEGRepresentation(imageFromCache, 1)
                artistName = key as! String
                performSegue(withIdentifier: "artistDetail", sender: cell)
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
                cell.artistImage.image = UIImage(data:fetchedResultsController.fetchedObjects![indexPath.row].image!)
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
                                    if !self.showSavedBool{collectionView.reloadItems(at: [indexPath])}
                                    
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
    
    
}

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
            showSavedBool = false
            showSavedButton.title = "Show Saved"
        }else{
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
        fetchAllArtists()
        if !showSavedBool{
            if collectionView != nil {
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            }}else{
            collectionView.reloadData()
        }
        
        
        self.setupFlowLayout()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupFlowLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        DispatchQueue.global(qos: .userInitiated).async {
            getTopArtists { ab in
                self.allArtists = ab
                DispatchQueue.main.async {
                    self.collectionView.delegate = self
                    self.collectionView.dataSource = self
                    //self.collectionView.decelerationRate = 0.3
                    self.collectionView.reloadData()
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
                                    collectionView.reloadItems(at: [indexPath])
                                }
                                
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
    
}

//
//  ViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import UIKit

class MainViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    var allArtists = [String:String]()
    var allImages = [Data]()
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    var artistName:String!
    var imageData:Data!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        return allArtists.count
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Artist", for: indexPath) as! ArtistListCell
        let key = Array(allArtists.keys)[indexPath.row]
        imageData = allImages[indexPath.row]
        let array = allArtists[key]
        artistName = key as! String
        performSegue(withIdentifier: "artistDetail", sender: cell)
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Artist", for: indexPath) as! ArtistListCell
        cell.artistImage.image = nil
        let key = Array(allArtists.keys)[indexPath.row]
        let array = allArtists[key]
        if allImages.count > indexPath.row{
            cell.artistImage.image = UIImage(data:allImages[indexPath.row])
            cell.loadingIndicator.stopAnimating()
            cell.artistName.text = key as String
        }else{
            DispatchQueue.global(qos: .userInitiated).async {
                imageDownload(imageUrl: array as! String, completionHandler: { (success, data) in
                    if success{
                        self.allImages.append(data)
                        DispatchQueue.main.async {
                            cell.artistImage.image = UIImage(data:data)
                            cell.loadingIndicator.stopAnimating()
                            cell.artistName.text = key as String
                            
                        }
                    }
                })
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
            }
        }
    }
}

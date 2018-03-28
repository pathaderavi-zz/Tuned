//
//  ViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    var allArtists = [String:String]()
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(setupFlowLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        getTopArtists { ab in
            self.allArtists = ab
            DispatchQueue.main.async {
                self.collectionView.delegate = self
                self.collectionView.dataSource = self
                self.collectionView.reloadData()
                
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
        }else{
            let space:CGFloat = 3.0
            let dimension = (view.frame.size.width - (2 * space)) / 2.0
            
            flowLayout.minimumInteritemSpacing = space
            flowLayout.minimumLineSpacing = space
            flowLayout.itemSize = CGSize(width: dimension, height: dimension*1.60)
        }
    
    }

}
extension ViewController{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(allArtists.count)
        return allArtists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Artist", for: indexPath) as! ArtistListCell
        let key = Array(allArtists.keys)[indexPath.row]
        let array = allArtists[key]
        DispatchQueue.global(qos: .userInitiated).async {
            imageDownload(imageUrl: array as! String, completionHandler: { (success, data) in
                if success{
                    DispatchQueue.main.async {
                        cell.artistImage.image = UIImage(data:data)
                        cell.artistName.text = key as String
                    }
                }
            })
        }
        return cell
    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let padding: CGFloat =  0
//        let collectionViewSize = collectionView.frame.size.width - padding
//
//        return CGSize(width: collectionView.frame.size.width/3.2, height: 100)
//    }
}

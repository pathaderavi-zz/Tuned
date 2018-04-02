//
//  ArtistListCell.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/27/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

class ArtistListCell:UICollectionViewCell{
    @IBOutlet weak var artistImage: UIImageView!
    @IBOutlet weak var artistName: UILabel!
    //ADD Loading indicator
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    override func prepareForReuse() {
        super.prepareForReuse()
        loadingIndicator.startAnimating()
        artistImage.image = #imageLiteral(resourceName: "placeholder")
        artistName.text = ""
    }
}

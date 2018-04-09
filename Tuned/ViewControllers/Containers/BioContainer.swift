//
//  BioContainer.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 3/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit

class BioContainer:UIViewController{
    @IBOutlet weak var bioLabel: UILabel!
    var bioLabelText:String!
    @IBOutlet weak var bioLabelTextView: UITextView!
    var lastFmUrl:NSMutableAttributedString!
    override func viewDidLoad() {
      
        bioLabelTextView.isEditable = false
        bioLabelTextView.dataDetectorTypes = .link
        bioLabelTextView.isSelectable = true
        bioLabelTextView.text = bioLabelText
        //bioLabelTextView.attributedText = lastFmUrl
        print(lastFmUrl)
    }
    
}

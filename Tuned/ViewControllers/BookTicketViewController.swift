//
//  BookTicketViewController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 4/29/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class BookTicketViewController : UIViewController,WKNavigationDelegate{
    var eventUrl:String!
    
    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //webView = WKWebView()
//        self.view.addSubview(self.webView)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        let url = URL(string:eventUrl)
        let request = URLRequest(url:url!)
        
        webView.load(request)
    }
  

}

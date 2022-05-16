//
//  PrivacyPolicyViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/16.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController {
    @IBOutlet weak var NavBar: UINavigationBar!
    @IBOutlet weak var webView: WKWebView!
    
    var url = URL(string: "https://tjlabscorp.tistory.com/3")!
//    var url = URL(string: "https://tjlabs.notion.site/TJLABS-e83ccd3cb45342ffa4426877b146681b")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NavBar.topItem?.title = "개인정보처리방침"
        NavBar.tintColor = UIColor.white
        
        let bbiDone = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(bbiDonelTapped))
        bbiDone.tintColor = UIColor.red
        
        NavBar.topItem?.rightBarButtonItem = bbiDone
        
        let request = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
        webView.load(request)
    }
    
    @objc func bbiDonelTapped(_ sender: UIButton?) {
        self.dismiss(animated: true, completion: nil)
    }
}

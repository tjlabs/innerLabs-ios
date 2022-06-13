//
//  GalleryViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/06/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

protocol GalleryViewPageDelegate {
    func sendPage(data: Int)
}

class GalleryViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
//    var url = URL(string: "https://tjlabs.notion.site/Inner-Labs-62a2233766be4bc6899d101484b360b8")!
//    var url = URL(string: "https://tjlabscorp.com")!
    var url = URL(string: "https://tjlabscorp.tistory.com/3")!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var delegate : GalleryViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setCardData(cardData: cardData!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
        webView.load(request)
        
        self.webView.navigationDelegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.alwaysBounceVertical = false
        self.webView.scrollView.bounces = false
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print(scrollView.contentOffset.y)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        print("WebView is loaded")
        scrollToBottom()
    }
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
        print(self.webView.scrollView.contentSize.height)
        print(self.webView.scrollView.bounds.height)
        print(self.webView.scrollView.contentInset.bottom)
        print(bottomOffset)
        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
    }
}

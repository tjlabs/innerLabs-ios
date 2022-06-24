//
//  GalleryViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/06/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import WebKit
import Floaty
import JupiterSDK

protocol GalleryViewPageDelegate {
    func sendPage(data: Int)
}

class GalleryViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    let defaultHeight:Double = 500
    
    var url = URL(string: "https://tjlabscorp.tistory.com/3")!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var delegate : GalleryViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    
    var contentsHeight: CGPoint?
    
    // Floating Button
    let floaty = Floaty()
    
    var sectorDetectionService = ServiceManager()
    
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
        
        setFloatingButton()
        
        sectorDetectionService.startService(service: "mariner1")
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
    }
    
    func setFloatingButton() {
        floaty.buttonColor = .systemGreen
        floaty.plusColor = .black
        floaty.itemButtonColor = .white
        floaty.openAnimationType = .slideLeft
        
        let item = FloatyItem()
        item.buttonColor = .systemYellow
        item.title = "Custom"
        floaty.addItem(item: item)
        
        floaty.addItem("To Bottom", icon: UIImage(named: "showInfoToggle"), handler: { [self] item in
            scrollToBottom()
            floaty.close()
        })
        
        floaty.addItem("To Top", icon: UIImage(named: "closeInfoToggle"), handler: { [self] item in
            scrollToTop()
            floaty.close()
        })
        
//        floaty.addItem("Test", icon: UIImage(named: "showInfoToggle"), handler: { [self] item in
//            let alert = UIAlertController(title: "Wow", message: "It's lunch time", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//            floaty.close()
//        })
        
        self.view.addSubview(floaty)
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition: Double = scrollView.contentOffset.y
        guard let height = contentsHeight else { return }
        imageDisappear(contentsHeight: (height.y/5), scrollPostion: scrollPosition)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        contentsHeight = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
    }
    
    func scrollToTop() {
        self.webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        imageDisappear(contentsHeight: (self.contentsHeight!.y/5), scrollPostion: 0)
    }
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)

        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
        imageDisappear(contentsHeight: (self.contentsHeight!.y/5), scrollPostion: (self.contentsHeight!.y/5))
    }
    
    func imageDisappear(contentsHeight: Double, scrollPostion: Double) {
        var percentage: Double = scrollPostion/contentsHeight
        if (percentage > 1) {
            percentage = 1
        }
        imageHeight.constant = defaultHeight - (defaultHeight*percentage)
    }
}

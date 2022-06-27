//
//  GalleryViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/06/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import WebKit
import Charts
import Floaty
import JupiterSDK

protocol GalleryViewPageDelegate {
    func sendPage(data: Int)
}

class GalleryViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var button3F: UIButton!
    @IBOutlet weak var button4F: UIButton!
    @IBOutlet weak var switchButton: CustomSwitchButton!
    
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    let defaultHeight:Double = 300
    
    var url = URL(string: "https://tjlabscorp.tistory.com/3")!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var delegate : GalleryViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    var RP = [String: [[Double]]]()
    let levels: [String] = ["3F", "4F"]
    
    var contentsHeight: CGPoint?
    
    // Floating Button
    let floaty = Floaty()
    
    var sectorDetectionService = ServiceManager()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        switchButton.delegate = self
        
        setCardData(cardData: cardData!)
//        loadRP()
        
        button3F.layer.shadowOpacity = 0.5
        button3F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button3F.layer.shadowRadius = 4
        
        button4F.layer.shadowOpacity = 0.5
        button4F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button4F.layer.shadowRadius = 4
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
        webView.load(request)
        
        self.webView.navigationDelegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.alwaysBounceVertical = false
        self.webView.scrollView.bounces = false
        
        // Floating Button
//        setFloatingButton()
        
        // Enroll Service
//        sectorDetectionService.startService(service: "mariner1")
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
    }
    
    func loadRP() {
        for idx in 0..<levels.count {
            let nameLevel: String = "Gallery_\(levels[idx])"
            let filePath = Bundle.main.path(forResource: nameLevel, ofType: "csv")!
            let rpXY:[[Double]] = parseRP(url: URL(fileURLWithPath: filePath))
            
            RP[levels[idx]] = rpXY
        }
    }
    
    private func parseRP(url:URL) -> [[Double]] {
        var rpXY = [[Double]]()
        
        var rpX = [Double]()
        var rpY = [Double]()
        
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
            
            if let dataArr = dataEncoded?.components(separatedBy: "\n").map({$0.components(separatedBy: ",")}) {
                for item in dataArr {
                    let rp: [String] = item
                    if (rp.count == 2) {
                        
                        guard let x: Double = Double(rp[0]) else { return [[Double]]() }
                        guard let y: Double = Double(rp[1].components(separatedBy: "\r")[0]) else { return [[Double]]() }
                        
                        rpX.append(x)
                        rpY.append(y)
                    } else {
                        print("Error reading .txt file")
                        return [[Double]]()
                    }
                }
            }
            rpXY = [rpX, rpY]
        } catch {
            print("Error reading .txt file")
        }
        
        return rpXY
    }
    
    private func drawRP(RP_X: [Double], RP_Y: [Double], XY: [Double]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        let values2 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "RP")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.square)
        set1.setColor(UIColor.yellow)
        set1.scatterShapeSize = 4
        
        let set2 = ScatterChartDataSet(entries: values2, label: "User")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(UIColor.systemRed)
        set2.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
//        scatterChart.xAxis.axisMinimum = xMin + limits[0]
//        scatterChart.xAxis.axisMaximum = xMax + limits[1]
//        scatterChart.leftAxis.axisMinimum = yMin + limits[2]
//        scatterChart.leftAxis.axisMaximum = yMax + limits[3]
        
        scatterChart.xAxis.drawGridLinesEnabled = chartFlag
        scatterChart.leftAxis.drawGridLinesEnabled = chartFlag
        scatterChart.rightAxis.drawGridLinesEnabled = chartFlag
        
        scatterChart.xAxis.drawAxisLineEnabled = chartFlag
        scatterChart.leftAxis.drawAxisLineEnabled = chartFlag
        scatterChart.rightAxis.drawAxisLineEnabled = chartFlag
        
        scatterChart.xAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.leftAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.rightAxis.centerAxisLabelsEnabled = chartFlag

        scatterChart.xAxis.drawLabelsEnabled = chartFlag
        scatterChart.leftAxis.drawLabelsEnabled = chartFlag
        scatterChart.rightAxis.drawLabelsEnabled = chartFlag
        
        scatterChart.legend.enabled = chartFlag
        
        scatterChart.backgroundColor = .clear
        
        scatterChart.data = chartData
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
    
    @IBAction func tapButton3F(_ sender: UIButton) {
        imageLevel.image = UIImage(named: "L1_3F")
    }
    
    @IBAction func tapButton4F(_ sender: UIButton) {
        imageLevel.image = UIImage(named: "L8_B1")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition: Double = scrollView.contentOffset.y
//        guard let height = contentsHeight else { return }
//        imageDisappear(contentsHeight: (height.y/5), scrollPostion: scrollPosition)
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

extension GalleryViewController: CustomSwitchButtonDelegate {
    func isOnValueChange(isOn: Bool) {
//        label.text = "\(isOn)"
    }
}

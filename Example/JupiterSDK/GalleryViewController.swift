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
    
    let defaultHeight:Double = 250
    
    var url3F = URL(string: "https://tjlabscorp.tistory.com/3")!
    var url4F = URL(string: "https://www.admgallery.co.kr/individual-island")!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var delegate : GalleryViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    var runMode: String = "PDR"
    var RP = [String: [[Double]]]()
    var modeAuto: Bool = false
    let levels: [String] = ["3F", "4F"]
    var currentLevel: String = "3F"
    
    var contentsHeight: CGPoint?
    
    var pastTime: Double = 0
    var timer : Timer?
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    let jupiterService = JupiterService()
    
    // Floating Button
    let floaty = Floaty()
    
    var sectorDetectionService = ServiceManager()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        switchButton.delegate = self
        
        setCardData(cardData: cardData!)
        loadRP()
        
        let rp: [[Double]] = RP["3F"] ?? [[Double]]()
        if (rp.isEmpty) {
            scatterChart.alpha = 0
        } else {
            scatterChart.alpha = 1.0
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [0, 0])
        }
        
        button3F.showsTouchWhenHighlighted = true
        button3F.layer.shadowOpacity = 0.5
        button3F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button3F.layer.shadowRadius = 4
        
        button4F.showsTouchWhenHighlighted = true
        button4F.layer.shadowOpacity = 0.5
        button4F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button4F.layer.shadowRadius = 4
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadWebView(currentLevel: self.currentLevel)
        
        if (cardData!.mode == 1 || cardData!.mode == 2) {
            runMode = "PDR"
        } else {
            runMode = "DR"
        }
        
        jupiterService.uuid = uuid
        jupiterService.mode = runMode
        jupiterService.startService(parent: self)
        
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
                    }
                }
            }
            rpXY = [rpX, rpY]
        } catch {
            print("Error reading .csv file")
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
        set1.scatterShapeSize = 8
        
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
        if (currentLevel == "3F") {
//            scatterChart.xAxis.axisMinimum = xMin - 2.8
//            scatterChart.xAxis.axisMaximum = xMax + 0.2
//            scatterChart.leftAxis.axisMinimum = yMin - 5
//            scatterChart.leftAxis.axisMaximum = yMax + 3

            scatterChart.xAxis.axisMinimum = xMin - 1
            scatterChart.xAxis.axisMaximum = xMax + 1
            scatterChart.leftAxis.axisMinimum = yMin - 1
            scatterChart.leftAxis.axisMaximum = yMax + 1
        } else if (currentLevel == "4F") {
            scatterChart.xAxis.axisMinimum = xMin - 3.5
            scatterChart.xAxis.axisMaximum = xMax + 1
            scatterChart.leftAxis.axisMinimum = yMin - 1
            scatterChart.leftAxis.axisMaximum = yMax + 1
        }
        
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
        currentLevel = "3F"
        imageLevel.image = UIImage(named: "Gallery_3F")
        
        let rp: [[Double]] = RP["3F"] ?? [[Double]]()
        if (rp.isEmpty) {
            scatterChart.alpha = 0
        } else {
            scatterChart.alpha = 1.0
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [0, 0])
        }
        
        loadWebView(currentLevel: currentLevel)
    }
    
    @IBAction func tapButton4F(_ sender: UIButton) {
        currentLevel = "4F"
        imageLevel.image = UIImage(named: "Gallery_4F")
        
        let rp: [[Double]] = RP["4F"] ?? [[Double]]()
        if (rp.isEmpty) {
            scatterChart.alpha = 0
        } else {
            scatterChart.alpha = 1.0
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [0, 0])
        }
        
        loadWebView(currentLevel: currentLevel)
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    // Display Outputs
    func startTimer() {
        if (timer == nil) {
            timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
    }
    
    @objc func timerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        print("Time Stamp :", timeStamp)
        
        // length, scc, status, mode, idx Tx, idx Rx, level
        let isStepDetected = jupiterService.unitDRInfo.isIndexChanged
        
        let unitIdxTx = Int(jupiterService.unitDRInfo.index)
        let unitLength = jupiterService.unitDistane
        let status = jupiterService.unitDRInfo.lookingFlag
        
        if (isStepDetected) {
            let buildingName: String = jupiterService.jupiterOutput.building
            let buildingLevels: [String] = cardData!.infoLevel[buildingName] ?? []
            
            if (!buildingLevels.isEmpty) {
                let x = jupiterService.jupiterOutput.x
                let y = jupiterService.jupiterOutput.y
                
                let unitIdxRx = jupiterService.jupiterOutput.index
                let scc = jupiterService.jupiterOutput.scc
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition: Double = scrollView.contentOffset.y
//        guard let height = contentsHeight else { return }
//        imageDisappear(contentsHeight: (height.y/5), scrollPostion: scrollPosition)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        contentsHeight = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
    }
    
    func loadWebView(currentLevel: String) {
        if (currentLevel == "3F") {
            let request = URLRequest.init(url: url3F, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
            webView.load(request)
        } else {
            let request = URLRequest.init(url: url4F, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
            webView.load(request)
        }
        
        self.webView.navigationDelegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.alwaysBounceVertical = false
        self.webView.scrollView.bounces = false
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
        if (isOn) {
            startTimer()
        } else {
            stopTimer()
        }
    }
}

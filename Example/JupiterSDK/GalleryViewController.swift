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
    
    let defaultHeight:Double = 320
    
    var url3F = URL(string: "https://www.admgallery.co.kr/gallery")!
//    var url4F = URL(string: "https://www.admgallery.co.kr/there-is-water-inside")!
    var url4F = URL(string: "https://tjlabscorp.tistory.com/4?category=1063691")!
//    var url4F = URL(string: "https://tjlabs.notion.site/THERE-IS-WATER-INSIDE-a04acc19e6224b67a81f82fedb7888eb")!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var delegate : GalleryViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    var runMode: String = "pdr"
    
    var RP = [String: [[Double]]]()
    var Road = [[Double]]()
    var roadLength: Int = 0
    
    var modeAuto: Bool = false
    let levels: [String] = ["3F", "4F"]
    var currentLevel: String = "3F"
    
    var contentsHeight: CGPoint?
    
    var pastTime: Double = 0
    var timer : Timer?
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
//    let jupiterService = JupiterService()
    var levelBuffer = [String]()
    var isChanged: Bool = false
    
    var countStop: Int = 0
    
    // Floating Button
    let floaty = Floaty()
    
    let initPos: [Double] = [20, 17]
    var posX: Double = 20
    var posY: Double = 17
    var posH: Double = 0
    
    var pastX: Double = 20
    var pastY: Double = 17
    
    // Contents Position Center
//    let Number1: [[Double]] = [[10], [14]]
//    let Number2: [[Double]] = [[6], [13]]
//    let Number3: [[Double]] = [[9], [10]]
//    let Number4: [[Double]] = [[6], [6]]
//    let Number5: [[Double]] = [[14], [11]]
//    let Number6: [[Double]] = [[14], [7]]
//    let Number7: [[Double]] = [[19], [6]]
//    let Number8: [[Double]] = [[20], [11]]
//    let NumberArray: [[Double]] = [[10, 6, 9, 6, 14, 14, 19, 20], [14, 13, 10, 6, 12, 7, 6, 11]]
    
    // Contents
    let Number1: [[Double]] = [[8,8,8,9,9,9,10,10,10,8,9,10], [13,14,15,13,14,15,13,14,15,16,16,16]]
    let Number2: [[Double]] = [[5,5,6,6,7,7,5,6,7], [13,14,13,14,13,14,15,15,15]]
    let Number3: [[Double]] = [[6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9], [9,10,11,12,9,10,11,12,9,10,11,12,9,10,11,12]]
    let Number4: [[Double]] = [[5,5,5,6,6,6,7,7,7,5,6,7], [5,6,7,5,6,7,5,6,7,8,8,8]]
    let Number5: [[Double]] = [[11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15], [10,11,12,13,10,11,12,13,10,11,12,13,10,11,12,13,10,11,12,13]]
    let Number6: [[Double]] = [[13,13,13,14,14,14,15,15,15], [6,7,8,6,7,8,6,7,8]]
    let Number7: [[Double]] = [[17,17,17,18,18,18,19,19,19,20,20,20], [5,6,7,5,6,7,5,6,7,5,6,7]]
    let Number8: [[Double]] = [[17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,21,21,21,21], [10,11,12,13,10,11,12,13,10,11,12,13,10,11,12,13,10,11,12,13]]
    
    let contentsMinMax: [[Double]] = [[8,10,13,16], [5,7,13,15], [6,9,9,12], [5,7,5,8],
                                      [11,15,10,13], [13,15,6,8], [17,20,5,7], [17,21,10,13]]
//    let contentsMinMax: [[Double]] = [[8,10,13,16], [5,9,9,15], [6,9,9,12], [5,7,5,8],
//                                      [12,15,10,12], [13,15,6,8], [17,20,5,7], [18,21,10,13]]
    let contetnsScroll: [Double] = [1755, 3054, 3957, 5526, 6228, 7016, 8215, 9408]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        switchButton.delegate = self
        
        setCardData(cardData: cardData!)
        loadRP()
        
        button3F.showsTouchWhenHighlighted = true
        button3F.layer.shadowOpacity = 0.5
        button3F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button3F.layer.shadowRadius = 4
        
        button4F.showsTouchWhenHighlighted = true
        button4F.layer.shadowOpacity = 0.5
        button4F.layer.shadowOffset = CGSize(width: 5, height: 5)
        button4F.layer.shadowRadius = 4
        
        changeFloorMap(level: currentLevel)
        scatterChart.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runMode = cardData!.mode
        
        loadWebView(currentLevel: self.currentLevel)
        
//        jupiterService.uuid = uuid
//        jupiterService.mode = runMode
//        jupiterService.startService(parent: self)
        
        // Floating Button
        setFloatingButton()
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
            
            if (nameLevel == "Gallery_4F") {
                let fileRoad = Bundle.main.path(forResource: "Gallery_4F_Road", ofType: "csv")!
                let roadXY:[[Double]] = parseRP(url: URL(fileURLWithPath: fileRoad))
                
                Road = roadXY
                roadLength = Road[0].count
            }
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
    
    private func drawRoad(RP_X: [Double], RP_Y: [Double], Road_X: [Double], Road_Y: [Double]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        let xRoadValue: [Double] = Road_X
        let yRoadValue: [Double] = Road_Y
        
//        let sliceX = Road_X[1..<2]
//        let sliceY = Road_Y[1..<2]
//
//        let xRoadValue: [Double] = Array(sliceX)
//        let yRoadValue: [Double] = Array(sliceY)
//
//        let xRoadValue: [Double] = Number8[0]
//        let yRoadValue: [Double] = Number8[1]
        
//        print(xRoadValue[0], ",", yRoadValue[0])
        
        let values2 = (0..<xRoadValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xRoadValue[i], y: yRoadValue[i])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "RP")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.square)
        set1.setColor(UIColor.yellow)
        set1.scatterShapeSize = 8
        
        let set2 = ScatterChartDataSet(entries: values2, label: "Road")
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
        scatterChart.xAxis.axisMinimum = xMin - 3.5
        scatterChart.xAxis.axisMaximum = xMax + 1
        scatterChart.leftAxis.axisMinimum = yMin - 1
        scatterChart.leftAxis.axisMaximum = yMax + 1
        
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
    
    private func drawContents(RP_X: [Double], RP_Y: [Double], no1: [[Double]], no2: [[Double]], no3: [[Double]], no4: [[Double]], no5: [[Double]], no6: [[Double]], no7: [[Double]], no8: [[Double]], XY: [Double] ) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        let xNo1: [Double] = no1[0]
        let yNo1: [Double] = no1[1]
        let contents1 = (0..<xNo1.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo1[i], y: yNo1[i])
        }
        
        let xNo2: [Double] = no2[0]
        let yNo2: [Double] = no2[1]
        let contents2 = (0..<xNo2.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo2[i], y: yNo2[i])
        }
        
        let xNo3: [Double] = no3[0]
        let yNo3: [Double] = no3[1]
        let contents3 = (0..<xNo3.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo3[i], y: yNo3[i])
        }
        
        let xNo4: [Double] = no4[0]
        let yNo4: [Double] = no4[1]
        let contents4 = (0..<xNo4.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo4[i], y: yNo4[i])
        }
        
        let xNo5: [Double] = no5[0]
        let yNo5: [Double] = no5[1]
        let contents5 = (0..<xNo5.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo5[i], y: yNo5[i])
        }
        
        let xNo6: [Double] = no6[0]
        let yNo6: [Double] = no6[1]
        let contents6 = (0..<xNo6.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo6[i], y: yNo6[i])
        }
        
        let xNo7: [Double] = no7[0]
        let yNo7: [Double] = no7[1]
        let contents7 = (0..<xNo7.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo7[i], y: yNo7[i])
        }
        
        let xNo8: [Double] = no8[0]
        let yNo8: [Double] = no8[1]
        let contents8 = (0..<xNo8.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xNo8[i], y: yNo8[i])
        }
        
        
        
        let set0 = ScatterChartDataSet(entries: values1, label: "RP")
        set0.drawValuesEnabled = false
        set0.setScatterShape(.square)
        set0.setColor(UIColor.yellow)
        set0.scatterShapeSize = 8
        
        let set1 = ScatterChartDataSet(entries: contents1, label: "Road")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.circle)
        set1.setColor(UIColor.black)
        set1.scatterShapeSize = 16
        
        let set2 = ScatterChartDataSet(entries: contents2, label: "Road")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(UIColor.black)
        set2.scatterShapeSize = 16
        
        let set3 = ScatterChartDataSet(entries: contents3, label: "Road")
        set3.drawValuesEnabled = false
        set3.setScatterShape(.circle)
        set3.setColor(UIColor.black)
        set3.scatterShapeSize = 16
        
        let set4 = ScatterChartDataSet(entries: contents4, label: "Road")
        set4.drawValuesEnabled = false
        set4.setScatterShape(.circle)
        set4.setColor(UIColor.black)
        set4.scatterShapeSize = 16
        
        let set5 = ScatterChartDataSet(entries: contents5, label: "Road")
        set5.drawValuesEnabled = false
        set5.setScatterShape(.circle)
        set5.setColor(UIColor.black)
        set5.scatterShapeSize = 16
        
        let set6 = ScatterChartDataSet(entries: contents6, label: "Road")
        set6.drawValuesEnabled = false
        set6.setScatterShape(.circle)
        set6.setColor(UIColor.black)
        set6.scatterShapeSize = 16
        
        let set7 = ScatterChartDataSet(entries: contents7, label: "Road")
        set7.drawValuesEnabled = false
        set7.setScatterShape(.circle)
        set7.setColor(UIColor.black)
        set7.scatterShapeSize = 16
        
        let set8 = ScatterChartDataSet(entries: contents8, label: "Road")
        set8.drawValuesEnabled = false
        set8.setScatterShape(.circle)
        set8.setColor(UIColor.black)
        set8.scatterShapeSize = 16
        
        let values = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let setUser = ScatterChartDataSet(entries: values, label: "User")
        setUser.drawValuesEnabled = false
        setUser.setScatterShape(.circle)
        setUser.setColor(UIColor.systemRed)
        setUser.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: set0)
        chartData.append(set1)
        chartData.append(set2)
        chartData.append(set3)
        chartData.append(set4)
        chartData.append(set5)
        chartData.append(set6)
        chartData.append(set7)
        chartData.append(set8)
        chartData.append(setUser)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
        scatterChart.xAxis.axisMinimum = xMin - 3.5
        scatterChart.xAxis.axisMaximum = xMax + 1
        scatterChart.leftAxis.axisMinimum = yMin - 1
        scatterChart.leftAxis.axisMaximum = yMax + 1
        
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
    
    private func drawUser(RP_X: [Double], RP_Y: [Double], XY: [Double]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y
        
        let values = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let setUser = ScatterChartDataSet(entries: values, label: "User")
        setUser.drawValuesEnabled = false
        setUser.setScatterShape(.circle)
        setUser.setColor(UIColor.systemYellow)
        setUser.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: setUser)
        chartData.setDrawValues(false)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
        if (currentLevel == "3F") {
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
        let colorYellow = UIColor(red: 255/255, green: 246/255, blue: 71/255, alpha: 1.0)
        
        floaty.buttonColor = colorYellow
        floaty.plusColor = .black
//        floaty.itemButtonColor = .white
        floaty.openAnimationType = .slideLeft
        
        let itemToBottom = FloatyItem()
        itemToBottom.buttonColor = colorYellow
        itemToBottom.title = "To Bottom"
//        itemToBottom.titleColor = .black
        itemToBottom.icon = UIImage(named: "arrowDown")
        itemToBottom.handler = { [self] itemToBottom in
            scrollToBottom()
            floaty.close()
        }
        floaty.addItem(item: itemToBottom)
        
        let itemToTop = FloatyItem()
        itemToTop.buttonColor = colorYellow
        itemToTop.title = "To Top"
//        itemToTop.titleColor = .black
        itemToTop.icon = UIImage(named: "arrowUp")
        itemToTop.handler = { [self] itemToTop in
            scrollToTop()
            floaty.close()
        }
        floaty.addItem(item: itemToTop)
        
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

        changeFloorMap(level: currentLevel)
        loadWebView(currentLevel: currentLevel)
    }
    
    @IBAction func tapButton4F(_ sender: UIButton) {
        currentLevel = "4F"
        
        changeFloorMap(level: currentLevel)
        loadWebView(currentLevel: currentLevel)
    }
    
    func changeFloorMap(level: String) {
        if (level == "3F") {
            currentLevel = "3F"
            imageLevel.image = UIImage(named: "Gallery_3F")
            
            let rp: [[Double]] = RP["3F"] ?? [[Double]]()
            if (rp.isEmpty) {
                scatterChart.isHidden = true
            } else {
                scatterChart.isHidden = false
            }
            
            button3FSelected()
        } else if (level == "4F") {
            currentLevel = "4F"
            imageLevel.image = UIImage(named: "Gallery_4F")
            
            let rp: [[Double]] = RP["4F"] ?? [[Double]]()
//            if (rp.isEmpty) {
//                scatterChart.isHidden = true
//            } else {
//                scatterChart.isHidden = false
//            }
//            scatterChart.isHidden = true
            
            button4FSelected()
        }
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
//        let timeStamp = getCurrentTimeInMilliseconds()
//        let dt = timeStamp - pastTime
//        pastTime = timeStamp
//
//        // length, scc, status, mode, idx Tx, idx Rx, level
//        let isStepDetected = jupiterService.unitDRInfo.isIndexChanged
//
//        let unitIdxTx = Int(jupiterService.unitDRInfo.index)
//        let unitLength = jupiterService.unitDistane
//        let status = jupiterService.unitDRInfo.lookingFlag
//        let unitHeading = jupiterService.unitDRInfo.heading-90
//
//        if (isStepDetected) {
//            countStop = 0
//
//            posX = posX + unitLength*cos(unitHeading*(Double.pi/180))
//            posY = posY + unitLength*sin(unitHeading*(Double.pi/180))
//
////            posX = (posX + pastX)/2
////            posY = (posY + pastY)/2
//
//            pastX = posX
//            pastY = posY
//
//            let levelName: String = "4F"
//            let rp: [[Double]] = RP[levelName] ?? [[Double]]()
//
//            scatterChart.isHidden = false
////            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [posX, posY])
//            drawUser(RP_X: rp[0], RP_Y: rp[1], XY: [posX, posY])
////            drawContents(RP_X: rp[0], RP_Y: rp[1], no1: Number1, no2: Number2, no3: Number3, no4: Number4, no5: Number5, no6: Number6, no7: Number7, no8: Number8, XY: [posX, posY])
//
////            let buildingName: String = jupiterService.jupiterOutput.building
////            let buildingLevels: [String] = cardData!.infoLevel[buildingName] ?? []
////            if (!buildingLevels.isEmpty) {
////                let levelName: String = jupiterService.jupiterOutput.level
////
////                levelBuffer.append(levelName)
////                if (levelBuffer.count > 5) {
////                    levelBuffer.removeFirst()
////
////                    isChanged = detectFloorChange(buffer: levelBuffer, level: currentLevel)
////
////                    if (isChanged) {
////                        self.currentLevel = levelName
////                        changeFloorMap(level: currentLevel)
////                        loadWebView(currentLevel: currentLevel)
////
////                        isChanged = false
////                    }
////
////                    let rp: [[Double]] = RP[levelName] ?? [[Double]]()
////                    print("Jupiter Output :", jupiterService.jupiterOutput)
////                    let x = jupiterService.jupiterOutput.x
////                    let y = jupiterService.jupiterOutput.y
////
////                    let unitIdxRx = jupiterService.jupiterOutput.index
////                    let scc = jupiterService.jupiterOutput.scc
////
//////                    drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [x, y])
//////                    drawUser(RP_X: rp[0], RP_Y: rp[1], XY: [x, y])
////
////                    if (levelName == "4F") {
////                        let idx = getNearestRoad(x: x, y: y, road: Road)
////                        if (idx != -1) {
////                            let percentage: Double = Double(idx)/Double(roadLength)
////                            print("Percentage :", percentage)
////                        }
////                    }
////                }
////            }
//        } else {
//            countStop = countStop + 1
//
//            if (countStop > 39) {
//                let index = findNearestContents(X: posX, Y: posY, contents: contentsMinMax)
//                if (index != -1) {
//                    scrollToContents(index: index)
//                }
//                countStop = 0
//            }
//        }
    }
    
    func detectFloorChange(buffer: [String], level: String) -> Bool {
        let levelCount = buffer.filter{$0 == level}.count
        if (levelCount < 3) {
            return true
        }
        
        return false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition: Double = scrollView.contentOffset.y
//        print("Scroll Position :", scrollPosition)
//        guard let height = contentsHeight else { return }
//        imageDisappear(contentsHeight: (height.y/5), scrollPostion: scrollPosition)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        contentsHeight = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
        guard let height = contentsHeight else { return }
        print("Contents Height :", height.y)
        
        if (height.y < 12000) {
            scrollInit()
        }
//        scrollToContents(index: 7)
//        print("Contents Height :", height.y)
//        print("Road Length :", roadLength)
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
//        imageDisappear(contentsHeight: (self.contentsHeight!.y/5), scrollPostion: 0)
    }
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
//        imageDisappear(contentsHeight: (self.contentsHeight!.y/5), scrollPostion: (self.contentsHeight!.y/5))
    }
    
    func findNearestContents(X: Double, Y: Double, contents: [[Double]]) -> Int {
        var contentsNum: Int = -1
        
        for i in 0..<contents.count {
            let xMin: Double = contents[i][0]
            let xMax: Double = contents[i][1]
            let yMin: Double = contents[i][2]
            let yMax: Double = contents[i][3]
            
            if ((X >= xMin) && (X <= xMax)) {
                if ((Y >= yMin) && (Y <= yMax)) {
                    contentsNum = i
                }
            }
        }
        
        return contentsNum
    }
    
    func scrollAuto(percentage: Double) {
        let offset = self.webView.scrollView.contentSize.height * percentage
        let bottomOffset = CGPoint(x: 0, y: offset - self.webView.scrollView.bounds.height + self.webView.scrollView.contentInset.bottom)
        
        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    func scrollInit() {
        let bottomOffset = CGPoint(x: 0, y: 270)
        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    func scrollToContents(index: Int) {
        let scrollPosition: Double = self.contetnsScroll[index]
        let bottomOffset = CGPoint(x: 0, y: scrollPosition)
        self.webView.scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    func imageDisappear(contentsHeight: Double, scrollPostion: Double) {
        var percentage: Double = scrollPostion/contentsHeight
        if (percentage > 1) {
            percentage = 1
        }
        imageHeight.constant = defaultHeight - (defaultHeight*percentage)
    }
    
    func button3FSelected() {
        self.button3F.isUserInteractionEnabled = false
        self.button4F.isUserInteractionEnabled = true
        
        self.button3F.alpha = 1.0
        self.button4F.alpha = 0.5
    }
    
    func button4FSelected() {
        self.button4F.isUserInteractionEnabled = false
        self.button3F.isUserInteractionEnabled = true
        
        self.button4F.alpha = 1.0
        self.button3F.alpha = 0.5
    }
    
    func getNearestRoad(x: Double, y: Double, road: [[Double]]) -> Int {
        let xRoadValue: [Double] = road[0]
        let yRoadValue: [Double] = road[1]
        
        var norm = [Double]()
        for i in 0..<xRoadValue.count {
            let dx: Double = xRoadValue[i] - x
            let dy: Double = yRoadValue[i] - y
            
            norm.append(sqrt(dx*dx + dy*dy))
        }
        
        let minValue = norm.min()
        
        
        guard let minIdx = norm.firstIndex(where: {$0 == minValue}) else { return -1 }
        
        return minIdx
    }
}

extension GalleryViewController: CustomSwitchButtonDelegate {
    func isOnValueChange(isOn: Bool) {
        if (isOn) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [self] in
              // 1초 후 실행될 부분
                startTimer()
                
                currentLevel = "4F"
                
                loadWebView(currentLevel: self.currentLevel)
                changeFloorMap(level: currentLevel)
                
                posX = initPos[0]
                posY = initPos[1]
                
                pastX = initPos[0]
                pastY = initPos[1]
            }
        } else {
            stopTimer()
        }
    }
}

//
//  MapViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/09.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import Charts

protocol PageDelegate {
    func sendPage(data: Int)
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var jupiterTableView: UITableView!
    
    private let tableList: [TableList] = [.sector]
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var jupiterService = JupiterService()
    var uuid: String = ""
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    var delegate : PageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var referencePoints = [[Double]]()
    var rpX = [Double]()
    var rpY = [Double]()
    
    var RP = [String: [[Double]]]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        
        setCardData(cardData: cardData!)
        
        if (cardData?.sectorID == 2) {
            let numLevels: Int = (cardData?.infoLevel.count)!
            for idx in 0..<numLevels {
                if (idx == 0) {
                    loadRP(fileName: "Autoway_RP_B3F")
                } else {
                    loadRP(fileName: "Autoway_RP_B4F")
                }
                let nameLevel: String = (cardData?.infoLevel[idx])!
                RP[nameLevel] = [rpX, rpY]
            }
        }
        
        makeDelegate()
        registerXib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        jupiterService.uuid = uuid
        jupiterService.startService(parent: self)
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.name
        self.cardTopImage.image = UIImage(named: cardData.cardTopImage)!
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    func registerXib() {
        let sectorContainerTVC = UINib(nibName: SectorContainerTableViewCell.identifier, bundle: nil)
        jupiterTableView.register(sectorContainerTVC, forCellReuseIdentifier: SectorContainerTableViewCell.identifier)
    }
    
    func makeDelegate() {
        jupiterTableView.dataSource = self
        jupiterTableView.delegate = self
    }
    
    func setTableView() {
        //테이블 뷰 셀 사이의 회색 선 없애기
        jupiterTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    private func parseCSV(url:URL) {
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
                
            if let dataArr = dataEncoded?.components(separatedBy: "\n").map({$0.components(separatedBy: ",")}) {
                for item in dataArr {
                    let rp: [String] = item
                    if(rp.count == 2) {
                        let x = rp[0]
                        let y = rp[1].components(separatedBy: "\r")
                        
                        rpX.append(Double(x)!)
                        rpY.append(Double(y[0])!)
                    }
                }
            }
        } catch {
            print("Error reading CSV file")
            
        }
    }
    
    private func loadRP(fileName: String) {
        let path = Bundle.main.path(forResource: fileName, ofType: "csv")!
        parseCSV(url: URL(fileURLWithPath: path))
    }
}


extension MapViewController: UITableViewDelegate {
    // 높이 지정 index별
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return jupiterTableView.frame.height
//        return UITableView.automaticDimension
    }
}

extension MapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableList = tableList[indexPath.row]
        
        switch(tableList) {
            
        case .sector:
            guard let sectorContainerTVC = tableView.dequeueReusableCell(withIdentifier: SectorContainerTableViewCell.identifier) as?
                    SectorContainerTableViewCell else {return UITableViewCell()}
            sectorContainerTVC.configure(cardData: cardData!, RP: RP)
            sectorContainerTVC.selectionStyle = .none
            
            return sectorContainerTVC
        }
    }
    
}

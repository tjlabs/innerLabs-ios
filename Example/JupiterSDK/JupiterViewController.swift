import UIKit
import JupiterSDK

enum TableList{
    case sector
}

class JupiterViewController: UIViewController {

    @IBOutlet weak var jupiterTableView: UITableView!
    
    private let tableList: [TableList] = [.sector]
    
    var jupiterService = JupiterService()
    var uuid: String = ""
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var unitCountLabel: UILabel!
    @IBOutlet weak var unitLengthLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
//        print(uuid)
        jupiterService.uuid = uuid
        jupiterService.sector = "TJLABS"
        jupiterService.startService(parent: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        self.navigationItem.hidesBackButton = true
        
        makeDelegate()
        registerXib()
        startTimer()
    }

    @IBAction func tapBackButton(_ sender: UIButton) {
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
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        
        timerCounter = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    @objc func timerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        
        if (dt < 100) {
            elapsedTime += (dt*1e-3)
        }
        self.timeLabel.text = String(format: "%.2f", elapsedTime)
        
        let isStepDetected = jupiterService.stepResult.isStepDetected
        let unitIdx = Int(jupiterService.stepResult.unit_idx)
        let unitLength = jupiterService.stepResult.step_length
        let flag = jupiterService.stepResult.lookingFlag
        
        if (isStepDetected) {
//            print("\(elapsedTime) \\ \(unitIdx) \\ \(unitLength)")
            self.unitCountLabel.text = String(unitIdx)
            self.unitLengthLabel.text = String(format: "%.4f", unitLength)
            self.flagLabel.text = String(flag)
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}

extension JupiterViewController: UITableViewDelegate {
    // 높이 지정 index별
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return jupiterTableView.frame.height
//        return UITableView.automaticDimension
    }
}

extension JupiterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableList = tableList[indexPath.row]
        
        switch(tableList) {
            
        case .sector:
            guard let sectorContainerTVC = tableView.dequeueReusableCell(withIdentifier: SectorContainerTableViewCell.identifier) as?
                    SectorContainerTableViewCell else {return UITableViewCell()}
            sectorContainerTVC.selectionStyle = .none
            return sectorContainerTVC
        }
    }
    
}

import UIKit
import OlympusSDK
import Charts

class Measurements {
    var time: Int = 0

    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0

    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0

    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0

    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0

    var qx: Double = 0
    var qy: Double = 0
    var qz: Double = 0
    var qw: Double = 0

    var pressure: Double = 0

    var ble: String = ""
}

class Trajectory {
    var time: Int = 0
    var index: Int = 0
    var length: Double = 0
    var heading: Double = 0
    var pressure: Double = 0
    var ble: String = ""
}

class CollectViewController: UIViewController {
    @IBOutlet var collectView: UIView!
    
    var serviceManager = OlympusServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var region: String = ""
    var userId: String = ""
    
    var timer: Timer?
    let TIMER_INTERVAL: TimeInterval = 1/40
    
    let data: NSMutableArray  = NSMutableArray()
    
    var saveFlag: Bool = false
    var isWriting: Bool = false
    var deviceModel: String = "Unknown"
    var os: String = "Unknown"
    var osVersion: String = "Unknown"
    
    @IBOutlet weak var fileButton: UIButton!
    
    // Ward Info
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    
    @IBOutlet weak var wardCollectionView: UICollectionView!
    @IBOutlet weak var scatterChart: ScatterChartView!

    
    var x: Double = 0
    var y: Double = 0
    var heading: Double = 0
    var xAxisValue = [Double]()
    var yAxisValue = [Double]()
    
    var headingImage = UIImage(named: "heading")
    
    var wardData = [String: Double]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        osVersion = arr[0]
        
        let width = collectView.frame.size.width
        let height = collectView.frame.size.height
        
        headingImage = headingImage?.resize(newWidth: 40)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        serviceManager.initCollect(region: self.region)
        startTimer()
        
        setupCollectionView()
    }
    
    
    public func setupCollectionView() {
        view.addSubview(wardCollectionView)
        
        wardCollectionView.register(UINib(nibName: "WardCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "WardCollectionViewCell")
        
        wardCollectionView.dataSource = self
        wardCollectionView.delegate = self
        
        self.wardCollectionView.reloadData()
        wardCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        goToBack()
    }
    
    @IBAction func tapStartButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            sender.backgroundColor = .blue3
            isWriting = true
            
            fileButton.isEnabled = false
            startToSave()
        }
        else {
            sender.backgroundColor = .systemGray4
            isWriting = false
            
            fileButton.isEnabled = true
            saveFile()
            goToBack()
        }
    }
    
    @IBAction func tapFileButton(_ sender: UIButton) {
        guard let fileVC = self.storyboard?.instantiateViewController(withIdentifier: "FileViewController") as? FileViewController else { return }
        self.navigationController?.pushViewController(fileVC, animated: true)
    }
    
    func saveFile() {
        serviceManager.stopCollect()
        self.saveFlag = false
        self.stopTimer()
    }
    
    
    func goToBack() {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    func startTimer() {
        if (timer == nil) {
            self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer!, forMode: .common)
        }
    }

    func stopTimer() {
        if (timer != nil) {
            self.timer!.invalidate()
            self.timer = nil
        }
    }
    
    func startToSave() {
        serviceManager.startCollect()
        saveFlag = true
    }

    @objc func timerUpdate() {
        let collectedData = serviceManager.collectData
        let bleAvg: [String: Double] = collectedData.bleAvg
        let sortedBleAvg = bleAvg.sorted { $0.1 > $1.1 }
        
        self.wardData = bleAvg
        self.wardCollectionView.reloadData()
        
        if (saveFlag) {
            if (collectedData.isIndexChanged) {
                let index = collectedData.index
                let length = collectedData.length
                indexLabel.text = String(index)
                lengthLabel.text = String(format: "%.4f", length)
                let currentHeading: Double = collectedData.heading + 90
                
                x += (length * cos(currentHeading*deg2rad))
                y += (length * sin(currentHeading*deg2rad))
                
                xAxisValue.append(x)
                yAxisValue.append(y)
                
                if (xAxisValue.count > 20) {
                    xAxisValue.removeFirst()
                    yAxisValue.removeFirst()
                }

                
                let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
                    return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
                }
                
                // Heading
                let point = scatterChart.getPosition(entry: ChartDataEntry(x: xAxisValue[xAxisValue.count-1], y: yAxisValue[yAxisValue.count-1]), axis: .left)
                let imageView = UIImageView(image: headingImage?.rotate(degrees: -currentHeading + 90))
                imageView.frame = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
                imageView.contentMode = .center
                imageView.tag = 100
                if let viewWithTag = scatterChart.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                }
                scatterChart.addSubview(imageView)
                
                let set1 = ScatterChartDataSet(entries: values1, label: "Trajectory")
                set1.drawValuesEnabled = false
                set1.setScatterShape(.circle)
                set1.setColor(.blue1)
                set1.scatterShapeSize = 12
                
                let chartData = ScatterChartData(dataSet: set1)
                setChartFlag(chartFlag: true)
                
                let xMin = x - 15
                let xMax = x + 15
                let yMin = y - 15
                let yMax = y + 15
                
                scatterChart.xAxis.axisMinimum = xMin
                scatterChart.xAxis.axisMaximum = xMax
                scatterChart.leftAxis.axisMinimum = yMin
                scatterChart.leftAxis.axisMaximum = yMax
                
                scatterChart.data = chartData
            }
        }
    }
    
    public func setChartFlag(chartFlag: Bool) {
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
    }
}

extension CollectViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width-10, height: 80)
    }
}

extension CollectViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.wardData.isEmpty) {
            return 0
        } else {
            let wards = self.wardData.sorted { $0.1 > $1.1 }
            
            return wards.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WardCollectionViewCell", for: indexPath) as! WardCollectionViewCell
        
        let wards = self.wardData
        
        if (!wards.isEmpty) {
            let sortedWards = wards.sorted { $0.1 > $1.1 }
            let idFull: String = sortedWards[indexPath.item].key
            let id = idFull.components(separatedBy: "-")[2]
                
            cell.wardIdLabel.text = id
            cell.wardRssiLabel.text = String(format: "%.1f", sortedWards[indexPath.item].value)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        print(getLocalTimeString() + " , (CollectVC) Want to delete : \(indexPath.item)")
    }
}

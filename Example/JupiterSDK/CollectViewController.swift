import UIKit
import SwiftCSVExport
import JupiterSDK
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
    let R2D: Double = 180 / Double.pi
    let D2R: Double = Double.pi / 180
    
    @IBOutlet var collectView: UIView!
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var timer: Timer?
    let TIMER_INTERVAL: TimeInterval = 1/40
    
    let data: NSMutableArray  = NSMutableArray()
    
    var saveFlag: Bool = false
    var isWriting: Bool = false
    
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
        
        let width = collectView.frame.size.width
        let height = collectView.frame.size.height
        
        headingImage = headingImage?.resize(newWidth: 40)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        serviceManager.initCollect()
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
        self.saveData()
//        self.saveTrajData()
        
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

    func writeData(collectData: CollectData) {
        let time = collectData.time

        let accX = collectData.acc[0]
        let accY = collectData.acc[1]
        let accZ = collectData.acc[2]

        let gyroX = collectData.gyro[0]
        let gyroY = collectData.gyro[1]
        let gyroZ = collectData.gyro[2]

        let magX = collectData.mag[0]
        let magY = collectData.mag[1]
        let magZ = collectData.mag[2]

        let roll = collectData.att[0]
        let pitch = collectData.att[1]
        let yaw = collectData.att[2]

        let qx = collectData.quaternion[0]
        let qy = collectData.quaternion[1]
        let qz = collectData.quaternion[2]
        let qw = collectData.quaternion[3]

        let pressure = collectData.pressure[0]

        let meas = Measurements()

        meas.time = time

        meas.accX = accX
        meas.accY = accY
        meas.accZ = accZ

        meas.gyroX = gyroX
        meas.gyroY = gyroY
        meas.gyroZ = gyroZ

        meas.magX = magX
        meas.magY = magY
        meas.magZ = magZ

        meas.roll = roll
        meas.pitch = pitch
        meas.yaw = yaw

        meas.qx = qx
        meas.qy = qy
        meas.qz = qz
        meas.qw = qw

        meas.pressure = pressure
        
        let bleData = collectData.bleRaw
        let bleString = (bleData.flatMap({ (key, value) -> String in
            let str = String(format: "%.2f", value)
            return "\(key),\(str)"
        }) as Array).joined(separator: ",")
        meas.ble = bleString

        data.add(listPropertiesWithValues(meas))
    }
    
    func writeTrajectoryData(collectData: CollectData) {
        let time = collectData.time

        let index = collectData.index
        let length = collectData.length
        let heading = collectData.heading
        let pressure = collectData.pressure[0]

        let traj = Trajectory()

        traj.time = time
        traj.index = index
        traj.length = length
        traj.heading = heading
        traj.pressure = pressure
        
        let bleData = collectData.bleAvg
        let bleString = (bleData.flatMap({ (key, value) -> String in
            let str = String(format: "%.2f", value)
            return "\(key),\(str)"
        }) as Array).joined(separator: ",")
        traj.ble = bleString

        data.add(listPropertiesWithValues(traj))
    }
    
    func saveData() {
        let header = ["time", "accX", "accY", "accZ", "gyroX", "gyroY", "gyroZ", "magX", "magY", "magZ", "roll", "pitch", "yaw", "qx", "qy", "qz", "qw", "pressure", "ble"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        // Create a object for write CSV
        let writeCSVObj = CSV()
        writeCSVObj.rows = self.data
        writeCSVObj.delimiter = DividerType.comma.rawValue
        writeCSVObj.fields = header as NSArray
        writeCSVObj.name = "iosData_" + convertNowStr
        
        // Write File using CSV class object
        let output = CSVExport.export(writeCSVObj)
        if output.result.isSuccess {
            guard let filePath =  output.filePath else {
                print("Export Error: \(String(describing: output.message))")
                return
            }
            
            print("File Path: \(filePath)")
            self.readCSVPath(filePath)
        } else {
            print("Export Error: \(String(describing: output.message))")
        }
    }
    
    func saveTrajData() {
        let header = ["time", "index", "length", "heading", "pressure", "ble"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        // Create a object for write CSV
        let writeCSVObj = CSV()
        writeCSVObj.rows = self.data
        writeCSVObj.delimiter = DividerType.comma.rawValue
        writeCSVObj.fields = header as NSArray
        writeCSVObj.name = "iosData_" + convertNowStr
        
        // Write File using CSV class object
        let output = CSVExport.export(writeCSVObj)
        if output.result.isSuccess {
            guard let filePath =  output.filePath else {
                print("Export Error: \(String(describing: output.message))")
                return
            }
            
            print("File Path: \(filePath)")
            self.readCSVPath(filePath)
        } else {
            print("Export Error: \(String(describing: output.message))")
        }
    }
    
    func readCSVPath(_ filePath: String) {
        let request = NSURLRequest(url:  URL(fileURLWithPath: filePath) )
        
        // Read File and convert as CSV class object
        _ = CSVExport.readCSVObject(filePath);
        
        // Use 'SwiftLoggly' pod framework to print the Dictionary
        //        loggly(LogType.Info, text: readCSVObj.name)
        //        loggly(LogType.Info, text: readCSVObj.delimiter)
    }

    @objc func timerUpdate() {
        let bleAvg: [String: Double] = serviceManager.collectData.bleAvg
        let sortedBleAvg = bleAvg.sorted { $0.1 > $1.1 }
        
        self.wardData = bleAvg
        self.wardCollectionView.reloadData()
        
        if (saveFlag) {
            writeData(collectData: serviceManager.collectData)
            if (serviceManager.collectData.isIndexChanged) {
//                writeTrajectoryData(collectData: serviceManager.collectData)
                let index = serviceManager.collectData.index
                let length = serviceManager.collectData.length
                indexLabel.text = String(index)
                lengthLabel.text = String(format: "%.4f", length)
                let currentHeading: Double = serviceManager.collectData.heading + 90
                
                x = x + (length * cos(currentHeading*D2R))
                y = y + (length * sin(currentHeading*D2R))
                
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
                let imageView = UIImageView(image: headingImage!.rotate(degrees: -currentHeading + 90))
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
        //        print("Want to delete : \(indexPath.item)")
    }
}

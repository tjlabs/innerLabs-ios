import UIKit
import AWSS3

class FileViewController: UIViewController {
    
    var fileUrls = [URL]()
    
    var isSelectAll: Bool = false
    
    var arrSelectedIndex = [IndexPath]()
    var arrSelectedFile = [URL]()
    
    @IBOutlet weak var darkView: UIView!
    
    // AWS S3
    var bucketName = ""
    var accessKey = ""
    var secretKey = ""
    var fileKey = "ios/"
    
    @IBOutlet weak var fileCollectionView: UICollectionView!
    @IBOutlet weak var numFilesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDirFiles()
        setupCollectionView()
        
        initS3()
    }
    
    func initS3() {
        if let loadedBucketName = Bundle.main.object(forInfoDictionaryKey: "S3_BUCKET_NAME") as? String {
            self.bucketName = loadedBucketName
        }
        
        if let loadedAccessKey = Bundle.main.object(forInfoDictionaryKey: "S3_ACCESS_KEY") as? String {
            self.accessKey = loadedAccessKey
        }

        if let loadedSecetKey = Bundle.main.object(forInfoDictionaryKey: "S3_SECRET_KEY") as? String {
            self.secretKey = loadedSecetKey
        }
    }
    
    func uploadToS3(fileURLs: [URL]) {
        let urls: [URL] = fileURLs
        
        let progressCircleView = ProgressCircleView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), lineWidth: 10, progressColor: .green)
        progressCircleView.backgroundColor = .clear
        progressCircleView.center = self.view.center
        
        let darkView = UIView(frame: UIScreen.main.bounds)
        darkView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        darkView.isUserInteractionEnabled = true
        if (urls.count > 0) {
            self.view.addSubview(darkView)
            self.view.addSubview(progressCircleView)
        }
        
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: self.accessKey, secretKey: self.secretKey)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.APNortheast2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        var uploadedCount: Double = 0
        
        for i in 0..<urls.count {
            let fileURL: URL = urls[i]
            let urlToString: String = fileURL.absoluteString
            let fileNameArray: [String] = urlToString.components(separatedBy: "/")
            let fileName: String = fileNameArray[fileNameArray.count-1]
            let objectKey = self.fileKey + fileName
            
            guard let fileData = try? Data(contentsOf: fileURL) else {
                print("Failed to read CSV file")
                return
            }
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = {(task, progress) in
                DispatchQueue.main.async {
                    let percentage: Double = (uploadedCount+1)/CGFloat(urls.count)
                    progressCircleView.progress = percentage

                    if (percentage == 1.0) {
                        progressCircleView.removeFromSuperview()
                        darkView.removeFromSuperview()
                    }
                }
            }
            
            let transferUtility = AWSS3TransferUtility.default()
            transferUtility.uploadData(fileData, bucket: self.bucketName, key: objectKey, contentType: "text/csv", expression: expression) {(task, error) in
                if let error = error {
                    print("Failed to upload CSV file: \(error)")
                } else {
                    uploadedCount += 1
                    print("\(fileName) uploaded successfully")
                }
            }
        }
    }
    
    
    @IBAction func tapSelectButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            // 전체선택
            isSelectAll = true
            
            let files = self.fileUrls
            clearSelectedFiles()
            for i in 0..<files.count {
                arrSelectedIndex.append(IndexPath(item: i, section: 0))
            }
            arrSelectedFile = files
            
            self.fileCollectionView.reloadData()
        }
        else {
            // 전체선택 해제
            isSelectAll = false
            clearSelectedFiles()
            
            self.fileCollectionView.reloadData()
        }
    }
    
    @IBAction func tapSendButton(_ sender: UIButton) {
        uploadToS3(fileURLs: self.arrSelectedFile)
    }
    
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        goToBack()
    }
    
    @IBAction func tapDeleteButton(_ sender: UIButton) {
        deleteClicked(files: self.arrSelectedFile, indexs: self.arrSelectedIndex)
    }
    
    public func setupCollectionView() {
        view.addSubview(fileCollectionView)
        
        fileCollectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "FileCollectionViewCell")
        
        fileCollectionView.dataSource = self
        fileCollectionView.delegate = self
        fileCollectionView.allowsMultipleSelection = true
        
        self.fileCollectionView.reloadData()
        fileCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    func goToBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func allSavedFiles() -> [URL]? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for i in 0..<fileURLs.count {
                if (fileURLs[i].absoluteString.range(of: "Exports") != nil) {
                    let exportsUrl = fileURLs[i]
                    do {
                        let directoryContents = try FileManager.default.contentsOfDirectory(at: exportsUrl, includingPropertiesForKeys: nil)
                        return directoryContents.filter{ $0.pathExtension == "csv" }
                    } catch {
                        return nil
                    }
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return nil
    }
    
    func updateDirFiles() {
        if let allFiles = allSavedFiles() {
            self.fileUrls = allFiles
            self.fileCollectionView.reloadData()
            
            self.numFilesLabel.text = "Num Files : \(self.fileUrls.count)"
            self.numFilesLabel.sizeToFit()
        }
    }
    
    func deleteClicked(files: [URL], indexs: [IndexPath]) {
        if (!files.isEmpty) {
            showPopUpWithButton(title: "Delete Files", message: "Are you sure to delete?", leftActionTitle: "Cancel", rightActionTitle: "Okay", rightActionCompletion: deleteFiles)
        }
    }
    
    @objc func deleteFiles() {
        let files = self.arrSelectedFile
        let indexes = self.arrSelectedIndex
        
        var indexsToDelete = [IndexPath]()
        var filesToDelete = [URL]()
        
        for i in 0..<files.count {
            indexsToDelete.append(indexes[i])
            filesToDelete.append(files[i])
            
        }
        print("Index to Delete : \(indexsToDelete)")
        print("File to Delete : \(filesToDelete)")
        
        
        do {
            for i in 0..<filesToDelete.count {
                try FileManager.default.removeItem(at: filesToDelete[i])
                print("File successfully deleted at path: \(filesToDelete[i])")
            }
            
            clearSelectedFiles()
            updateDirFiles()
        } catch let error as NSError {
            print("Failed to delete file with error: \(error.localizedDescription)")
        }
    }
    
    func clearSelectedFiles() {
        self.arrSelectedIndex = [IndexPath]()
        self.arrSelectedFile = [URL]()
    }
}

extension FileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width-10, height: 80)
    }
}

extension FileViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.fileUrls.isEmpty) {
            return 0
        } else {
            let numFiles = self.fileUrls.count
            
            return numFiles
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCollectionViewCell", for: indexPath) as! FileCollectionViewCell
        
        let files = self.fileUrls
        var fileName: String = "Cannot open the file"
        
        if (!files.isEmpty) {
            let fileString: String = files[indexPath.item].path
            let fileNames = fileString.split(separator: "/")
            fileName = String(fileNames[fileNames.count-1])
            
            if arrSelectedIndex.contains(indexPath) {
                cell.fileView.backgroundColor = UIColor.darkgrey4
                cell.fileNameLabel.textColor = .white
            } else {
                cell.fileView.backgroundColor = UIColor.white
                cell.fileNameLabel.textColor = .black
            }
            
        }
        
        cell.fileNameLabel.text = fileName
        cell.fileNameLabel.sizeToFit()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let files = self.fileUrls
        
        let selectedFileUrl = files[indexPath.item]
        
        if arrSelectedIndex.contains(indexPath) {
            arrSelectedIndex = arrSelectedIndex.filter { $0 != indexPath}
            arrSelectedFile = arrSelectedFile.filter { $0 != selectedFileUrl}
        }
        else {
            arrSelectedIndex.append(indexPath)
            arrSelectedFile.append(selectedFileUrl)
        }
        collectionView.reloadData()
    }
}

import UIKit

class FileViewController: UIViewController {
    
    var fileUrls = [URL]()

    var isSelectAll: Bool = false
    
    var arrSelectedIndex = [IndexPath]()
    var arrSelectedFile = [URL]()
    
    @IBOutlet weak var fileCollectionView: UICollectionView!
    @IBOutlet weak var numFilesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDirFiles()
        setupCollectionView()
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
            
            print("Select All : \(arrSelectedIndex)")
            print("Select All : \(arrSelectedFile)")
            
            self.fileCollectionView.reloadData()
        }
        else {
            // 전체선택 해제
            isSelectAll = false
            
            clearSelectedFiles()
            
            print("Clear All : \(arrSelectedIndex)")
            print("Clear All : \(arrSelectedFile)")
            
            self.fileCollectionView.reloadData()
        }
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
        
        
//        var indexsToDelete = [IndexPath]()
//        var filesToDelete = [URL]()
//
//        for i in 0..<files.count {
//            indexsToDelete.append(indexs[i])
//            filesToDelete.append(files[i])
//
//        }
//        print("Index to Delete : \(indexsToDelete)")
//        print("File to Delete : \(filesToDelete)")
//
//
//        do {
//            for i in 0..<filesToDelete.count {
//                try FileManager.default.removeItem(at: filesToDelete[i])
//                print("File successfully deleted at path: \(filesToDelete[i])")
//            }
//
//            clearSelectedFiles()
//            updateDirFiles()
//        } catch let error as NSError {
//            print("Failed to delete file with error: \(error.localizedDescription)")
//        }
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
        arrSelectedIndex = [IndexPath]()
        arrSelectedFile = [URL]()
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
        
        print("Selected : \(arrSelectedIndex)")
        print("Selected : \(arrSelectedFile)")

        collectionView.reloadData()
    }
}

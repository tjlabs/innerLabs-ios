import UIKit

class FileViewController: UIViewController {
    
    var fileUrls = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDirFiles()
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        goToBack()
    }
    
    @IBAction func tapDeleteButton(_ sender: UIButton) {
        deleteFiles(files: self.fileUrls)
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
        }
    }
    
    func deleteFiles(files: [URL]) {
        var filesToDelete = [URL]()
        if files.count > 1 {
            filesToDelete.append(files[0])
        }
        print("All Files : \(files.count) , \(files)")
        print("File To Delete : \(filesToDelete)")
        
        do {
            try FileManager.default.removeItem(at: filesToDelete[0])
            print("File successfully deleted at path: \(filesToDelete[0])")
            updateDirFiles()
            print(self.fileUrls)
        } catch let error as NSError {
            print("Failed to delete file with error: \(error.localizedDescription)")
        }
    }
}

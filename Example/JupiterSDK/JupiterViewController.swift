import UIKit
import JupiterSDK

enum TableList{
    case sector
}

class JupiterViewController: UIViewController {

    @IBOutlet weak var jupiterTableView: UITableView!
    
    private let tableList: [TableList] = [.sector]
    
    var jupiterService = PDRService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        self.navigationItem.hidesBackButton = true
        
        makeDelegate()
        registerXib()
        
        jupiterService.startService(parent: self)
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

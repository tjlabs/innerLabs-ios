import UIKit

class FileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        goToBack()
    }
    
    func goToBack() {
        self.navigationController?.popViewController(animated: true)
    }
}

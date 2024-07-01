import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var webView: WKWebView!
    
    var url = URL(string: "https://tjlabscorp.tistory.com/3")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBar.topItem?.title = "개인정보처리방침"
        navBar.tintColor = UIColor.white
        
        let bbiDone = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(bbiDonelTapped))
        bbiDone.tintColor = UIColor.red
        
        navBar.topItem?.rightBarButtonItem = bbiDone
        
        let request = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60 * 60 * 24)
        webView.load(request)
    }
    
    @objc func bbiDonelTapped(_ sender: UIButton?) {
        self.dismiss(animated: true, completion: nil)
    }
}

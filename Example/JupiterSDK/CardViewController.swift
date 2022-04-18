import UIKit
import JupiterSDK

class CardViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var uuid: String = ""
    var cardItemData: [CardItemData] = []
    var cardImages: [UIImage] = []
    var sectorImages: [UIImage] = []
    
    let INITIAL_CARD: Int = 1
    
    // Card
        let itemColors = [UIColor.green, UIColor.red, UIColor.yellow, UIColor.blue, UIColor.green, UIColor.red]
//    let itemColors = [UIColor.red, UIColor.yellow, UIColor.blue, UIColor.green]
    var currentIndex: CGFloat = 0
    let lineSpacing: CGFloat = 20
    
    var currentPage: Int = 0
    var previousIndex: Int = 0
    
    // Default : 0.7
    //    let cellWidthRatio: CGFloat = 0.7
    //    let cellheightRatio: CGFloat = 0.9
    
    let cellWidthRatio: CGFloat = 0.8
    let cellheightRatio: CGFloat = 0.9
    
    var isOneStepPaging = true
    
    func setData(data: Array<CardItemData>) {
        for i in 0..<data.count {
            let cardImage = UIImage(named: data[i].cardImage)!
            cardImages.append(cardImage)
            
            let sectorImage = UIImage(named: data[i].sectorImage)!
            sectorImages.append(sectorImage)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setData(data: cardItemData)
        setupCollectionView()
        setupProgressView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        let cardCount = cardItemData.count
        collectionView.scrollToItem(at: IndexPath(item: INITIAL_CARD, section: 0), at: .centeredHorizontally, animated: false)
        let progress: Float = Float(INITIAL_CARD+1) / Float(cardCount)
        self.progressView.setProgress(progress, animated: true)
    }
    
    // 최초 보여지는 카드
//    override func viewDidLayoutSubviews() {
//        let cardCount = cardItemData.count
//        collectionView.scrollToItem(at: IndexPath(item: INITIAL_CARD, section: 0), at: .centeredHorizontally, animated: false)
//        let progress: Float = Float(INITIAL_CARD+1) / Float(cardCount)
//        self.progressView.setProgress(progress, animated: true)
//    }
    
    public func setupCollectionView() {
        // width, height 설정
        let cellWidth = floor(collectionView.frame.width * cellWidthRatio)
        let cellHeight = floor(collectionView.frame.height * cellheightRatio)
        
        // 상하, 좌우 inset value 설정
        let insetX = (collectionView.bounds.width - cellWidth) / 2.0
        let insetY = (collectionView.bounds.height - cellHeight) / 2.0
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.minimumLineSpacing = lineSpacing
        layout.scrollDirection = .horizontal
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Color Card 설정 시 주석 풀기
        collectionView.register(UINib(nibName: "CardCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "CardCollectionViewCell")
        self.collectionView.reloadData()
        
        // 스크롤 시 빠르게 감속 되도록 설정
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    public func setupProgressView() {
        self.progressView.clipsToBounds = true
        self.progressView.progress = 0.0
//        self.progressView.transform = progressView.transform.scaledBy(x: 1, y: 1.5)
        self.progressView.layer.cornerRadius = 3.0
    }
    
    
    @IBAction func tapShowCardButton(_ sender: UIButton) {
        guard let jupiterVC = self.storyboard?.instantiateViewController(withIdentifier: "JupiterViewController") as? JupiterViewController else { return }
        jupiterVC.uuid = uuid
        self.navigationController?.pushViewController(jupiterVC, animated: true)
    }
    
    public func getProgressValue(currentPage: Int) -> Float {
        var progressValue: Float = 0.0
        if (currentPage == 0 || currentPage == cardItemData.count-2) {
            progressValue = 1.0
        } else if (currentPage == 1 || currentPage == cardItemData.count-1) {
            progressValue = 1/Float(cardItemData.count-2)
        } else {
            progressValue = Float(currentPage)/Float(cardItemData.count-2)
        }

        return progressValue
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
    }
    
}

extension CardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cardItemData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Color Card 설정 시 주석 풀기
        //        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        //        cell.backgroundColor = itemColors[indexPath.row]
        //        cell.alpha = 0.5
        
        
        // Image Card 설정 시 주석 풀기
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        cell.cardImageView.image = cardImages[indexPath.row]
        cell.sectorImageView.image = sectorImages[indexPath.row]
//        cell.cardView.backgroundColor = itemColors[indexPath.row]
        
        return cell
    }
    
}

extension CardViewController : UIScrollViewDelegate {
    
    // 사용자가 스크롤하고 스크린과 손이 떨어졌을 경우
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        // item의 사이즈와 item 간의 간격 사이즈를 구해서 하나의 item 크기로 설정.
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing
        
        // targetContentOff을 이용하여 x좌표가 얼마나 이동했는지 확인
        // 이동한 x좌표 값과 item의 크기를 비교하여 몇 페이징이 될 것인지 값 설정
        var offset = targetContentOffset.pointee
        let index = (offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing
        var roundedIndex = round(index)
        
        // scrollView, targetContentOffset의 좌표 값으로 스크롤 방향을 알 수 있다.
        // index를 반올림하여 사용하면 item의 절반 사이즈만큼 스크롤을 해야 페이징이 된다.
        // 스크롤로 방향을 체크하여 올림,내림을 사용하면 좀 더 자연스러운 페이징 효과를 낼 수 있다.
        if scrollView.contentOffset.x > targetContentOffset.pointee.x {
            roundedIndex = floor(index)
        } else if scrollView.contentOffset.x < targetContentOffset.pointee.x {
            roundedIndex = ceil(index)
        } else {
            roundedIndex = round(index)
        }
        
        if isOneStepPaging {
            if currentIndex > roundedIndex {
                currentIndex -= 1
                roundedIndex = currentIndex
            } else if currentIndex < roundedIndex {
                currentIndex += 1
                roundedIndex = currentIndex
            }
        }
        
        // 위 코드를 통해 페이징 될 좌표값을 targetContentOffset에 대입하면 된다.
        offset = CGPoint(x: roundedIndex * cellWidthIncludingSpacing - scrollView.contentInset.left, y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset
        
        currentPage = Int(roundedIndex)
        print("Current Page: \(roundedIndex)")
        
        // ProgressBar
        let progress = getProgressValue(currentPage: currentPage)
        UIView.animate(withDuration: 0.5) {
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if currentPage == 0 {
//            collectionView.scrollToItem(at: IndexPath(item: cardItemData.count-2, section: 0), at: .centeredHorizontally, animated: false)
//            currentIndex = CGFloat(cardItemData.count-2)
//            previousIndex = 1
//        } else if currentPage == cardItemData.count-1 {
//            collectionView.scrollToItem(at: IndexPath(item: INITIAL_CARD, section: 0), at: .centeredHorizontally, animated: false)
//            currentIndex = CGFloat(INITIAL_CARD)
//            previousIndex = cardItemData.count-2
////            print("You have to move to first")
//        }
//    }
    
    func animateZoomforCell(zoomCell: UICollectionViewCell) {
        UIView.animate( withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { zoomCell.transform = .identity }, completion: nil)
    }
    
    func animateZoomforCellremove(zoomCell: UICollectionViewCell) {
        UIView.animate( withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { zoomCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) }, completion: nil)
        
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        let cellWidth = floor(collectionView.frame.width * cellWidthRatio)
        
        let cellWidthIncludeSpacing = cellWidth + layout.minimumLineSpacing
        
        let offsetX = collectionView.contentOffset.x
        let index = (offsetX + collectionView.contentInset.left) / cellWidthIncludeSpacing
        let roundedIndex = round(index)
        let indexPath = IndexPath(item: Int(roundedIndex), section: 0)
        
        //        let roundedIndex = currentPage
        //        let indexPath = IndexPath(item: Int(roundedIndex), section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) {
            animateZoomforCell(zoomCell: cell)
        }
        if Int(roundedIndex) != previousIndex {
            let preIndexPath = IndexPath(item: previousIndex, section: 0)
            if let preCell = collectionView.cellForItem(at: preIndexPath)
            {
                animateZoomforCellremove(zoomCell: preCell)
                
            }
            previousIndex = indexPath.item
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if currentPage == 0 {
            collectionView.scrollToItem(at: IndexPath(item: cardItemData.count-2, section: 0), at: .centeredHorizontally, animated: false)
            currentIndex = CGFloat(cardItemData.count-2)
            previousIndex = 1
        } else if currentPage == cardItemData.count-1 {
            collectionView.scrollToItem(at: IndexPath(item: INITIAL_CARD, section: 0), at: .centeredHorizontally, animated: false)
            currentIndex = CGFloat(INITIAL_CARD)
            previousIndex = cardItemData.count-2
        }
    }
}



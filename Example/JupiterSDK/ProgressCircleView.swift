import UIKit

class ProgressCircleView: UIView {
    
    private var progressLabel: UILabel!
    
    var progress: CGFloat = 0 {
        didSet {
            progressLabel.text = "\(Int(progress * 100))%"
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth/2
        let startAngle = -CGFloat.pi/2
        let endAngle = startAngle + progress * 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        progressColor.setStroke()
        path.stroke()
    }
    
    var lineWidth: CGFloat = 20
    var progressColor: UIColor = .green
    
    convenience init(frame: CGRect, lineWidth: CGFloat, progressColor: UIColor) {
        self.init(frame: frame)
        self.lineWidth = lineWidth
        self.progressColor = progressColor
        
        self.progressLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        self.progressLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)
        self.progressLabel.textAlignment = .center
        self.progressLabel.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        self.progressLabel.textColor = .green
        addSubview(progressLabel)
    }
}

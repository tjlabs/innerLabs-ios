import Foundation

protocol AddCardDelegate {
    func sendCardItemData(data: [CardItemData])
    func sendPage(data: Int)
}

protocol ServiceViewPageDelegate {
    func sendPage(data: Int)
}

protocol FusionViewPageDelegate {
    func sendPage(data: Int)
}

protocol ShowCardDelegate {
    func sendCardItemData(data: [CardItemData])
    func sendPage(data: Int)
}

protocol GuideSendPageDelegate {
    func sendPage(data: Int)
}

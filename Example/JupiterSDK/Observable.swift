import Foundation

class Observable<T> {
    typealias Listener = (T) -> Void
    var listener: Listener?
    // ✅ 값이 변할 때마다 클로저 listener 를 호출한다.(View 의 액션에 따라서 자동으로 View Model 의 값이 최신화.)
    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func bind(_ closure: @escaping (T) -> Void) {
        self.listener = closure
        listener?(value)
    }
}

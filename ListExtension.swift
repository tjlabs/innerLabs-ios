//
//  LinkedList.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/24.
//

import Foundation

public class Node<T> {
    public var value: T
    public var next: Node<T>?
    
    public init(value: T, next: Node<T>?) {
        self.value = value
        self.next = next
    }
}

public class LinkedList<T> {
    public var head: Node<T>?
    public var tail: Node<T>?
    
    public init (head: Node<T>?) {
        self.head = head
        self.tail = head
    }
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: Node<T>? {
        return head
    }
    
    public var last: Node<T>? {
        guard var node = head else {
            return nil
        }
        
        while let next = node.next {
            node = next
        }
        return node
    }
    
    public var count: Int {
        guard var node = head else {
            return 0
        }
        
        var count = 1
        while let next = node.next {
            node = next
            count += 1
        }
        return count
    }
    
    public func node(at index: Int) -> Node<T>? {
        if index == 0 {
            return head
        } else {
            var node = head!.next
            for _ in 1..<index {
                node = node?.next
                if node == nil {
                    break
                }
            }
            
            return node
        }
    }
    
    public func append(_ newNode: Node<T>) {
        if let tail = self.tail {
            tail.next = newNode
            self.tail = tail.next
        } else {
            self.head = newNode
            self.tail = newNode
        }
    }
    
    public func insert(_ newNode: Node<T>, at index: Int) {
        if self.head == nil {
            self.head = newNode
            self.tail = newNode
            return
        }
        guard let frontNode = node(at: index-1) else {
            self.tail?.next = newNode
            self.tail = newNode
            return
        }
        guard let nextNode = frontNode.next else {
            frontNode.next = newNode
            self.tail = newNode
            return
        }
        newNode.next = nextNode
        frontNode.next = newNode
    }
    
    public func removeAll() {
        head = nil
    }
    
    public func remove(at index: Int) -> T? {
        guard let frontNode = node(at: index-1) else { // 인덱스 앞 노드를 찾을 수 없다면 -> nil 반환
            return nil
        }
        
        guard let removeNode = frontNode.next else { // 인덱스 앞 노드가 마지막 노드라면 -> nil 반환
            return nil
        }
        
        guard let nextNode = removeNode.next else { // index가 마지막 위치라면? -> tail에 index 이전 노드 저장
            frontNode.next = nil
            self.tail = frontNode
            return removeNode.value
        }
        
        frontNode.next = nextNode // index - 1 가 마지막 아닐 때 (일반적인 경우)
        
        return removeNode.value
    }
    
    public func removeLast() -> T? {
        return remove(at: self.count - 1)
    }
}

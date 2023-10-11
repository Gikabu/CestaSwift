//
//  File.swift
//  
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import RealmSwift

//import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public typealias RealmQueryChanged = ([IndexPath]) -> Void

final public class RealmQuery<T: Object> {

    // MARK: - Properties
    
    private var deleteNotificationBlock: RealmQueryChanged?
    private var insertNotificationBlock: RealmQueryChanged?
    private var updateNotificationBlock: RealmQueryChanged?

    private(set) var notificationToken: NotificationToken?
    private(set) var section: Int?
    
    public var results: Results<T>?
    public var count: Int {
        return results?.count ?? 0
    }
    
    // MARK: - Subscript
    
    public subscript(index: Int) -> T? {
        return results?[index]
    }

    // MARK: - Con(De)structor

    init(results: Results<T>?) {
        self.results = results
    }

    deinit {
        clearNotification()
    }

    // MARK: - Public methods
    
    public func onDelete<Object: AnyObject>(
        _ object: Object,
        block: @escaping (Object, [IndexPath]) -> Void
    ) -> Self {
        deleteNotificationBlock = { [weak object] (deletions) in
            guard let weakObject = object else {return}
            
            block(weakObject, deletions)
        }
        return self
    }
    
    public func onInsert<Object: AnyObject>(
        _ object: Object,
        block: @escaping (Object, [IndexPath]) -> Void
    ) -> Self {
        insertNotificationBlock = { [weak object] (insertions) in
            guard let weakObject = object else {return}
            
            block(weakObject, insertions)
        }
        return self
    }
    
    public func onUpdate<Object: AnyObject>(
        _ object: Object,
        block: @escaping (Object, [IndexPath]) -> Void
    ) -> Self {
        updateNotificationBlock = { [weak object] (modifications) in
            guard let weakObject = object else {return}
            
            block(weakObject, modifications)
        }
        return self
    }
    
    public func clearNotification() {
        notificationToken?.invalidate()
    }
    
    public func registerNotification() {
        guard let results = results else { return }

        clearNotification()
        notificationToken = results.observe { [weak self] (change) in
            guard let weakSelf = self else {return}
            
            switch change {
            case .update(_, let deletions, let insertions, let modifications):
                let indexPathsForDeletions = weakSelf.indexPathsFromInt(deletions)
                let indexPathsForInsertions = weakSelf.indexPathsFromInt(insertions)
                let indexPathsForModifications = weakSelf.indexPathsFromInt(modifications)
                
                if !deletions.isEmpty && !insertions.isEmpty && deletions.count == insertions.count {
                    weakSelf.updateNotificationBlock?(indexPathsForInsertions)
                } else {
                    if !deletions.isEmpty {
                        weakSelf.deleteNotificationBlock?(indexPathsForDeletions)
                    }
                    if !insertions.isEmpty {
                        weakSelf.insertNotificationBlock?(indexPathsForInsertions)
                    }
                    if !modifications.isEmpty {
                        weakSelf.updateNotificationBlock?(indexPathsForModifications)
                    }
                }
            default:
                break
            }
        }
    }
    
    public func setSection(_ section: Int) -> Self {
        self.section = section
        return self
    }

    // MARK: - Private methods
    
    private func indexPathsFromInt(_ data: [Int]) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        data.forEach { (datum) in
            #if os(iOS)
            indexPaths.append(IndexPath(row: datum, section: section ?? 0))
            #elseif os(macOS)
            indexPaths.append(IndexPath(item: datum, section: section ?? 0))
            #endif
        }
        return indexPaths
    }

}

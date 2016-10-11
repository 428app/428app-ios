//
//  Friend+CoreDataProperties.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import CoreData

extension Friend {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<Friend>(entityName: "Friend") as! NSFetchRequest<NSFetchRequestResult>;
    }

    @NSManaged public var profileImageName: String?
    @NSManaged public var name: String?
    @NSManaged public var disciplineImageName: String?
    @NSManaged public var messages: NSSet?

}

// MARK: Generated accessors for messages
extension Friend {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

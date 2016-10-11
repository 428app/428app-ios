//
//  Message+CoreDataProperties.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation
import CoreData

extension Message {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<Message>(entityName: "Message") as! NSFetchRequest<NSFetchRequestResult>;
    }

    @NSManaged public var date: Date?
    @NSManaged public var text: String?
    @NSManaged public var isSender: Bool
    @NSManaged public var friend: Friend?

}

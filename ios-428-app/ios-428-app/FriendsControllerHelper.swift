//
//  FriendsControllerHelper.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

import UIKit
import CoreData

extension FriendsController {
    
    func clearData() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        do {
            let messageFetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
            let friendFetchRequest: NSFetchRequest<Friend> = Friend.fetchRequest()
            let messages = try(context.fetch(messageFetchRequest) as [Message])
            let friends = try(context.fetch(friendFetchRequest) as [Friend])
            for message in messages {
                context.delete(message)
            }
            for friend in friends {
                context.delete(friend)
            }
            try(context.save())
        } catch let err {
            print(err)
        }
    }
    
    func setupData() {
        clearData()
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        let leo = Friend(context: context)
        leo.name = "Leonard"
        leo.profileImageName = "leo-profile"
        leo.disciplineImageName = "business"

        let jenny = Friend(context: context)
        jenny.name = "Jenny"
        jenny.profileImageName = "jenny-profile"
        jenny.disciplineImageName = "biology"
        let spandan = Friend(context: context)
        spandan.name = "Spandan"
        spandan.profileImageName = "spandan-profile"
        spandan.disciplineImageName = "computer"

        _ = FriendsController.createMessageWithText(friend: leo, text: "Hello, my name is Leonard. Nice to meet you!", minutesAgo: 5, context: context)
        createThomasMessagesWithContext(context: context)
        _ = FriendsController.createMessageWithText(friend: jenny, text: "I want to eat food now! Give me food or else!!", minutesAgo: 60 * 24 * 2, context: context)
        _ = FriendsController.createMessageWithText(friend: spandan, text: "I love computer vision! Let's hack something cool together.", minutesAgo: 60 * 24 * 10, context: context)

        do {
            try(context.save())
        } catch let err {
            print(err)
        }
        loadData()
    }
    
    // TODO: For testing, to remove later
    private func createThomasMessagesWithContext(context: NSManagedObjectContext) {
        let thomas = Friend(context: context)
        thomas.name = "Thomas"
        thomas.profileImageName = "thomas-profile"
        thomas.disciplineImageName = "computer"
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Let's engage in cooking and combine it with art! That way it's a lot more engaging. Don't you think we should do it immediately? Hurray!", minutesAgo: 60 * 24 * 1.7, context: context)
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Good morning. Why are you ignoring me?", minutesAgo: 60 * 24 * 1.6, context: context)
        _ = FriendsController.createMessageWithText(friend: thomas, text: "If you continue to ignore me I'm going to block you.", minutesAgo: 60 * 24 * 1.5, context: context)
        
        // Response message
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Okay, okay I'm finally replying now! Hi!", minutesAgo: 60 * 24 * 1.4, context: context, isSender: true)
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Ok great. Are you free anytime soon to discuss some of my ideas? We can play ping pong too if you want.", minutesAgo: 60 * 24 * 1.3, context: context)
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Sure. How about 6pm tomorrow at Richard's Basement?", minutesAgo: 60 * 24 * 1.25, context: context, isSender: true)
        _ = FriendsController.createMessageWithText(friend: thomas, text: "Also I'm not so sure how free I am from tomorrow onwards. I'm going to be coding 428 non stop until I finally finish implementing it! This is a product that has real value for people - Imagine you having connections from multiple different disciplines! And all those disciplines are already right here at Harvard, but unfortunately with no easy way to connect them... until now!!", minutesAgo: 60 * 24 * 1.2, context: context, isSender: true)
    }
    
    static func createMessageWithText(friend: Friend, text: String, minutesAgo: Double, context: NSManagedObjectContext, isSender: Bool = false) -> Message {
        let message = Message(context: context)
        message.friend = friend
        message.text = text
        message.date = NSDate().addingTimeInterval(-minutesAgo * 60)
        message.isSender = isSender
        return message
    }
    
    func loadData() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        guard let friends = fetchFriends() else {
            return
        }
        messages = [Message]()
        
        for friend in friends {
            if friend.name == nil {
                continue
            }
            let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "friend.name = %@", friend.name!)
            fetchRequest.fetchLimit = 1
            do {
                // messages inside FriendsController
                let fetchedMessages = try(context.fetch(fetchRequest) as [Message])
                messages?.append(contentsOf: fetchedMessages)
            } catch let err {
                print(err)
            }
        }
        messages = messages?.sorted{($0.date as! Date).compare($1.date as! Date) == .orderedDescending}
    }
    
    private func fetchFriends() -> [Friend]? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let context = delegate.persistentContainer.viewContext
        let friendFetchRequest: NSFetchRequest<Friend> = Friend.fetchRequest()
        do {
            return try(context.fetch(friendFetchRequest) as [Friend])
        } catch let err {
            print(err)
        }
        return nil
    }
}

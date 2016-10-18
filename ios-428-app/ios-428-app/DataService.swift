//
//  ConnectionsControllerHelper.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

import UIKit
import CoreData
// TODO: To tear down this extension and replace it with Firebase DataService

// Set up profiles
let jennyprof = Profile(uid: "1", name: "Jenny", disciplineImageName: "biology", profileImageName: "jenny-profile", disciplineBgName: "biology-bg", age: 22, location: "USA, MA, Cambridge", org: "Maxwell Dworkin Corp", school: "Harvard University of Wizardry, Angels and the Forbidden Arts", discipline: "Biology", tagline1: "understanding mutations in DNA and how they lead to cancer. I'm doing it because I've always enjoyed Biology. In middle school I dissected an animal's heart, and my interest just escalated from there!", tagline2: "make a breakthrough in cancer research and win a Nobel prize. That's a big statement I know, but gotta dream big right?")



// Set up messages
extension ConnectionsController {

    func setupData() {
        // Create messages
        let jenny = Friend(uid: "1", name: "Jenny", profileImageName: "jenny-profile", disciplineImageName: "biology")
        let spandan = Friend(uid: "2", name: "Spandan", profileImageName: "spandan-profile", disciplineImageName: "computer")
        let tomas = Friend(uid: "3", name: "Tomas", profileImageName: "tomas-profile", disciplineImageName: "computer")
        let kyooeun = Friend(uid: "4", name: "Kyooeun", profileImageName: "kyooeun-profile", disciplineImageName: "eastasian")
        let emil = Friend(uid: "5", name: "Emil", profileImageName: "emil-profile", disciplineImageName: "physics")
        let kezi = Friend(uid: "6", name: "Kezi", profileImageName: "kezi-profile", disciplineImageName: "physics")
        
        _ = self.createMessageForFriend(tomas, text: "Let's go to the gym! When do you want to do it?", minutesAgo: 60 * 24 * 3, isSender: true)
        _ = self.createMessageForFriend(kyooeun, text: "ni hao ma??", minutesAgo: 60 * 24, isSeen: false)
        _ = self.createMessageForFriend(emil, text: "Dude! Quantum mechanics is my true love. You should go check it out.", minutesAgo: 25, isSeen: false)
        _ = self.createMessageForFriend(kezi, text: "How have you been Kezi?", minutesAgo: 29, isSender: true)

        createLeoMessages()
        createThomasMessages()
        _ = self.createMessageForFriend(jenny, text: "I want to eat food now! Give me food or else!!", minutesAgo: 60 * 24 * 400)
        _ = self.createMessageForFriend(spandan, text: "I love computer vision! Let's hack something cool together.", minutesAgo: 60 * 24 * 10)
        
        // Set messages
        self.latestMessages = friendToLatestMessage.flatMap { (_: String, v: Message) -> Message? in
            return v
        }
        self.latestMessages = self.latestMessages.sorted{($0.date.timeIntervalSince1970) > ($1.date.timeIntervalSince1970)}
    }
    
    fileprivate func createLeoMessages() {
        let leo = Friend(uid: "7", name: "Leonard", profileImageName: "leo-profile", disciplineImageName: "business")
        _ = self.createMessageForFriend(leo, text: "Hello, my name is Leonard. Nice to meet you!", minutesAgo: 200)
        _ = self.createMessageForFriend(leo, text: "What do you do?", minutesAgo: 198)
        _ = self.createMessageForFriend(leo, text: "Hi! My name is Yihang.", minutesAgo: 90, isSender: true)
        _ = self.createMessageForFriend(leo, text: "I'm currently pursuing a Masters in Computational Science & Engineering.", minutesAgo: 89, isSender: true)
        _ = self.createMessageForFriend(leo, text: "That's cool! Okay I'll brb and talk to you later all right?", minutesAgo: 20)
        _ = self.createMessageForFriend(leo, text: "Ok gotcha. I'm gonna go do data science homework first!", minutesAgo: 15, isSender: true)
    }
    
    fileprivate func createThomasMessages() {
        let thomas = Friend(uid: "8", name: "Thomas", profileImageName: "thomas-profile", disciplineImageName: "electricengineering")
        _ = self.createMessageForFriend(thomas, text: "Let's engage in cooking and combine it with art! That way it's a lot more engaging. Don't you think we should do it immediately? Hurray!", minutesAgo: 60 * 24 * 1.7)
        _ = self.createMessageForFriend(thomas, text: "Hey, you haven't replied. You there?", minutesAgo: 60 * 24 * 1.6)
        _ = self.createMessageForFriend(thomas, text: "Anyway just thought of a new twist. Let's meet for a while.", minutesAgo: 60 * 24 * 1.5)
        
        // Response message
        _ = self.createMessageForFriend(thomas, text: "Okay, okay I'm finally replying now! Hi!", minutesAgo: 60 * 24 * 1.4, isSender: true)
        _ = self.createMessageForFriend(thomas, text: "Ok great. Are you free anytime soon to discuss some of my ideas? We can play ping pong too if you want.", minutesAgo: 60 * 24 * 1.3)
        _ = self.createMessageForFriend(thomas, text: "Sure. How about 6pm tomorrow at Richard's Basement?", minutesAgo: 60 * 24 * 1.25, isSender: true)
        _ = self.createMessageForFriend(thomas, text: "Also I'm not so sure how free I am from tomorrow onwards. I'm going to be coding 428 non stop until I finally finish implementing it! This is a product that has real value for people - Imagine you having connections from multiple different disciplines! And all those disciplines are already right here at Harvard, but unfortunately with no easy way to connect them... until now!!", minutesAgo: 60 * 24 * 1.2, isSender: true)
        _ = self.createMessageForFriend(thomas, text: "OK good luck with your crazy ideas then! I hope you do well in that.", minutesAgo: 60 * 24 * 1.19)
        _ = self.createMessageForFriend(thomas, text: "www.google.com", minutesAgo: 60 * 24 * 1.1, isSeen: false)
    }
    

    fileprivate func createMessageForFriend(_ friend: Friend, text: String, minutesAgo: Double, isSender: Bool = false, isSeen: Bool = true) -> Message {
        let message = Message(mid: "\(midAutoId)", text: text, friend: friend, date: Date().addingTimeInterval(-minutesAgo * 60), isSender: isSender, isSeen: isSeen)
        midAutoId += 1
        friend.addMessage(message: message) // Friend has all their own messages
        let uid = friend.uid
        if friendToMinutesAgo[uid] == nil || friendToMinutesAgo[uid]! > minutesAgo {
            friendToMinutesAgo[uid] = minutesAgo
            friendToLatestMessage[uid] = message
        }
        return message
    }
}

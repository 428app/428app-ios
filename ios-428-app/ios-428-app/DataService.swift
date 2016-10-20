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

// Set up topics

func t(daysAgo: Double) -> Date {
    return Date().addingTimeInterval(-daysAgo * 60.0 * 60.0 * 24.0)
}

func loadTopics() -> [Topic] {
    var topics = [Topic]()
    let topic1 = Topic(tid: "1", prompt: "Healthcare in the United States is badly broken. We are getting close to spending 20% of our GDP on healthcare.", imageName: "topic-healthcare", description: "How do you make healthcare better for less money, and not exploit the system by overcharging. Think about preventative healthcare, as this is probably the highest-leverage way to improve health. Sensors and data are interesting in lots of different areas, but especially for healthcare. Medical devices also seem like fertile ground for startups.", date: t(daysAgo: 1))
    let topic2 = Topic(tid: "2", prompt: "We are starting to augment humans.", imageName: "topic-augmentation", description: "This is a very general category because there are a lot of different ways to do this. Biotech can help us live longer and be smarter. Robots can help us do physical things we otherwise couldn’t. Software can help us focus on simple actions that make us happier and help large groups of us organize ourselves better. And on and on and on.", date: t(daysAgo: 2))
    let topic3 = Topic(tid: "3", prompt: "About half of all energy is used on transportation, and people spend a huge amount of time unhappily commuting.", imageName: "topic-cars", description: "Face-to-face interaction is still really important; people still need to move around. And housing continues to get more expensive, partially due to difficulties in transportation. We’re interested in better ways for people to live somewhere nice, work together, and have easier commutes. Specifically, lightweight, short-distance personal transportation is something we’re interested in.", date: t(daysAgo: 3))
    let topic4 = Topic(tid: "4", prompt: "Let us think of an idea to create a million jobs.", imageName: "topic-jobs", description: "There are a lot of areas where it makes sense to divide labor between humans and computers-—we are very good at some things computers are terrible at and vice versa—-and some of these require huge amounts of human resources. This is both good for the world and likely a good business strategy—-as existing jobs go away, a company that creates a lot of new jobs should be able to get a lot of talented people.", date: t(daysAgo: 4))
    let topic5 = Topic(tid: "5", prompt: "New celebrities don’t get discovered by talent agents, they get discovered directly by their fans on YouTube.", imageName: "topic-celebrities", description: "In 2014, movies had their worst summer since 1997. Just like future celebrities are unlikely to get their start with talent agencies, future content consumers will watch content online instead of at the theater, and probably in very different ways. Celebrities now have direct relationships with their fans. They can also distribute content in new ways. There are almost certainly huge new businesses that will get built as part of this shift.", date: t(daysAgo: 5))
    let topic6 = Topic(tid: "6", prompt: "The world’s financial systems are increasingly unable to meet the demands of consumers and businesses.", imageName: "topic-finance", description: "That makes some sense because regulations designed to protect customers can’t change fast enough to keep up with the pace at which technology is changing the needs of those customers. This mismatch creates inefficiencies at almost every level of the financial system. It impacts how people invest their savings, how businesses gain access to capital to grow, how risk is priced and insured, and how financial firms do business with each other. We think that software will accelerate the pace at which financial services change and will eventually shift the nature of regulations. We want to fund companies with novel ideas of how to make that happen.", date: t(daysAgo: 6))
    let topic7 = Topic(tid: "7", prompt: "Securing computers is difficult because the work required is so asymmetric", imageName: "topic-security", description: "The attacker only has to find one flaw, while a defender has to protect against every possible weakness. Unfortunately, securing computers isn’t just hard - it’s critically and increasingly important. As the software revolution continues and more critical information and systems are connected to the Internet, we become more vulnerable to cyberattacks and the disruption is more severe.", date: t(daysAgo: 7))
    let topic8 = Topic(tid: "8", prompt: "There are lots of cheap, proven ways to save and improve people’s lives. They should be reaching everyone.", imageName: "topic-nonprofits", description: "Why do so many people in the developing world still suffer for lack of simple things like bednets, vaccines, and iodized salt? Part of the problem is money, and we’re interested in new ways to get people to give. Part of it is execution, and we’d love to see nonprofits that are truly data-literate and metrics-driven closing these gaps. Organizations like GiveWell have large amounts of funding at the ready for provably effective global health interventions.", date: t(daysAgo: 8))
    topics = [topic1, topic2, topic3, topic4, topic5, topic6, topic7, topic8]
    return topics
}


// Set up profiles
let jennyprof = Profile(uid: "1", name: "Jenny", disciplineImageName: "biology", profileImageName: "jenny-profile", disciplineBgName: "jenny-bg", age: 22, location: "USA, MA, Cambridge", org: "Maxwell Dworkin Corp", school: "Harvard University of Wizardry, Angels and the Forbidden Arts", discipline: "Biology", tagline1: "understanding mutations in DNA and how they lead to cancer. I'm doing it because I've always enjoyed Biology. In middle school I dissected an animal's heart, and my interest just escalated from there!", tagline2: "make a breakthrough in cancer research and win a Nobel prize. That's a big statement I know, but gotta dream big right?")
let yihangprof = Profile(uid: "99", name: "Yihang", disciplineImageName: "business", profileImageName: "yihang-profile", disciplineBgName: "yihang-bg", age: 24, location: "USA, MA, Cambridge", org: "428", school: "Harvard University", discipline: "Business", tagline1: "an app that lets you easily meet people from different industries. There's LinkedIn, and we're LinkedOut. On the app, you get matched with a new connection and introduced to a new topic once a day, at 4:28pm.", tagline2: "make my mark on the world, and have a happy family.")


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

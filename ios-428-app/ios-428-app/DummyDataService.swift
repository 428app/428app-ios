//
//  DummyDataService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

import UIKit
// TODO: To tear down this extension and replace it with Firebase DataService

// Set up topics

func t(daysAgo: Double) -> Date {
    return Date().addingTimeInterval(-daysAgo * 60.0 * 60.0 * 24.0)
}

func m(minutesAgo: Double) -> Date {
    return Date().addingTimeInterval(-minutesAgo * 60.0)
}


func loadTopicMessages() -> [TopicMessage] {
    let m1 = TopicMessage(tmid: "1", parentTid: "4", posterUid: "999", posterName: "Leonard", postercoverImageName: "business", text: "Creating a million jobs is not easy. Let's start with improving our own education system first.", date: m(minutesAgo: 200))
    let m2 = TopicMessage(tmid: "2", parentTid: "4", posterUid: "999", posterName: "Jenny", postercoverImageName: "biology", text: "Just open more restaurants so we get more jobs... and more food!", date: m(minutesAgo: 195))
    let m3 = TopicMessage(tmid: "3", parentTid: "4", posterUid: "999", posterName: "Yihang", postercoverImageName: "business", text: "The economy is that bad right now and the financial sector where I come from is being hit that heavily. Let's think about how to preserve our own jobs first before thinking of how automation is replacing future jobs.", date: m(minutesAgo: 192), isSender: true)
    let m4 = TopicMessage(tmid: "4", parentTid: "4", posterUid: "999", posterName: "Tomas", postercoverImageName: "computer", text: "Yihang, you're right in saying that. Times are tough, even interviews for tech jobs are dwindling, and too many people are fighting for those coveted positions.", date: m(minutesAgo: 180))
    let m5 = TopicMessage(tmid: "5", parentTid: "4", posterUid: "999", posterName: "Leonard", postercoverImageName: "business", text: "No one addressing the problem with education? I thought about it for a while and realized our education system is not creating enough creative and bold visionaries who can go on and generate more jobs. We need more open-ended education, and exclude memorization of text.", date: m(minutesAgo: 100))
    let m6 = TopicMessage(tmid: "6", parentTid: "4", posterUid: "999", posterName: "Thomas", postercoverImageName: "electricengineering", text: "Let's not focus on such a grandiose idea for now. Let's think about how each of us can generate 5-10 jobs by starting small businesses so that collectively we can achieve this vision. After all, the startups ARE the backbone of the American economy.", date: m(minutesAgo: 75))
    // Sorted by earliest first
    return [m1, m2, m3, m4, m5, m6]
}


func loadTopics() -> [Topic] {
    var topics = [Topic]()
    let topic1 = Topic(tid: "1", prompt: "Healthcare in the United States is badly broken. We are getting close to spending 20% of our GDP on healthcare.", imageName: "topic-healthcare", description: "How do you make healthcare better for less money, and not exploit the system by overcharging. Think about preventative healthcare, as this is probably the highest-leverage way to improve health. Sensors and data are interesting in lots of different areas, but especially for healthcare. Medical devices also seem like fertile ground for startups.", date: t(daysAgo: 1))
    let topic2 = Topic(tid: "2", prompt: "We are starting to augment humans.", imageName: "topic-augmentation", description: "This is a very general category because there are a lot of different ways to do this. Biotech can help us live longer and be smarter. Robots can help us do physical things we otherwise couldn’t. Software can help us focus on simple actions that make us happier and help large groups of us organize ourselves better. And on and on and on.", date: t(daysAgo: 2))
    let topic3 = Topic(tid: "3", prompt: "About half of all energy is used on transportation, and people spend a huge amount of time unhappily commuting.", imageName: "topic-cars", description: "Face-to-face interaction is still really important; people still need to move around. And housing continues to get more expensive, partially due to difficulties in transportation. We’re interested in better ways for people to live somewhere nice, work together, and have easier commutes. Specifically, lightweight, short-distance personal transportation is something we’re interested in.", date: t(daysAgo: 3))
    let topic4 = Topic(tid: "4", prompt: "Let us think of an idea to create a million jobs.", imageName: "topic-jobs", description: "There are a lot of areas where it makes sense to divide labor between humans and computers-—we are very good at some things computers are terrible at and vice versa—-and some of these require huge amounts of human resources. This is both good for the world and likely a good business strategy—-as existing jobs go away, a company that creates a lot of new jobs should be able to get a lot of talented people.", date: t(daysAgo: 4), topicMessages: loadTopicMessages(), latestMessageDate: loadTopicMessages().last!.date, isSeen: false)
    let topic5 = Topic(tid: "5", prompt: "New celebrities don’t get discovered by talent agents, they get discovered directly by their fans on YouTube.", imageName: "topic-celebrities", description: "In 2014, movies had their worst summer since 1997. Just like future celebrities are unlikely to get their start with talent agencies, future content consumers will watch content online instead of at the theater, and probably in very different ways. Celebrities now have direct relationships with their fans. They can also distribute content in new ways. There are almost certainly huge new businesses that will get built as part of this shift.", date: t(daysAgo: 5))
    let topic6 = Topic(tid: "6", prompt: "The world’s financial systems are increasingly unable to meet the demands of consumers and businesses.", imageName: "topic-finance", description: "That makes some sense because regulations designed to protect customers can’t change fast enough to keep up with the pace at which technology is changing the needs of those customers. This mismatch creates inefficiencies at almost every level of the financial system. It impacts how people invest their savings, how businesses gain access to capital to grow, how risk is priced and insured, and how financial firms do business with each other. We think that software will accelerate the pace at which financial services change and will eventually shift the nature of regulations. We want to fund companies with novel ideas of how to make that happen.", date: t(daysAgo: 6))
    let topic7 = Topic(tid: "7", prompt: "Securing computers is difficult because the work required is so asymmetric", imageName: "topic-security", description: "The attacker only has to find one flaw, while a defender has to protect against every possible weakness. Unfortunately, securing computers isn’t just hard - it’s critically and increasingly important. As the software revolution continues and more critical information and systems are connected to the Internet, we become more vulnerable to cyberattacks and the disruption is more severe.", date: t(daysAgo: 7))
    let topic8 = Topic(tid: "8", prompt: "There are lots of cheap, proven ways to save and improve people’s lives. They should be reaching everyone.", imageName: "topic-nonprofits", description: "Why do so many people in the developing world still suffer for lack of simple things like bednets, vaccines, and iodized salt? Part of the problem is money, and we’re interested in new ways to get people to give. Part of it is execution, and we’d love to see nonprofits that are truly data-literate and metrics-driven closing these gaps. Organizations like GiveWell have large amounts of funding at the ready for provably effective global health interventions.", date: t(daysAgo: 8))
    topics = [topic1, topic2, topic3, topic4, topic5, topic6, topic7, topic8]
    return topics
}


// Set up profiles
let jennyprof = Profile(uid: "1", name: "Jenny", coverImageName: "jenny-bg", profileImageName: "jenny-profile", age: 22, location: "USA, MA, Cambridge", org: "Maxwell Dworkin Corp", school: "Harvard University of Wizardry, Angels and the Forbidden Arts", discipline: "Biology", tagline1: "understanding mutations in DNA and how they lead to cancer. I'm doing it because I've always enjoyed Biology. In middle school I dissected an animal's heart, and my interest just escalated from there!", tagline2: "make a breakthrough in cancer research and win a Nobel prize. That's a big statement I know, but gotta dream big right?")
let yihangprof = Profile(uid: "99", name: "Yihang", coverImageName: "yihang-bg", profileImageName: "yihang-profile", age: 24, location: "USA, MA, Cambridge", org: "428", school: "Harvard University", discipline: "Business", tagline1: "an app that lets you easily meet people from different industries. There's LinkedIn, and we're LinkedOut. On the app, you get matched with a new connection and introduced to a new topic once a day, at 4:28pm.", tagline2: "make my mark on the world, and have a happy family.")


// Set up messages
extension ConnectionsController {

    func setupData() {
//        // Create messages
//        let jenny = Connection(uid: "1", name: "Jenny", profileImageName: "jenny-profile", coverImageName: "biology")
//        let spandan = Connection(uid: "2", name: "Spandan", profileImageName: "spandan-profile", coverImageName: "computer")
//        let tomas = Connection(uid: "3", name: "Tomas", profileImageName: "tomas-profile", coverImageName: "computer")
//        let kyooeun = Connection(uid: "4", name: "Kyooeun", profileImageName: "kyooeun-profile", coverImageName: "eastasian")
//        let emil = Connection(uid: "5", name: "Emil", profileImageName: "emil-profile", coverImageName: "physics")
//        let kezi = Connection(uid: "6", name: "Kezi", profileImageName: "kezi-profile", coverImageName: "physics")
//        
//        _ = self.createMessageForconnection(tomas, text: "Programming assignments take up so much time. But they are worthwhile.", minutesAgo: 60 * 24 * 3, isSender: true)
//        _ = self.createMessageForconnection(kyooeun, text: "China is a wonderland. I frequent Beijing whenever I go back to do research.", minutesAgo: 60 * 24, isSeen: false)
//        _ = self.createMessageForconnection(emil, text: "Quantum mechanics is my true love. You should go check it out.", minutesAgo: 25, isSeen: false)
//        _ = self.createMessageForconnection(kezi, text: "What are your views about time travel? Is it PHYSICALLY possible?", minutesAgo: 29, isSender: true)
//
//        createLeoMessages()
//        createThomasMessages()
//        _ = self.createMessageForconnection(jenny, text: "I want to eat food now! Give me food or else!!", minutesAgo: 60 * 24 * 400)
//        _ = self.createMessageForconnection(spandan, text: "I love computer vision! Let's hack something cool together.", minutesAgo: 60 * 24 * 10)
//        
//        // Set messages
//        self.latestMessages = connectionToLatestMessage.flatMap { (_: String, v: Message) -> Message? in
//            return v
//        }
//        self.latestMessages = self.latestMessages.sorted{($0.date.timeIntervalSince1970) > ($1.date.timeIntervalSince1970)}
    }
    
    fileprivate func createLeoMessages() {
        let leo = Connection(uid: "7", name: "Leonard", profileImageName: "leo-profile", disciplineImageName: "business")
        _ = self.createMessageForconnection(leo, text: "Hello, my name is Leonard. Nice to meet you!", minutesAgo: 200)
        _ = self.createMessageForconnection(leo, text: "What do you do?", minutesAgo: 198)
        _ = self.createMessageForconnection(leo, text: "Hi! My name is Yihang.", minutesAgo: 90, isSender: true)
        _ = self.createMessageForconnection(leo, text: "I'm currently pursuing a Masters in Computational Science & Engineering.", minutesAgo: 89, isSender: true)
        _ = self.createMessageForconnection(leo, text: "That's cool! Okay I'll brb and talk to you later all right?", minutesAgo: 20)
        _ = self.createMessageForconnection(leo, text: "Data science is every where these days. Do you think you want to be involved in that?", minutesAgo: 15, isSender: true)
    }
    
    fileprivate func createThomasMessages() {
        let thomas = Connection(uid: "8", name: "Thomas", profileImageName: "thomas-profile", disciplineImageName: "electricengineering")
        _ = self.createMessageForconnection(thomas, text: "Let's engage in cooking and combine it with art! That way it's a lot more engaging. Don't you think we should do it immediately? Hurray!", minutesAgo: 60 * 24 * 1.7)
        _ = self.createMessageForconnection(thomas, text: "Hey, you haven't replied. You there?", minutesAgo: 60 * 24 * 1.6)
        _ = self.createMessageForconnection(thomas, text: "Anyway just thought of a new twist. Let's meet for a while.", minutesAgo: 60 * 24 * 1.5)
        
        // Response message
        _ = self.createMessageForconnection(thomas, text: "Okay, okay I'm finally replying now! Hi!", minutesAgo: 60 * 24 * 1.4, isSender: true)
        _ = self.createMessageForconnection(thomas, text: "Ok great. Are you free anytime soon to discuss some of my ideas? We can play ping pong too if you want.", minutesAgo: 60 * 24 * 1.3)
        _ = self.createMessageForconnection(thomas, text: "Sure. How about 6pm tomorrow at Richard's Basement?", minutesAgo: 60 * 24 * 1.25, isSender: true)
        _ = self.createMessageForconnection(thomas, text: "Also I'm not so sure how free I am from tomorrow onwards. I'm going to be coding 428 non stop until I finally finish implementing it! This is a product that has real value for people - Imagine you having connections from multiple different disciplines! And all those disciplines are already right here at Harvard, but unfortunately with no easy way to connect them... until now!!", minutesAgo: 60 * 24 * 1.2, isSender: true)
        _ = self.createMessageForconnection(thomas, text: "OK good luck with your crazy ideas then! I hope you do well in that.", minutesAgo: 60 * 24 * 1.19)
        _ = self.createMessageForconnection(thomas, text: "Whoever said it is the end of Moore's law is kidding!", minutesAgo: 60 * 24 * 1.1, isSeen: false)
    }

    fileprivate func createMessageForconnection(_ connection: Connection, text: String, minutesAgo: Double, isSender: Bool = false, isSeen: Bool = true) -> Message {
        let message = Message(mid: "\(midAutoId)", text: text, connection: connection, date: Date().addingTimeInterval(-minutesAgo * 60), isSender: isSender, isSeen: isSeen)
        midAutoId += 1
        connection.addMessage(message: message) // connection has all their own messages
        let uid = connection.uid
        if connectionToMinutesAgo[uid] == nil || connectionToMinutesAgo[uid]! > minutesAgo {
            connectionToMinutesAgo[uid] = minutesAgo
            connectionToLatestMessage[uid] = message
        }
        return message
    }
}

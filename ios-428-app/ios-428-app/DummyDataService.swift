////
////  DummyDataService.swift
////  ios-428-app
////
////  Created by Leonard Loo on 10/10/16.
////  Copyright © 2016 428. All rights reserved.
////
//
//import Foundation
//
//import UIKit
//// TODO: To tear down this extension and replace it with Firebase DataService
//
//// Set up classrooms
//
//func t(daysAgo: Double) -> Date {
//    return Date().addingTimeInterval(-daysAgo * 60.0 * 60.0 * 24.0)
//}
//
//func m(minutesAgo: Double) -> Date {
//    return Date().addingTimeInterval(-minutesAgo * 60.0)
//}
//
//
//func loadClassroomMessages() -> [ClassroomMessage] {
//    let m1 = ClassroomMessage(tmid: "1", parentTid: "4", posterUid: "999", posterName: "Leonard", posterDiscipline: "leo-profile", text: "Omg if that happens fertilization will happen without us even knowing. That's dangerous!", date: m(minutesAgo: 200))
//    let m2 = ClassroomMessage(tmid: "2", parentTid: "4", posterUid: "999", posterName: "Jenny", posterDiscipline: "jenny-profile", text: "Wait, wouldn't it be even crazier? Sperm could potentially travel back in time. I could already start thinking of all kinds of medical applications of a time travel sperm.", date: m(minutesAgo: 195))
//    let m3 = ClassroomMessage(tmid: "3", parentTid: "4", posterUid: "999", posterName: "Yihang", posterDiscipline: "business", text: "LOL. You know they say anything that travels fast creates a black hole... Get it?", date: m(minutesAgo: 192), isSentByYou: true)
//    let m4 = ClassroomMessage(tmid: "4", parentTid: "4", posterUid: "999", posterName: "Tomas", posterDiscipline: "tomas-profile", text: "Yihang, you're right in saying that. Times are tough, even interviews for tech jobs are dwindling, and too many people are fighting for those coveted positions. So this is more text blah blah blah blah blah blah.", date: m(minutesAgo: 180))
//    let m5 = ClassroomMessage(tmid: "5", parentTid: "4", posterUid: "999", posterName: "Leonard", posterDiscipline: "business", text: "No one addressing the problem with education? I thought about it for a while and realized our education system is not creating enough creative and bold visionaries who can go on and generate more jobs. We need more open-ended education, and exclude memorization of text.", date: m(minutesAgo: 100))
//    let m6 = ClassroomMessage(tmid: "6", parentTid: "4", posterUid: "999", posterName: "Thomas", posterDiscipline: "electricengineering", text: "Let's not focus on such a grandiose idea for now. Let's think about how each of us can generate 5-10 jobs by starting small businesses so that collectively we can achieve this vision. After all, the startups ARE the backbone of the American economy.", date: m(minutesAgo: 75))
//    // Sorted by earliest first
//    return [m1, m2, m3, m4, m5, m6]
//}
//
//
//func loadClassrooms() -> [Classroom] {
//    var classrooms = [Classroom]()
//    let classroom1 = Classroom(tid: "1", prompt: "Physics I, Question 1, 0", imageName: "classroom-physics", description: "How do you make healthcare better for less money, and not exploit the system by overcharging. Think about preventative healthcare, as this is probably the highest-leverage way to improve health. Sensors and data are interesting in lots of different areas, but especially for healthcare. Medical devices also seem like fertile ground for startups.", date: t(daysAgo: 1))
//    let classroom2 = Classroom(tid: "2", prompt: "History IV, Question 8, 4", imageName: "classroom-history", description: "This is a very general category because there are a lot of different ways to do this. Biotech can help us live longer and be smarter. Robots can help us do physical things we otherwise couldn’t. Software can help us focus on simple actions that make us happier and help large groups of us organize ourselves better. And on and on and on.", date: t(daysAgo: 2), hasSeen: false)
//    let classroom3 = Classroom(tid: "3", prompt: "Computer Science II, Question 15, 0", imageName: "classroom-finance", description: "What happens when sperm travels at the speed of light?", date: t(daysAgo: 3))
//    let classroom4 = Classroom(tid: "4", prompt: "Let us think of an idea to create a million jobs.", imageName: "classroom-fertility", description: "There are a lot of areas where it makes sense to divide labor between humans and computers-—we are very good at some things computers are terrible at and vice versa—-and some of these require huge amounts of human resources. This is both good for the world and likely a good business strategy—-as existing jobs go away, a company that creates a lot of new jobs should be able to get a lot of talented people.", date: t(daysAgo: 4), classroomMessages: loadClassroomMessages(), latestMessageDate: loadClassroomMessages().last!.date, hasSeen: false)
//    let classroom5 = Classroom(tid: "5", prompt: "New celebrities don’t get discovered by talent agents, they get discovered directly by their fans on YouTube.", imageName: "classroom-celebrities", description: "In 2014, movies had their worst summer since 1997. Just like future celebrities are unlikely to get their start with talent agencies, future content consumers will watch content online instead of at the theater, and probably in very different ways. Celebrities now have direct relationships with their fans. They can also distribute content in new ways. There are almost certainly huge new businesses that will get built as part of this shift.", date: t(daysAgo: 5))
//    let classroom6 = Classroom(tid: "6", prompt: "The world’s financial systems are increasingly unable to meet the demands of consumers and businesses.", imageName: "classroom-finance", description: "That makes some sense because regulations designed to protect customers can’t change fast enough to keep up with the pace at which technology is changing the needs of those customers. This mismatch creates inefficiencies at almost every level of the financial system. It impacts how people invest their savings, how businesses gain access to capital to grow, how risk is priced and insured, and how financial firms do business with each other. We think that software will accelerate the pace at which financial services change and will eventually shift the nature of regulations. We want to fund companies with novel ideas of how to make that happen.", date: t(daysAgo: 6))
//    let classroom7 = Classroom(tid: "7", prompt: "Securing computers is difficult because the work required is so asymmetric", imageName: "classroom-security", description: "The attacker only has to find one flaw, while a defender has to protect against every possible weakness. Unfortunately, securing computers isn’t just hard - it’s critically and increasingly important. As the software revolution continues and more critical information and systems are connected to the Internet, we become more vulnerable to cyberattacks and the disruption is more severe.", date: t(daysAgo: 7))
//    let classroom8 = Classroom(tid: "8", prompt: "There are lots of cheap, proven ways to save and improve people’s lives. They should be reaching everyone.", imageName: "classroom-nonprofits", description: "Why do so many people in the developing world still suffer for lack of simple things like bednets, vaccines, and iodized salt? Part of the problem is money, and we’re interested in new ways to get people to give. Part of it is execution, and we’d love to see nonprofits that are truly data-literate and metrics-driven closing these gaps. Organizations like GiveWell have large amounts of funding at the ready for provably effective global health interventions.", date: t(daysAgo: 8))
//    classrooms = [classroom1, classroom2, classroom3, classroom4, classroom5, classroom6, classroom7, classroom8]
//    return classrooms
//}
//
//
//// Set up profiles
////let jennyprof = Profile(uid: "1", name: "Jenny", coverImageName: "jenny-bg", profileImageName: "jenny-profile", age: 22, location: "USA, MA, Cambridge", org: "Maxwell Dworkin Corp", school: "Harvard University of Wizardry, Angels and the Forbidden Arts", discipline: "Biology", tagline1: "understanding mutations in DNA and how they lead to cancer. I'm doing it because I've always enjoyed Biology. In middle school I dissected an animal's heart, and my interest just escalated from there!", tagline2: "make a breakthrough in cancer research and win a Nobel prize. That's a big statement I know, but gotta dream big right?")
////let yihangprof = Profile(uid: "99", name: "Yihang", coverImageName: "yihang-bg", profileImageName: "yihang-profile", age: 24, location: "USA, MA, Cambridge", org: "428", school: "Harvard University", discipline: "Business", tagline1: "an app that lets you easily meet people from different industries. There's LinkedIn, and we're LinkedOut. On the app, you get matched with a new connection and introduced to a new classroom once a day, at 4:28pm.", tagline2: "make my mark on the world, and have a happy family.")
//

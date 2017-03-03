//
//  Discipline.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/8/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

let DISCIPLINE_OPTIONS = [ "",
                           "Agriculture",
                           "Astronomy",
                           "Biology",
                           "Chemistry",
                           "Computer Science",
                           "Culture",
                           "Economics",
                           "Education",
                           "Engineering",
                           "Fashion",
                           "Finance",
                           "Geography",
                           "Health",
                           "History",
                           "Languages",
                           "Law",
                           "Literature",
                           "Mathematics",
                           "Performing Arts",
                           "Philosophy",
                           "Physics",
                           "Political Sciences",
                           "Psychology",
                           "Sports",
                           "Theology",
                           "Visual Arts" ]

// Maps in same, sorted order as options above
let DISCIPLINE_ICONS = [ "",
                         "agriculture",
                         "astronomy",
                         "biology",
                         "chemistry",
                         "computerscience",
                         "culture",
                         "economics",
                         "education",
                         "engineering",
                         "fashion",
                         "finance",
                         "geography",
                         "health",
                         "history",
                         "languages",
                         "law",
                         "literature",
                         "mathematics",
                         "performingarts",
                         "philosophy",
                         "physics",
                         "politicalsciences",
                         "psychology",
                         "sports",
                         "theology",
                         "visualarts" ]

let DISCIPLINE_DESCRIPTIONS = [
"",
"Learn about cultivation of the soil for the growing of crops and the rearing of animals to provide food, wool, and other products",
"Learn about earthly or celestial objects and phenomena",
"Learn the study of life and living organisms, including their structure, function, growth, evolution, distribution, identification and taxonomy",
"Learn the composition, structure, properties and change of matter",
"Learn the theory, experimentation, and engineering that form the basis for the design and use of computers",
"Learn about various cultures' knowledge, beliefs, art, morals, law and customs",
"Learn knowledge concerned with the production, consumption and transfer of wealth",
"Explore how humans learn in educational settings, the effectiveness of educational interventions and the psychology of teaching",
"Learn the industrial applications of mathematics and science",
"Explore the popular style or practice in clothing, footwear, accessories, makeup, body and furniture",
"Learn about investing and how to manage your money",
"Learn Earthly phenomena, from the form of lands to their features and inhabitants",
"Learn the science and practice of the diagnosis, treatment and prevention of disease",
"Learn and analyze sequences of past events",
"Learn language and its structure",
"Learn how different countries regulate the actions of their members",
"Learn the artistic and intellectual value of various written pieces",
"Learn the abstract science of number, quantity and space",
"Learn how artists use their voices through music and their bodies through dance",
"Learn fundamental issues concerning our existence, knowledge, values, reason, mind and language",
"Learn matter and its behavior through space and time along with related concepts such as energy and force",
"Learn systems of government, and analyze political activities and behavior",
"Learn behavior and mind while embracing aspects of conscious and unconscious experience",
"Learn about sports and nutrition, and the science behind them",
"Learn the nature of God and religious beliefs",
"Learn how artists use paint, canvas or various materials to create art objects"
]

func getDisciplineIcon(discipline: String) -> String {
    let ind = DISCIPLINE_OPTIONS.index(of: discipline)
    if ind != nil && ind! > 0 && ind! < DISCIPLINE_ICONS.count {
        return DISCIPLINE_ICONS[ind!]
    }
    return ""; // Discipline cannot be found, return blank icon
}

func getDisciplineName(iconImageName: String) -> String {
    let ind = DISCIPLINE_ICONS.index(of: iconImageName)
    if ind != nil && ind! > 0 && ind! < DISCIPLINE_OPTIONS.count {
        return DISCIPLINE_OPTIONS[ind!]
    }
    return ""; // Discipline name cannot be found, return empty string
}

func getDisciplineDescription(discipline: String) -> String {
    let ind = DISCIPLINE_OPTIONS.index(of: discipline)
    if ind != nil && ind! > 0 && ind! < DISCIPLINE_DESCRIPTIONS.count {
        return DISCIPLINE_DESCRIPTIONS[ind!]
    }
    return ""; // Discipline cannot be found, return blank icon
}

func getIndexGivenDiscipline(discipline: String) -> Int {
    for i in 0...DISCIPLINE_OPTIONS.count {
        if DISCIPLINE_OPTIONS[i] == discipline {
            return i
        }
    }
    return 0 // Returns the index of the empty discipline if not found
}

// MARK: Sound Smarts

// Default soundsmarts, that will be further populated from the server
// NOTE: $'s are replaced by an input name, and *'s are replaced by discipline
var soundSmarts = [
    "This question stimulates me. Anyone else get the same kind of reaction?",
    "$, how was your day?",
    "I was looking at profiles and gosh I gotta say $, you're pretty attractive LOL 😍",
    "Guys, let's discuss the question. It seems interesting.",
    "So how do you guys find 428 so far?",
    "LOL this is too easy for me!",
    "$, could I get your phone number please? Wait I think there's a private message function...",
    "$ has gotta be the smartest person in this playgroup",
    "What's up everybody? 🤘",
    "Just wondering.. what made you guys download this app?",
    "So far I found this app pretty interesting. Especially the concept of getting a question a day. You guys enjoying it so far?",
    "$, you look like you have an answer to this question",
    "$, would you want to be my friend?",
    "I think this question pertains the most to $... what do you think? 🤗",
    "😂😂😂 What a question lol",
    "😍 $ I've been dreaming about you all my life",
    "😡😡😡 Guys speak up!",
    "Where are you guys from?",
    "Well this is awkward",
    "You guys don't know about me but I bet you guys want to",
    "This question gives me the goosebumps.",
    "$ what do you think is the answer to this?",
    "I have a confession to make. $, you look cute. 😍",
    "$, I have an obsession over you. Oops wrong chat",
    "$ you're so funny sometimes you know 😓",
    "Wow I never thought about something like that before.",
    "Guys this is an odd question, but who do you think is the most attractive person in this group?",
    "Am I the only one who loves this app??! 🤗",
    "Something odd happened yesterday..",
    "Guys, name one important thing we had today that we did not 10 years ago.",
    "I'm using this sound smart function too much because I don't think I'm smart or social enough. 😒",
    "$ will you marry me?",
    "$ sometimes you still give me butterflies in my stomach ❤️️",
    "There's someone in this group that I think is really really smart. Wanna guess who? 😅",
    "If the world ends tomorrow, what will all of you do?",
    "My lifetime dream has always been to discover the world. I know this sounds kinda cheesy to talk about it here, but I'm really glad I can at least discover more of the academic world through this app 😌",
    "I wanna ask you guys for advice about something 😕",
    "Guys, which playgroup are you most excited about?",
    "$ were you on the news the other day? 😯",
    "😌 Ahh just had a great bath. Ok back to 428!",
    "😤 Why would you say something like that",
    "👌 $ you brought up a good point.",
    "LOL omg I can't wait for the answer to this one 😂",
    "This group might have been a lot better if only there were a comedian here. But it's okay I'll be the stand-in. 😎",
    "I wanted to sound smart but I think I'm failing. Whatever, what do you guys think about today's question?",
    "Just a show of hands, how many of you love this group?",
    "It's been a while, and since some of us are not that far from one another, wanna meet up?",
    "So far I've learnt a lot from 428. How about you guys?",
    "What's your fave playgroup here so far??",
    "What's the craziest experience you had on this app so far? 😱😱 ",
    "GUYS guess what happened just now when I was having lunch 😂😂😂",
    "$",
    "Plans this weekend guys?",
    "I'm just curious, how many of you guys are attached?",
    "Ok I'm gonna go a bit deeper here and ask this: What's your biggest failure?",
    "Anybody has any idea what superlatives mean?",
    "$, just curious. What do you do these days?",
    "Hey $! You look familiar 🤔",
    "How many of you guys here actually already know each another?",
    "n jdfngkjnkjg nkjdngkjfngjk ndfkjng kjnf kjf",
    "Sorry for not posting yet. I'll get back with an answer to this question soon k",
    "Gonna take a nap guys, brb 😴",
    "I'm still waiting for my next playgroup, anybody got yours yet?",
    "I'm getting a headache thinking about this 😪",
    "🙌 Good morning everybody!",
    "Who loves singing here???",
    "Plans tonight? I'm heading to this club near my place",
    "I think we have to work together to think of a good answer for this one lol",
    "This question is too tough for me.",
    "I remember reading about this somewhere before.. errr anybody knows?",
    "$ you look incredibly smart. Are you sure you're human? 😯",
    "$ I swear I've seen you on the train before 🤔",
    "Hey guys! Just came home. What you guys up to?",
    "I love girls. Ugh I swear I didn't type that",
    "You know when I was 12 my parents thought I was a genius. Look what happened",
    "Some people call me James Bond",
    "😶😐😑😯😦😧😮😲",
    "Sec, got a mindblock",
    "I love *!!! But never really got the chance to explore it as much as I like."
]

// Generates a sound troll given person's name which we might randomly use
func generateSoundSmart(name: String, discipline: String) -> String {
    if soundSmarts.count == 0 {
        return "Sup everybody, just want to say I love all of you guys!"
    }
    let i = Int(arc4random_uniform(UInt32(soundSmarts.count)))
    var soundSmart = soundSmarts[i]
    soundSmart = soundSmart.replacingOccurrences(of: "$", with: name)
    soundSmart = soundSmart.replacingOccurrences(of: "*", with: discipline)
    return soundSmart
}

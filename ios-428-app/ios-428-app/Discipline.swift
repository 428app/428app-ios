//
//  Discipline.swift
//  ios-428-app
//
//  Created by Leonard Loo on 11/8/16.
//  Copyright © 2016 428. All rights reserved.
//

import Foundation

let DISCIPLINE_OPTIONS = ["", "Performing arts", "Visual arts", "Geography", "History", "Languages", "Literature", "Philosophy", "Economics", "Law", "Political sciences", "Sports", "Theology", "Biology", "Chemistry", "Earth and Space sciences", "Mathematics", "Physics", "Finance", "Agriculture", "Computer science", "Engineering", "Health", "Psychology", "Culture", "Life hacks", "Education", "Fashion", "Romance"];

// Maps in same order as options above

let DISCIPLINE_ICONS = ["", "performingarts", "visualarts", "geography", "history", "languages", "literature", "philosophy", "economics", "law", "politicalsciences", "sports", "theology", "biology", "chemistry", "earthandspacesciences", "mathematics", "physics", "finance", "agriculture", "computerscience", "engineering", "health", "psychology", "culture", "lifehacks", "education", "fashion", "romance"];

let DISCIPLINE_DESCRIPTIONS = [
"",
"The classroom where you learn how artists use their voices or their bodies, like dance and music",
"The classroom where you learn how artists use paint, canvas or various materials to create art objects",
"The classroom where you learn the form of lands, the features, the inhabitants, and the phenomena of Earth",
"The classroom where you examine and analyze a sequence of past events",
"The classroom where you learn language and its structure",
"The classroom where you learn the artistic or intellectual value of various written pieces",
"The classroom where you learn general and fundamental problems concerning matters such as existence, knowledge, values, reason, mind, and language",
"The classroom where you learn different factors that determine the production, distribution, and consumption of goods and services",
"The classroom where you learn how different countries regulate the actions of its members",
"The classroom where you learn systems of government, and the analysis of political activities, thoughts and behavior",
"The classroom where you learn different types of sports and exercises",
"The classroom where you learn the nature of God and religious belief",
"The classroom where you learn the study of life and living organisms, including their structure, function, growth, evolution, distribution, identification and taxonomy",
"The classroom where you learn the composition, structure, properties and change of matter",
"The classroom where you learn about earthly or celestial objects and phenomena",
"The classroom where you learn numbers, structure, space, and change",
"The classroom where you learn matter and its behavior through space and time, along with related concepts such as energy and force",
"The classroom where you learn about investing and how to manage your money",
"The classroom where you learn about cultivation of the soil for the growing of crops and the rearing of animals to provide food, wool, and other products",
"The classroom where you learn the theory, experimentation, and engineering that form the basis for the design and use of computers",
"The classroom where you learn the application of mathematics and scientific, economic, social, and practical knowledge",
"The classroom where you learn the science and practice of the diagnosis, treatment, and prevention of disease",
"The classroom where you learn behavior and mind, embracing all aspects of conscious and unconscious experience as well as thought",
"The classroom where you learn how various cultures' knowledge, beliefs, art, morals, law and customs",
"The classroom where you learn how to manage your time and daily activities in a more efficient way",
"The classroom where you explore how humans learn in educational settings, the effectiveness of educational interventions, the psychology of teaching",
"The classroom where you explore the popular style or practice, especially in clothing, footwear, accessories, makeup, body, or furniture",
"The classroom where you can explore how chemicals flooding our system influence who we choose and how we feel"
]

func getDisciplineIcon(discipline: String) -> String {
    let ind = DISCIPLINE_OPTIONS.index(of: discipline)
    if ind != nil && ind! > 0 && ind! < DISCIPLINE_ICONS.count {
        let icon = DISCIPLINE_ICONS[ind!]
        log.info(icon)
        return DISCIPLINE_ICONS[ind!]
    }
    return ""; // Discipline cannot be found, return blank icon
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

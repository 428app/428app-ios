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
"Learn how various cultures' knowledge, beliefs, art, morals, law and customs",
"Learn systems of government, and the analysis of political activities, thoughts and behavior",
"Explore how humans learn in educational settings, the effectiveness of educational interventions, the psychology of teaching",
"Learn the application of mathematics and scientific, economic, social, and practical knowledge",
"Explore the popular style or practice, especially in clothing, footwear, accessories, makeup, body, or furniture",
"Learn about investing and how to manage your money",
"Learn the form of lands, the features, the inhabitants, and the phenomena of Earth",
"Learn the science and practice of the diagnosis, treatment, and prevention of disease",
"The classroom where you examine and analyze a sequence of past events",
"Learn language and its structure",
"Learn how different countries regulate the actions of its members",
"Learn the artistic or intellectual value of various written pieces",
"Learn numbers, structure, space, and change",
"Learn how artists use their voices or their bodies, like dance and music",
"Learn general and fundamental problems concerning matters such as existence, knowledge, values, reason, mind, and language",
"Learn matter and its behavior through space and time, along with related concepts such as energy and force",
"Learn systems of government, and the analysis of political activities, thoughts and behavior",
"Learn behavior and mind, embracing all aspects of conscious and unconscious experience as well as thought",
"Learn different types of sports and exercises",
"Learn the nature of God and religious belief",
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

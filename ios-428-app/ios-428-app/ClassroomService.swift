//
//  ClassroomService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 1/4/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation

import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FBSDKCoreKit
import FBSDKLoginKit

// Extends DataService to house Classroom calls
extension DataService {
    
    func checkIfThereAreAnyClassrooms(completed: @escaping (_ haveClassrooms: Bool) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        REF_USERS.child("\(uid)/classrooms").observeSingleEvent(of: .value, with: { snapshot in
            completed(snapshot.exists())
        })
    }
    
    // Observe for added classroom of a user, used in ClassroomsController
    func observeClassroomAdded(completed: @escaping (_ isSuccess: Bool, _ cid: String) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        // Grabs the user's classrooms
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/classrooms")
        
        // Observed on value as not childAdded, as classrooms might be deleted in the future
        let handle = ref.observe(.childAdded, with: { snapshot in
            if !snapshot.exists() {
                completed(false, "")
                return
            }
            guard var _ = snapshot.value as? [String: Any] else {
                completed(false, "")
                return
            }
            completed(true, snapshot.key)
            return
        })
        return (ref, handle)
    }
    
    // Observe updates of a single classroom for a user, used in ClassroomsController
    func observeClassroomUpdates(cid: String, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) ->(FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/classrooms/\(cid)")
        // Observed on value as not childAdded, as classrooms might be deleted in the future
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, nil)
                return
            }
            guard var classDict = snapshot.value as? [String: Any] else {
                completed(false, nil)
                return
            }
            let cid = snapshot.key
            
            guard let questionNum = classDict["questionNum"] as? Int, let discipline = classDict["discipline"] as? String, let questionImage = classDict["questionImage"] as? String, let questionShareImage = classDict["questionShareImage"] as? String, let questionText = classDict["questionText"] as? String, let timeReplied = classDict["timeReplied"] as? Double, let hasUpdates = classDict["hasUpdates"] as? Bool else {
                completed(false, nil)
                return
            }
            let classroom = Classroom(cid: cid, title: discipline, timeReplied: timeReplied, hasUpdates: hasUpdates, questionNum: questionNum, questionText: questionText, imageName: questionImage, shareImageName: questionShareImage)
            completed(true, classroom)
            return
        })
        return (ref, handle)
    }
    
    fileprivate func isIdenticalArrays(arr1: [Any], arr2: [Any]) -> Bool {
        let set1 = NSCountedSet(array: arr1)
        let set2 = NSCountedSet(array: arr2)
        return set1 == set2
    }
    
    // Observe single classroom used in ChatClassroomController
    func observeSingleClassroom(classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let cid = classroom.cid
        let ref: FIRDatabaseReference = REF_CLASSROOMS.child(cid)
        let handle = ref.observe(.value, with: { classSnap in
            guard let classDict = classSnap.value as? [String: Any], let classmateAndSuperlativeType = classDict["memberHasVoted"] as? [String: Int], let questionsDict = classDict["questions"] as? [String: Any] else {
                completed(false, classroom)
                return
            }
            // Download profiles, and find this user's superlative type
            var members: [Profile] = [Profile]()

            // Used as comparison to know if async task is done
            var memberIds: [String] = [String]()
            let totalMemberIds: [String] = Array(classmateAndSuperlativeType.keys)

            var didYouKnowId = ""
            if let did = classDict["didYouKnow"] as? String {
                didYouKnowId = did
            }
            
            // Assemble skeleton of questions, load question+answers later only when user clicks Answers
            var questions: [Question] = [Question]()
            
            for (qid, questionDict_) in questionsDict {
                if let questionDict = questionDict_ as? [String: Any], let questionTime = questionDict["timestamp"] as? Double, let userVoteIntForQuestion = questionDict[uid] as? Int, let userVoteForQuestion = QuestionVoteType(rawValue: userVoteIntForQuestion) {
                    questions.append(Question(qid: qid, timestamp: questionTime, userVote: userVoteForQuestion))
                }
            }
            
            var superlativeType: SuperlativeType = SuperlativeType.NOTVOTED
            
            for (uid_, superlativeType_) in classmateAndSuperlativeType {
                
                // Find superlative type of this user
                if uid_ == uid {
                    superlativeType = SuperlativeType(rawValue: superlativeType_)!
                }
                // Download all classmates' profiles
                self.getUserFields(uid: uid_, completed: { (isSuccess, userProfile) in
                    
                    if !isSuccess || userProfile == nil {
                        // There was a problem getting a user's profile, so return false)
                        completed(false, classroom)
                        return
                    }
                    
                    members.append(userProfile!)
                    memberIds.append(userProfile!.uid)
                    
                    if self.isIdenticalArrays(arr1: memberIds, arr2: totalMemberIds) { // All classmates read
                        
                        // Check if there are superlatives available yet
                        let hasSuperlatives = classDict["superlatives"] != nil
                        
                        // Form classroom messages in a separate call
                        let updatedClassroom = Classroom(cid: classroom.cid, title: classroom.title, timeReplied: classroom.timeReplied, hasUpdates: classroom.hasUpdates, questionNum: classroom.questionNum, questionText: classroom.questionText, imageName: classroom.imageName, shareImageName: classroom.shareImageName, members: members, questions: questions, superlativeType: superlativeType, hasSuperlatives: hasSuperlatives, didYouKnowId: didYouKnowId)
                        completed(true, updatedClassroom) // Finally!
                        return
                    }
                })
            }
        })
        return (ref, handle)
    }
    
    // MARK: Questions 
    
    // Used to get questions and answers in AnswersController
    func getQuestionsAndAnswers(classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom) -> ()) {
        // Note that qids must already be populated in classroom's questions
        let discipline = classroom.title
        let oldQuestions = classroom.questions
        var questionsLeft = classroom.questions.count
        if questionsLeft == 0 {
            completed(false, classroom)
            return
        }
        var newQuestions = [Question]()
        for question in oldQuestions {
            // Grab the question data to reform question
            self.REF_QUESTIONS.child("\(discipline)/\(question.qid)").observe(.value, with: { questionSnap in
                questionsLeft -= 1
                if let qDict = questionSnap.value as? [String: Any], let imageName = qDict["image"] as? String, let questionText = qDict["question"] as? String, let answer = qDict["answer"] as? String {
                    newQuestions.append(Question(qid: question.qid, timestamp: question.timestamp, imageName: imageName, question: questionText, answer: answer, userVote: question.userVote))
                }
                if questionsLeft == 0 { // Finished processing all questions, but might not have gotten all questions' info
                    classroom.questions = newQuestions
                    completed(newQuestions.count == oldQuestions.count, classroom)
                    return
                }
            });
            
        }
    }
    
    // Used to vote for a question in answers as Boring, Cool or Neutral
    func voteForQuestionInClassroom(cid: String, qid: String, userVote: Int) {
        guard let uid = getStoredUid() else {
            return
        }
        REF_CLASSROOMS.child("\(cid)/questions/\(qid)/\(uid)").setValue(userVote)
    }
    
    // MARK: Chat messages

    // Private helper function that takes in a snapshot of all private messages in a classroom and returns a Classroom model
    fileprivate func processClassChatSnapshot(snapshot: FIRDataSnapshot, classroom: Classroom, uid: String) -> Classroom? {
        if !snapshot.exists() {
            return nil
        }
        
        guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
            return nil
        }
        
        classroom.clearMessages()
        for snap in snaps {
            if let dict = snap.value as? [String: Any], let text = dict["message"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String {
                let mid: String = snap.key
                let isSentByYou: Bool = poster == uid
                let date = Date(timeIntervalSince1970: timestamp * 1.0 / 1000.0)
                let msg = ClassroomMessage(mid: mid, parentCid: classroom.cid, posterUid: poster, text: text, date: date, isSentByYou: isSentByYou)
                classroom.addMessage(message: msg)
            }
        }
        return classroom
    }
    
    // Observes all chat messags of one classroom, used in ChatClassroomController
    // Observes up till the limit, ordered by most recent timestamp
    func reobserveClassChatMessages(limit: UInt, classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) -> (FIRDatabaseQuery, FIRDatabaseHandle) {
        
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let cid = classroom.cid
        let ref: FIRDatabaseReference = REF_CLASSROOMMESSAGES.child(cid)
        ref.keepSynced(true)
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.keepSynced(true)
        let handle = q.observe(.value, with: { snapshot in
            let updatedClassroom = self.processClassChatSnapshot(snapshot: snapshot, classroom: classroom, uid: uid)
            completed(updatedClassroom != nil, updatedClassroom)
            return
        })
        return (q, handle)
    }
    
    // Observes all chat messags of one classroom, used when setting up ChatClassroomController
    // The only difference between this and reobserve is that this is a one time observer and does not return the handle
    func observeClassChatMessagesOnce(limit: UInt, classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let cid = classroom.cid
        let ref: FIRDatabaseReference = REF_CLASSROOMMESSAGES.child(cid)
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.observeSingleEvent(of: .value, with: { snapshot in
            q.removeAllObservers()
            let updatedClassroom = self.processClassChatSnapshot(snapshot: snapshot, classroom: classroom, uid: uid)
            completed(updatedClassroom != nil, updatedClassroom)
            return
        })
    }
    
    // Add a chat message to the classroom
    func addClassChatMessage(classroom: Classroom, text: String, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) {
        guard let profile = myProfile else {
            completed(false, nil)
            return
        }
        
        let posterUid = profile.uid
        let posterName = profile.name
        let posterImage = profile.profileImageName
        let cid = classroom.cid
        let classroomTitle = classroom.title
        let timestampInSeconds = Date().timeIntervalSince1970 // NOTE: This is in seconds, be careful with this one
        let timestampInMilliseconds = timestampInSeconds * 1000 // All Firebase entries are in milliseconds
        
        // Add to classroomMessages
        let messageRef: FIRDatabaseReference = REF_CLASSROOMMESSAGES.child(cid).childByAutoId()
        let mid = messageRef.key
        let newMessage: [String: Any] = ["message": text, "poster": posterUid, "timestamp": timestampInMilliseconds]
        messageRef.setValue(newMessage) { (err, ref) in
            // Message successfully added, append to classroom
            let msg: ClassroomMessage = ClassroomMessage(mid: mid, parentCid: cid, posterUid: posterUid, text: text, date: Date(timeIntervalSince1970: timestampInSeconds), isSentByYou: true)
            classroom.addMessage(message: msg)
            completed(err == nil, classroom)
            // NOTE: We do not return here, but also note that there are no more completed calls below
        }
        
        // Add to own classroom's time replied first (do not add to own hasUpdates)
        REF_USERS.child("\(posterUid)/classrooms/\(cid)/timeReplied").setValue(timestampInMilliseconds) // NOTE: Have to set milliseconds in server
        
        // Add to other classmates' hasUpdates
        let classmateUids = classroom.members.map { (profile) -> String in return profile.uid }.filter{$0 != posterUid}
        for classmateUid in classmateUids {
            
            self.REF_USERS.child(classmateUid).observeSingleEvent(of: .value, with: { (userSnap) in
                if !userSnap.exists() {
                    return
                }
                
                // Get this user's push token and push count, and send it to push server anyway
                guard let userDict = userSnap.value as? [String: Any], let classroomsDict = userDict["classrooms"] as? [String: Any], let classroomDict = classroomsDict[cid] as? [String: Any], let hasUpdates = classroomDict["hasUpdates"] as? Bool else {
                    return
                }
                guard let pushToken = userDict["pushToken"] as? String, let pushCount = userDict["pushCount"] as? Int else {
                    // No push token, but user still exists in classroom, so set updates right
                    self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                    return
                }
            
                // Check if this user has the settings that allow message to be push notified
                let settingsRef = self.REF_USERSETTINGS.child(classmateUid)
                settingsRef.keepSynced(true)
                settingsRef.observeSingleEvent(of: .value, with: { (settingsSnap) in
                    
                    var inAppSettings = true
                    
                    if settingsSnap.exists() {
                        
                        if let settingDict = settingsSnap.value as? [String: Bool], let inApp = settingDict["inAppNotifications"] {
                            inAppSettings = inApp
                        }
                        
                        // Check if /classroomMessages and /isLoggedIn are both true
                        if let settingDict = settingsSnap.value as? [String: Bool], let acceptsClassroomMessages = settingDict["classroomMessages"], let isLoggedIn = settingDict["isLoggedIn"] {
                            if !acceptsClassroomMessages || !isLoggedIn {
                                // Not allowed to push messages. Increment push count if necessary, then return
                                if !hasUpdates {
                                    self.adjustPushCount(isIncrement: true, uid: classmateUid, completed: { (isSuccess) in })
                                }
                                
                                self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                                return
                            }
                        }
                    }
                    
                    // Allowed to send push notifications
                    if hasUpdates {
                        // There are already new messages in this classroom for this user, just send a notification without updating push count
                        self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                        self.addToNotificationQueue(type: TokenType.CLASSROOM, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: classmateUid, pushToken: pushToken, pushCount: pushCount, inApp: inAppSettings, cid: cid, title: classroomTitle, body: text)
                        return
                    }
                    // No new messages for this user in this classroom, set hasUpdates to true, and increment push count for this user
                    self.adjustPushCount(isIncrement: true, uid: classmateUid, completed: { (isSuccess) in
                        self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                        // After push count is incremented, then push notification.
                        self.addToNotificationQueue(type: TokenType.CLASSROOM, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: classmateUid, pushToken: pushToken, pushCount: pushCount + 1, inApp: inAppSettings, cid: cid, title: classroomTitle, body: text)
                    })
                })
            })
        }
    }
    
    // See classroom messages so the updated label goes away
    func seeClassroomMessages(classroom: Classroom, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let cid = classroom.cid
        
        REF_USERS.child("\(uid)/classrooms/\(cid)/hasUpdates").setValue(false) { (err, ref) in
            self.updatePushCount { (isSuccess, pushCount) in }
        }
        
    }
    
    // MARK: Superlatives
    
    func submitSuperlativeVote(classroom: Classroom, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        
        // Atomic update on memberHasVoted and superlatives
        var classUpdates: [String: Any] = ["memberHasVoted/\(uid)": 1]
        for sup in classroom.superlatives {
            if let uidVotedFor = sup.userVotedFor?.uid {
                classUpdates["superlatives/\(sup.superlativeName)/\(uid)"] = uidVotedFor
            }
        }
        
        REF_CLASSROOMS.child(classroom.cid).updateChildValues(classUpdates) { (err, ref) in
            completed(err == nil)
            return
        }
    }
    
    func shareSuperlative(classroom: Classroom, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        
        // When a user shares a superlative, simply update the flag for memberHasVoted
        let classUpdates: [String: Any] = ["memberHasVoted/\(uid)": 2]
        REF_CLASSROOMS.child(classroom.cid).updateChildValues(classUpdates) { (err, ref) in
            completed(err == nil)
            return
        }
    }
    
    func getSuperlativeState(classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ superlativeState: SuperlativeType) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let cid = classroom.cid
        REF_CLASSROOMS.child("\(cid)/memberHasVoted/\(uid)").observeSingleEvent(of: .value, with: { snapshot in
            if let superlativeState = snapshot.value as? Int {
                completed(true, SuperlativeType(rawValue: superlativeState)!)
                return
            } else {
                completed(false, SuperlativeType(rawValue: 0)!)
                return
            }
        })
    }
    
    func observeSuperlatives(classroom: Classroom, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let cid = classroom.cid
        let ref: FIRDatabaseReference = REF_CLASSROOMS.child("\(cid)/superlatives")
        ref.keepSynced(true)
        
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                classroom.hasSuperlatives = false
                completed(true, classroom)
                return
            }
            
            guard let supDict = snapshot.value as? [String: Any] else {
                classroom.hasSuperlatives = false
                completed(true, classroom)
                return
            }
            
            var superlatives = [Superlative]()
            var results = [Superlative]()
            let members = classroom.members
            
            // Used to notify the user if voting is still ongoing or not.
            // If there is a single user who has not voted for a single superlative, this will be flipped to true.
            var isVotingOngoing = false
            
            for (supName, uidVotes_) in supDict {
                guard let uidVotes = uidVotes_ as? [String: String] else {
                    continue
                }
                
                // Update results (the most number of votes for a certain person)
                var voteResults = [String: Int]()
                for (_, uidVotedFor) in uidVotes {
                    if uidVotedFor == "" { // User has not voted yet
                        isVotingOngoing = true
                        continue
                    }
                    var currentVoteCount = voteResults[uidVotedFor]
                    if currentVoteCount == nil || currentVoteCount == 0 {
                        currentVoteCount = 1
                    } else {
                        currentVoteCount! += 1
                    }
                    voteResults[uidVotedFor] = currentVoteCount!
                }
                
                // Find uid with max votes
                var maxVoteCount = 0
                var maxVotedUid = ""
                for (uidVotedFor, voteCount) in voteResults {
                    if voteCount > maxVoteCount {
                        // Note: There could potentially be multiple users with the same vote, but we just choose one of them
                        maxVoteCount = voteCount
                        maxVotedUid = uidVotedFor
                    }
                }
                // Get the user with this uid
                var maxVotedMember = members.filter(){$0.uid == maxVotedUid}
                if maxVotedMember.count == 1 {
                    results.append(Superlative(superlativeName: supName, userVotedFor: maxVotedMember[0]))
                }
                
                // Update superlatives (what this user voted for)
                let uidVotedFor = uidVotes[uid]
                if uidVotedFor == nil || uidVotedFor == "" {
                    superlatives.append(Superlative(superlativeName: supName))
                } else {
                    let member = members.filter(){$0.uid == uidVotedFor!}
                    if member.count != 1 {
                        superlatives.append(Superlative(superlativeName: supName))
                    } else {
                        superlatives.append(Superlative(superlativeName: supName, userVotedFor: member[0]))
                    }
                }
            }
            
            classroom.superlatives = superlatives
            classroom.results = results
            classroom.isVotingOngoing = isVotingOngoing

            completed(true, classroom)
            return
        })
        return (ref, handle)
    }
    
    func getDidYouKnow(discipline: String, did: String, completed: @escaping (_ isSuccess: Bool, _ videoLink: String) -> ()) {
        REF_DIDYOUKNOWS.child("\(discipline)/\(did)").observeSingleEvent(of: .value, with: { snap in
            guard let didDict = snap.value as? [String: String], let videoLink = didDict["videoLink"] else {
                completed(false, "")
                return
            }
            completed(true, videoLink)
            return
        })
    }
}

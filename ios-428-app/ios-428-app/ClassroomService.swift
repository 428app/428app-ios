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
    
    // Observes changes in the classrooms that a user is in, used in ClassroomController
    func observeClassrooms(completed: @escaping (_ isSuccess: Bool, _ cids: [String]) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        // Grabs the user's classrooms
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/classrooms")
        ref.keepSynced(true)
        
        // Observed on value as not childAdded, as classrooms might be deleted in the future
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, [])
                return
            }
            guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
                completed(false, [])
                return
            }
            
            var cids: [String] = []
            
            for snap in snaps {
                cids.append(snap.key)
            }
            completed(true, cids)
            return
        })
        return (ref, handle)
    }
    
    // Private helper function that returns Question model given qid and timestamp of question. Used primarily by observeSingleClassroom.
    fileprivate func getQuestion(discipline: String, qid: String, timestamp: Double, completed: @escaping (_ isSuccess: Bool, _ question: Question?) -> ()) {
        self.REF_QUESTIONS.child("\(discipline)/\(qid)").observeSingleEvent(of: .value, with: { questionSnap in
            if !questionSnap.exists() {
                log.info("Failed at qid:\(qid)")
                completed(false, nil)
                return
            }
            
            guard let qDict = questionSnap.value as? [String: Any], let imageName = qDict["image"] as? String, let question = qDict["question"] as? String, let answer = qDict["answer"] as? String else {
                log.info("Failed at question fields not correct")
                completed(false, nil)
                return
            }
            
            let qn = Question(qid: qid, timestamp: timestamp, imageName: imageName, question: question, answer: answer)
            completed(true, qn)
            return
        })
    }
    
    fileprivate func isIdenticalArrays(arr1: [Any], arr2: [Any]) -> Bool {
        let set1 = NSCountedSet(array: arr1)
        let set2 = NSCountedSet(array: arr2)
        return set1 == set2
    }
    
    // Observes changes in a single classroom's meta information such as question number, etc., used in ClassroomController
    // NOTE: This is quite fragile with a lot of nested calls, and a lot of potential failure points. Restructure in the future to make it more robust.
    func observeSingleClassroom(cid: String, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/classrooms/\(cid)")
        ref.keepSynced(true)
        REF_CLASSROOMS.child("\(cid)/memberHasVoted/\(uid)").keepSynced(true)
        REF_CLASSROOMS.child("\(cid)/questions").keepSynced(true)
        
        // Primarily observe on changes in classroom's question number and image
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, nil)
                return
            }
            guard let snapDict = snapshot.value as? [String: Any], let _ = snapDict["discipline"] as? String, let _ = snapDict["questionNum"] as? Int, let _ = snapDict["questionImage"] as? String, let hasUpdates = snapDict["hasUpdates"] as? Bool else { // Some of the fields are not being used because they are collected below
                log.info("Failed at start")
                completed(false, nil)
                return
            }
            
            // Grab the other details relevant to form a Classroom model
            self.REF_CLASSROOMS.child(cid).observeSingleEvent(of: .value, with: { classSnap in
                
                if !classSnap.exists() {
                    log.info("Failed at classroom-0")
                    completed(false, nil)
                    return
                }
                guard let classDict = classSnap.value as? [String: Any], let classTitle = classDict["title"] as? String, let timeCreated = classDict["timeCreated"] as? Double, let classmateAndSuperlativeType = classDict["memberHasVoted"] as? [String: Int], let questionsAndTimes = classDict["questions"] as? [String: Double] else {
                    log.info("Failed at classroom")
                    completed(false, nil)
                    return
                }
                
                // Download profiles, and find this user's superlative type
                var members: [Profile] = [Profile]()
                
                // Used as comparison to know if async task is done
                var memberIds: [String] = [String]()
                let totalMemberIds: [String] = Array(classmateAndSuperlativeType.keys)
                
                var superlativeType: SuperlativeType = SuperlativeType.NOTVOTED
                for (uid_, superlativeType_) in classmateAndSuperlativeType {
                    
                    // Find superlative type of this user
                    if uid_ == uid {
                        superlativeType = SuperlativeType(rawValue: superlativeType_)!
                    }
                    // Download all classmates' profiles
                    self.getUserFields(uid: uid_, completed: { (isSuccess, userProfile) in
                        
                        if !isSuccess || userProfile == nil {
                            // There was a problem getting a user's profile, so return false
                            log.info("Failed at user profiles")
                            completed(false, nil)
                            return
                        }
                        
                        members.append(userProfile!)
                        memberIds.append(userProfile!.uid)
                        
                        if self.isIdenticalArrays(arr1: memberIds, arr2: totalMemberIds) { // All classmates read
                        
                            // Check if there are superlatives available yet
                            let hasSuperlatives = classDict["superlatives"] != nil
                            
                            // Download questions and answers
                            var questions: [Question] = [Question]()
                            for (qid_, timestamp_) in questionsAndTimes {
                                self.getQuestion(discipline: classTitle, qid: qid_, timestamp: timestamp_, completed: { (isSuccess2, question) in
                                    if !isSuccess2 || question == nil {
                                        // There was a problem getting a question from qid, so return false
                                        log.info("Failed at question")
                                        completed(false, nil)
                                        return
                                    }
                                    questions.append(question!)
                                    if questions.count == questionsAndTimes.count { // All questions qid read
                                        // Form classroom messages in a separate call
                                        let classroom = Classroom(cid: cid, title: classTitle, timeCreated: timeCreated, members: members, questions: questions, superlativeType: superlativeType, hasUpdates: hasUpdates, hasSuperlatives: hasSuperlatives)
                                        completed(true, classroom) // Finally!
                                        return
                                    }
                                })
                            }
                        }
                    })
                }
            })
        })
        return (ref, handle)
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
                let date = Date(timeIntervalSince1970: timestamp)
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
        let timestamp = Date().timeIntervalSince1970
        
        // Add to classrooms (timeReplied)
        REF_CLASSROOMS.child("\(cid)/timeReplied").setValue(timestamp)
        
        // Add to classroomMessages
        let messageRef: FIRDatabaseReference = REF_CLASSROOMMESSAGES.child(cid).childByAutoId()
        let mid = messageRef.key
        let newMessage: [String: Any] = ["message": text, "poster": posterUid, "timestamp": timestamp]
        messageRef.setValue(newMessage) { (err, ref) in
            // Message successfully added, append to classroom
            let msg: ClassroomMessage = ClassroomMessage(mid: mid, parentCid: cid, posterUid: posterUid, text: text, date: Date(timeIntervalSince1970: timestamp), isSentByYou: true)
            classroom.addMessage(message: msg)
            completed(err == nil, classroom)
            // NOTE: We do not return here, but also note that there are no more completed calls below
        }
        
        // Add to other classmates' hasUpdates
        let classmateUids = classroom.members.map { (profile) -> String in return profile.uid }.filter{$0 != posterUid}
        for classmateUid in classmateUids {
            
            self.REF_USERS.child(classmateUid).observeSingleEvent(of: .value, with: { (userSnap) in
                if !userSnap.exists() {
                    return
                }
                
                // Get this user's push token and badge count, and send it to push server anyway
                guard let userDict = userSnap.value as? [String: Any], let classroomsDict = userDict["classrooms"] as? [String: Any], let classroomDict = classroomsDict[cid] as? [String: Any], let hasUpdates = classroomDict["hasUpdates"] as? Bool else {
                    return
                }
                guard let pushToken = userDict["pushToken"] as? String, let pushCount = userDict["pushCount"] as? Int else {
                    // No push token, but user still exists in classroom, so set updates right
                    self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)/hasUpdates").setValue(true)
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
                                // Not allowed to push messages. Increment badge count if necessary, then return
                                if !hasUpdates {
                                    self.adjustPushCount(isIncrement: true, uid: classmateUid, completed: { (isSuccess) in })
                                }
                                
                                self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)/hasUpdates").setValue(true)
                                return
                            }
                        }
                    }
                    
                    // Allowed to send push notifications
                    if hasUpdates {
                        // There are already new messages in this classroom for this user, just send a notification without updating badge
                        self.addToNotificationQueue(type: TokenType.CLASSROOM, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: classmateUid, pushToken: pushToken, pushCount: pushCount, inApp: inAppSettings, cid: cid, title: classroomTitle, body: text)
                        return
                    }
                    // No new messages for this user in this classroom, set hasUpdates to true, and increment push count for this user
                    self.REF_USERS.child("\(classmateUid)/classrooms/\(cid)/hasUpdates").setValue(true)
                    self.adjustPushCount(isIncrement: true, uid: classmateUid, completed: { (isSuccess) in
                        // After badge count is incremented, then push notification.
                        self.addToNotificationQueue(type: TokenType.CLASSROOM, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: classmateUid, pushToken: pushToken, pushCount: pushCount + 1, inApp: inAppSettings, cid: cid, title: classroomTitle, body: text)
                    })
                })
            })
        }
    }
    
    // See classroom messages so the updated label goes away
    func seeClassroom(classroom: Classroom, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let cid = classroom.cid
        
        REF_USERS.child("\(uid)/classrooms/\(cid)/hasUpdates").setValue(false)
        updatePushCount { (isSuccess, pushCount) in }
        
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

}

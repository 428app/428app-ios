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
        })
    }
    
    // Observes changes in a single classroom's meta information such as question number, etc., used in ClassroomController
    // NOTE: This is quite fragile with a lot of nested calls, and a lot of potential failure points. Restructure in the future to make it more robust.
    func observeSingleClassroom(cid: String, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/classrooms/\(cid)")
        
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
                guard let classDict = classSnap.value as? [String: Any], let classTitle = classDict["title"] as? String, let timeCreated = classDict["timeCreated"] as? Double, let classmateAndRatingType = classDict["memberHasRated"] as? [String: Int], let questionsAndTimes = classDict["questions"] as? [String: Double] else {
                    log.info("Failed at classroom")
                    completed(false, nil)
                    return
                }
                
                // Download profiles, and find this user's rating type
                var members: [Profile] = [Profile]()
                var hasRatingType: RatingType = RatingType.NOTRATED
                for (uid_, ratingType_) in classmateAndRatingType {
                    // Find rating type of this user
                    if uid_ == uid {
                        hasRatingType = RatingType(rawValue: ratingType_)!
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
                        if members.count == classmateAndRatingType.count { // All classmates uid read
                            
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
                                        // Form ratings and classroom messages in a separate call
                                        let classroom = Classroom(cid: cid, title: classTitle, timeCreated: timeCreated, members: members, questions: questions, hasRatingType: hasRatingType, hasUpdates: hasUpdates)
                                        completed(true, classroom) // Finally!
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
        })
    }
    
    // Add a chat message to the classroom
    func addClassChatMessage(classroom: Classroom, text: String, completed: @escaping (_ isSuccess: Bool, _ classroom: Classroom?) -> ()) {
        guard let posterUid = getStoredUid() else {
            completed(false, nil)
            return
        }
        let cid = classroom.cid
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
        }
        
        // Add to other classmates' hasUpdates
        let classmateUids = classroom.members.map { (profile) -> String in return profile.uid }.filter{$0 != posterUid}
        
        // Don't add when the classmate is already in the chat
        for classmateUid in classmateUids {
            REF_USERS.child("\(classmateUid)/classrooms/\(cid)/hasUpdates").setValue(true)
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
    }
    
    // MARK: Ratings

}

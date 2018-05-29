//
//  sum.swift
//  AddingUp
//
//  Created by Daniel Jinks on 10/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import Foundation

enum LearnedStatus {
    case Learned
    case GettingRightButSlow
    case Inconclusive
    case GettingWrong
    case NotTriedEnough
}

class Sum {
    let n1: Int
    let n2: Int
    let op: String
    var history: [(correct: Bool, time: Double)] = []
    
    init(n1:Int, n2:Int, op:String) {
        self.n1 = n1
        self.n2 = n2
        self.op = op
    }
    
    public func submitAnswer(answer: Int, timeTaken: TimeInterval) -> Bool {
        let isCorrect = (answer == self.answer)
        history.append((correct: isCorrect, time: timeTaken))
        return isCorrect
    }
    
    public func hasLearned() -> LearnedStatus {
        guard history.count >= 2 else { return .NotTriedEnough }
        var numAnswers = 0
        var numRight = 0
        var totTime = 0.0
        for i in max(0,history.count - 5)...history.count - 1 {
            numAnswers += 1
            if history[i].correct { numRight += 1 }
            totTime += history[i].time
        }
        guard numRight >= 0 else { return .GettingWrong }
        guard numRight == numAnswers else { return .Inconclusive }
        if Double(totTime) / Double(numAnswers) < 6.5 {
            return .Learned
        } else {
            return .GettingRightButSlow
        }
    }
    
    //
    public func getBaseDifficulty() -> Int {
        guard op == "+" else { return 1000 }
        var diff = max(n1 + n2 - 5, 1) // bigger nos are harder
        if n1 == 1 || n2 == 1 {
            diff /= 2 // adding ones is particularly easy
        }
        if n1 % 10 + n2 % 10 > 10 {
            diff += 4 // carrying tens is hard
        }
        return diff
    }
    
    
    public var answer: Int {
        switch op {
        case "+": return n1 + n2
        case "-": return n1 - n2
        default: return 0
        }
    }

}
/*
struct SumAnswer {
    let sum: Sum
    let correct: Bool
    let timeTaken: TimeInterval
    init(sum: Sum, correct: Bool, timeTaken: TimeInterval) {
        self.sum = sum
        self.timeTaken = timeTaken
        self.correct = correct
    }
}
 */

//
//  User.swift
//  AddingUp
//
//  Created by Daniel Jinks on 10/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import Foundation

class User {
    var name = ""
    var additions: [Sum] = []
    var subtractions: [Sum] = []
    init(name: String) {
        self.name = name
        for i in 1...20 {
            for j in 1...20 {
                additions.append(Sum(n1: i, n2: j, op: "+"))
            }
        }
        for i in 1...40 {
            for j in 1...i {
                subtractions.append(Sum(n1: i, n2: j, op: "-"))
            }
        }
    }
    
    enum Carries {
        case Yes
        case No
        case Maybe
    }
    
    enum Mode {
        case Addition
        case Subtraction
    }
    
    func pickSum(level: Int, mode: User.Mode) -> Sum {
        switch mode {
        case .Addition:
            return pickAddition(level: level)
        case .Subtraction:
            return pickSubtraction(level: level)
        }
    }
    
    private func pickSubtraction(level: Int) -> Sum {
        var maxNumber = 30
        var minAnswer = 0
        var minNumber = 1
        var carriesAllowed = Carries.Maybe
        switch level {
        case 0:
            maxNumber = 5
        case 1:
            maxNumber = 7
            minNumber = 3
        case 2:
            maxNumber = 12
            minNumber = 6
            minAnswer = 2
            carriesAllowed = .No
        case 3:
            maxNumber = 15
            minNumber = 10
            minAnswer = 2
            carriesAllowed = .Maybe
        case 4:
            maxNumber = 20
            minNumber = 12
            minAnswer = 3
            carriesAllowed = .Maybe
        case 5:
            maxNumber = 20
            minNumber = 12
            minAnswer = 3
            carriesAllowed = .Yes
        case 6:
            maxNumber = 20
            minNumber = 15
            minAnswer = 4
            carriesAllowed = .Yes
        case 7:
            maxNumber = 30
            minNumber = 20
            minAnswer = 5
            carriesAllowed = .Yes
        default: break
        }
        while true {
            let possibleSum = subtractions[Int(arc4random_uniform(UInt32(subtractions.count)))]
            let n1 = possibleSum.n1
            let n2 = possibleSum.n2
            let ans = n1 - n2
            let carryNeeded = (n1 % 10 - n2 % 10 != ans % 10) && (n1 % 10 - n2 % 10 != 0)
            guard n1 >= minNumber && n1 <= maxNumber else { continue }
            guard (ans >= minAnswer) else {continue}
            switch carriesAllowed {
            case .No:
                guard !carryNeeded else { continue }
            case .Yes:
                guard carryNeeded else { continue }
            case .Maybe:
                break
            }
            return possibleSum
        }
    }
    
    
    private func pickAddition(level: Int) -> Sum {
        var maxTotal = 40
        var minTotal = 2
        var minNumber = 1
        var carriesAllowed = Carries.Maybe
        switch level {
        case 0:
            maxTotal = 5
        case 1:
            maxTotal = 10
            minTotal = 5
        case 2:
            maxTotal = 15
            minTotal = 8
            carriesAllowed = .No
            minNumber = 2
        case 3:
            maxTotal = 17
            minTotal = 10
            minNumber = 2
        case 4:
            maxTotal = 20
            minTotal = 12
            minNumber = 3
        case 5:
            maxTotal = 20
            minTotal = 12
            minNumber = 3
            carriesAllowed = .Yes
        case 6:
            maxTotal = 20
            minTotal = 15
            minNumber = 3
            carriesAllowed = .Yes
        case 7:
            maxTotal = 30
            minTotal = 21
            minNumber = 3
            carriesAllowed = .Maybe
        default: break
        }
        while true {
            let possibleSum = additions[Int(arc4random_uniform(UInt32(additions.count)))]
            let n1 = possibleSum.n1
            let n2 = possibleSum.n2
            let mn = min(n1, n2)
            let tot = n1 + n2
            let carryNeeded = (n1 % 10 + n2 % 10 != tot % 10) && (n1 % 10 + n2 % 10 != 0)
            guard mn >= minNumber else { continue }
            guard (tot >= minTotal && tot <= maxTotal) else {continue}
            switch carriesAllowed {
            case .No:
                guard !carryNeeded else { continue }
            case .Yes:
                guard carryNeeded else { continue }
            case .Maybe:
                break
            }
            return possibleSum
        }
    }
    /*
    func pickSum() -> Sum {
        //let picked = false
        while true {
            let possibleSum = sums[Int(arc4random_uniform(UInt32(sums.count)))]
            //print("possible sum : \(possibleSum.n1) + \(possibleSum.n2)")
            var prob = 0.0
            if (possibleSum.n1 + possibleSum.n2) > 7 && (possibleSum.n1 + possibleSum.n2) <= 20 && possibleSum.n1 > 1 && possibleSum.n2 > 1 {
                prob = 1.0
                //prob = 10.0 / Double(possibleSum.getBaseDifficulty())
            }
            /*
            switch possibleSum.hasLearned() {
            case .Inconclusive, .NotTriedEnough:
                break
            case .GettingRightButSlow:
                prob *= 10
            case .GettingWrong:
                prob *= 0.5
            case .Learned:
                prob *= 0.001
            }
 */
            //print("probability : \(prob)")
            if (Double(arc4random()) / Double(UINT32_MAX) < prob) {
                return possibleSum
            }
        }
    }
 */
}


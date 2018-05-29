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
    var sums: [Sum] = []
    init(name: String) {
        self.name = name
        for i in 1...20 {
            for j in 1...20 {
                sums.append(Sum(n1: i, n2: j, op: "+"))
            }
        }
    }
    
    func pickSum(level: Int) -> Sum {
        var maxTotal = 40
        var minTotal = 2
        var minNumber = 1
        var carriesAllowed = true
        switch level {
        case 0:
            maxTotal = 5
        case 1:
            maxTotal = 10
            minTotal = 5
        case 2:
            maxTotal = 15
            minTotal = 8
            carriesAllowed = false
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
            minTotal = 15
            minNumber = 3
        default: break
        }
        while true {
            let possibleSum = sums[Int(arc4random_uniform(UInt32(sums.count)))]
            let n1 = possibleSum.n1
            let n2 = possibleSum.n2
            let mn = min(n1, n2)
            let tot = n1 + n2
            let carryNeeded = n1 % 10 + n2 % 10 != tot % 10
            guard mn >= minNumber else { continue }
            guard (tot >= minTotal && tot <= maxTotal) else {continue}
            if !carriesAllowed {
                guard !carryNeeded else { continue }
            }
            return possibleSum
        }
    }
    
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
}


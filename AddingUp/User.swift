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
    
    func pickSum() -> Sum {
        //let picked = false
        while true {
            let possibleSum = sums[Int(arc4random_uniform(UInt32(sums.count)))]
            //print("possible sum : \(possibleSum.n1) + \(possibleSum.n2)")
            var prob = 0.0
            if (possibleSum.n1 + possibleSum.n2) > 7 && (possibleSum.n1 + possibleSum.n2) <= 20 {
                prob = 10.0 / Double(possibleSum.getBaseDifficulty())
            }
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
            //print("probability : \(prob)")
            if (Double(arc4random()) / Double(UINT32_MAX) < prob) {
                return possibleSum
            }
        }
    }
}


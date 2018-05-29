//
//  ActionQueue.swift
//  AddingUp
//
//  Created by Daniel Jinks on 29/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import Foundation

class ActionQueue {
    var actions: [() ->()] = []
    func actionCompleted() {
        actions.popLast()
        if let action = actions.last {
            action()
        }
    }
    func add(action: @escaping () -> ()) {
        print("adding action to queue")
        actions.insert(action, at: 0)
        if actions.count == 1 {
            print("initiating action immediately")
            action()
        }
    }
}

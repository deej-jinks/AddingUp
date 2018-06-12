//
//  GameResult.swift
//  AddingUp
//
//  Created by Daniel Jinks on 30/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import Foundation

struct HighScores: Codable {
    /*
 // singleton
    static let shared = load()
    private init() {}
    */
    static let key = "high scores"
    var scores: [GameResult] = []
    
    var orderedScores: [GameResult] {
        return scores.sorted(){$0.score > $1.score}
    }
    
    func save() {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(self)
            UserDefaults.standard.set(encodedData, forKey: HighScores.key)
        } catch { print("failed to save high scores to disk")}
    }
    
    static func load() -> HighScores {
        var scores = HighScores()
        if let encodedData = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            do {
                scores = try decoder.decode(HighScores.self, from: encodedData)
            } catch {
                print("error unencoding high scores from disk")
                UserDefaults.standard.removeObject(forKey: key)
            }
        } else {
            // create dummy entries for new table
            scores.scores.append(GameResult(name: "Madame Gazelle", score: 3000, levelReached: 5))
            scores.scores.append(GameResult(name: "Mummy Pig", score: 2250, levelReached: 5))
            scores.scores.append(GameResult(name: "Daddy Pig", score: 1750, levelReached: 4))
            scores.scores.append(GameResult(name: "Richard Rabbit", score: 1300, levelReached: 4))
            scores.scores.append(GameResult(name: "Peppa", score: 1000, levelReached: 3))
            scores.scores.append(GameResult(name: "Pedro Pony", score: 750, levelReached: 3))
            scores.scores.append(GameResult(name: "Candy Cat", score: 500, levelReached: 3))
            scores.scores.append(GameResult(name: "Suzy Sheep", score: 300, levelReached: 2))
            scores.scores.append(GameResult(name: "Danny Dog", score: 100, levelReached: 2))
            scores.scores.append(GameResult(name: "George", score: 50, levelReached: 1))
        }
        return scores
    }
    
    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

struct GameResult: Codable {
    var name: String
    var score: Int
    var levelReached: Int
}



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
    
    static let key = "high scores v4"
    
    var additionScores: [GameResult] = []
    var subtractionScores: [GameResult] = []
    
    func getOrderedScores(mode: User.Mode) -> [GameResult] {
        switch mode {
        case .Addition:
            return additionScores.sorted(){$0.score > $1.score}
        case .Subtraction:
            return subtractionScores.sorted(){$0.score > $1.score}
        }
        
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
            // reminder of level rewards : let levelRewards = [10, 15, 25, 50, 100, 150, 200]
            
            scores.additionScores.append(GameResult(name: "Madame Gazelle", score: 500, levelReached: 6))
            scores.additionScores.append(GameResult(name: "Mummy Pig", score: 400, levelReached: 6))
            scores.additionScores.append(GameResult(name: "Daddy Pig", score: 250, levelReached: 5))
            scores.additionScores.append(GameResult(name: "Richard Rabbit", score: 200, levelReached: 5))
            scores.additionScores.append(GameResult(name: "Peppa", score: 150, levelReached: 4))
            scores.additionScores.append(GameResult(name: "Pedro Pony", score: 100, levelReached: 4))
            scores.additionScores.append(GameResult(name: "Candy Cat", score: 60, levelReached: 3))
            scores.additionScores.append(GameResult(name: "Suzy Sheep", score: 45, levelReached: 3))
            scores.additionScores.append(GameResult(name: "Danny Dog", score: 25, levelReached: 2))
            scores.additionScores.append(GameResult(name: "George", score: 5, levelReached: 1))
            
            scores.subtractionScores.append(GameResult(name: "Madame Gazelle", score: 400, levelReached: 6))
            scores.subtractionScores.append(GameResult(name: "Mummy Pig", score: 250, levelReached: 5))
            scores.subtractionScores.append(GameResult(name: "Daddy Pig", score: 200, levelReached: 5))
            scores.subtractionScores.append(GameResult(name: "Richard Rabbit", score: 150, levelReached: 4))
            scores.subtractionScores.append(GameResult(name: "Peppa", score: 100, levelReached: 4))
            scores.subtractionScores.append(GameResult(name: "Pedro Pony", score: 60, levelReached: 3))
            scores.subtractionScores.append(GameResult(name: "Candy Cat", score: 45, levelReached: 3))
            scores.subtractionScores.append(GameResult(name: "Suzy Sheep", score: 25, levelReached: 2))
            scores.subtractionScores.append(GameResult(name: "Danny Dog", score: 10, levelReached: 1))
            scores.subtractionScores.append(GameResult(name: "George", score: 5, levelReached: 1))
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



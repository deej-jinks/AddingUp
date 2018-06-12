//
//  ViewController.swift
//  AddingUp
//
//  Created by Daniel Jinks on 21/04/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class SumViewController: UIViewController, UITextFieldDelegate, SFSpeechRecognitionTaskDelegate, AVSpeechSynthesizerDelegate, UITableViewDataSource, UITableViewDelegate {

    // key numbers
    let updateInterval = 0.025
    let meterBoost = 0.2
    var sumsAnswered = 0
    var NormalMeterSpeed: Double {
        return 0.02 + Double(sumsAnswered) * 0.0004
    }
    let SlowMeterSpeed = 0.001
    
    var level = 1
    var score = 0
    
    var meterPercent = 0.5
    
    var meterSpeed = 1.0 / 50.0
    var voicePitch: Float = 1.0
    var speechRate: Float = 0.55

    // state variables
    var paused = true {
        didSet {
            if paused == false { runUpdateCycle() }
        }
    }
    let actionQueue = ActionQueue()

    enum ListeningType {
        case Name
        case NameConfirmation
        case Answer
        case Level
    }
    var listeningFor = ListeningType.Name
    
    //var speechQueue = "" // are these both needed?
    //var utterances: [AVSpeechUtterance] = []
    
    // objects
    var sum: Sum!
    var user: User!
    
    var speechRecogniser: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    let speaker = AVSpeechSynthesizer()
    
    var highScores = HighScores.load()
    
    // outlets
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var n1: UILabel!
    @IBOutlet weak var n2: UILabel!
    @IBOutlet weak var answerInput: UILabel!
    @IBOutlet weak var correctAnswer: UILabel!
    @IBOutlet weak var tickOrCross: UIImageView!
    @IBOutlet weak var picturePlace: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!

    @IBOutlet weak var meterBox: UIView!
    @IBOutlet weak var meterHeight: NSLayoutConstraint!
    
    @IBOutlet weak var levelUpModalView: UIView!
    @IBOutlet weak var levelUpLabel: UILabel!
    
    @IBOutlet weak var gameOverModalView: UIView!
    @IBOutlet weak var highScoresTableView: UITableView! {
        didSet {
            highScoresTableView.dataSource = self
            highScoresTableView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speaker.delegate = self
        configureAudioSession()
        requestAuthorisations()

    }
    
    var readyForNextAction = true
    
    func askName() {
        say("Welcome to Emma's Adding Up Game")
        say("What's your name?")
        listen(for: .Name)
    }
    
    func startGame() {
        print("starting game")
        UIView.animate(withDuration: 1.5, animations: {
            self.modalView.alpha = 0.0
        }) { (success) in
            self.say("Let's go!")
            self.setNewSum()
            //self.sumToBeSet = true
            self.paused = false
        }
    }
    
    func askLevel() {
        say("Hello \(user.name)")
        say("what level would you like to start on?")
        listen(for: .Level)
    }

    func update() {
        meterPercent -= meterSpeed * updateInterval
        if meterPercent <= 0.0 {
            paused = true
            endGame()
        }
        meterHeight.constant =  (meterBox.bounds.height - 10.0) * CGFloat(meterPercent)
        scoreLabel.text = "\(score)"
        levelLabel.text = "\(level)"
    }
    
    func endGame() {
        stopListening()
        actionQueue.actionCompleted()
        highScores.scores.append(GameResult(name: user.name, score: score, levelReached: level))
        highScores.save()
        highScoresTableView.reloadData()
        print("scores : \(highScores.orderedScores)")
        say("Game over")
        nameLabel.text = "\(score)"
        UIView.animate(withDuration: 1.5, animations: {
            self.gameOverModalView.alpha = 1.0
        })
        say("Well done, you scored \(score)")
    }
    
    @IBAction func playAgain(_ sender: Any) {
        resetUI()
        picturePlace.image = nil
        modalView.alpha = 1.0
        nameLabel.text = ""
        level = 1
        score = 0
        sumsAnswered = 0
        UIView.animate(withDuration: 1.5, animations: {
            self.gameOverModalView.alpha = 0.0
        })
        askName()
    }
    @IBAction func resetHighScores(_ sender: Any) {
        let alert = UIAlertController(title: "Reset Scores", message: "Are you sure you want to reset the high scores?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .destructive) { (action) in
            HighScores.reset()
            self.highScores = HighScores.load()
            self.highScoresTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func resetUI() {
        meterPercent = 0.65 - Double(level) * 0.05//0.5
        n1.text = ""
        n2.text = ""
        tickOrCross.image = nil
        answerInput.text = ""
    }
    
    let playlist: [(name: String, ext: String)] =
        [
            (name: "dance_song", ext: "mp3"),
         (name: "dance_song", ext: "mp3"),
         (name: "retro dance theme", ext: "wav"),
         (name: "fast_dance", ext: "wav"),
         (name: "90s pop", ext: "wav"),
         (name: "dance_song", ext: "mp3"),
         (name: "game_theme", ext: "wav"),
         (name: "house-loop", ext: "wav"),
         (name: "other dance song", ext: "wav")
         ]
    func levelUp() {
        paused = true
        level += 1
        levelUpLabel.text = "Level \(level)"
        UIView.animate(withDuration: 1.0, animations: {
            self.levelUpModalView.alpha = 1.0
        }) { (success) in
            self.say("welcome to level \(self.level)")
            self.resetUI()
            let deadline = DispatchTime.now() + 2.0
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                self.playMusic(name: self.playlist[self.level].name, ext: self.playlist[self.level].ext, length: 15.0)
                let deadline2 = DispatchTime.now() + 14.0
                DispatchQueue.main.asyncAfter(deadline: deadline2, execute: {
                    UIView.animate(withDuration: 3.0, animations: {
                        self.levelUpModalView.alpha = 0.0
                    }, completion: { (success) in
                        self.setNewSum()
                        self.paused = false
                    })
                })
            })
        }
    }
    
    func runUpdateCycle() {
        update()
        if !paused {
            let deadline = DispatchTime.now() + updateInterval
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                self.runUpdateCycle()
            }
        }
    }
    
    func configureAudioSession() {
        do {
            try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try self.audioSession.setMode(AVAudioSessionModeMeasurement)
            try self.audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {print("error 583DPJ")}
    }
    
    func requestAuthorisations() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("authorised")
                    self.audioSession.requestRecordPermission { (granted) in
                        self.authorisationsGranted()
                    }
                case .denied:
                    print("User denied access to speech recognition")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                }
                
            }
        }
    }
    
    func authorisationsGranted() {
        setupSpeechRecogniser()
        askName()
    }
    
    func setupSpeechRecogniser() {
        speechRecogniser = SFSpeechRecognizer()
        guard speechRecogniser!.isAvailable else {
            print("recogniser not available")
            return
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest!.shouldReportPartialResults = true
        recognitionRequest!.taskHint = SFSpeechRecognitionTaskHint.dictation
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest!.append(buffer)}
    }
    
    func listen(for listeningFor: ListeningType) {
        print("listening for : \(listeningFor)")
        actionQueue.add {
            self.recognitionTask = self.speechRecogniser?.recognitionTask(with: self.recognitionRequest!, resultHandler: { (result, error) in
                guard result != nil else { return }
                let transcription = result!.bestTranscription.formattedString
                print("recognised speech : \(transcription)")
                switch listeningFor {
                case .Level:
                    if let num = findNumbers(inString: transcription) {
                        if num <= 5 {
                            self.actionQueue.actionCompleted()
                            self.level = num
                            self.say("ok, let's start on level \(self.level)")
                            self.startGame()
                        }
                    }
                case .Answer:
                    if let num = findNumbers(inString: transcription) {
                        self.actionQueue.actionCompleted()
                        self.answerInput.text = "\(num)"
                        self.checkAnswer(num)
                    }
                case .Name:
                    //self.listeningFor = .NameConfirmation
                    self.actionQueue.actionCompleted()
                    self.stopListening()
                    self.nameLabel.text = getName(transcription: transcription)
                    self.say("Is your name \(self.nameLabel.text!)")
                    self.listen(for: .NameConfirmation)
                case .NameConfirmation:
                    if let yesNo = findYesNo(inString: transcription) {
                        self.actionQueue.actionCompleted()
                        self.stopListening()
                        if yesNo == "yes" {
                            self.user = User(name: self.nameLabel.text!)
                            self.askLevel()
                        } else {
                            self.say("Oh! Sorry! What's your name?")
                            self.listen(for: .Name)//self.listeningFor = .Name
                        }
                    }
                    
                }
            })
            self.audioEngine.prepare()
            do {try self.audioEngine.start()} catch { print("failed to start audio engine")}
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        audioEngine.stop()
    }
    
    var timeSet = Date()
    func setNewSum() {
        meterSpeed = NormalMeterSpeed
        tickOrCross.image = nil
        answerInput.text = ""
        correctAnswer.text = ""
        sum = user.pickSum(level: level)
        speak(sum: sum)
        n1.text = "\(sum.n1)"
        n2.text = "\(sum.n2)"
        timeSet = Date()
        listen(for: .Answer)
    }
    
    func speak(sum: Sum) {
        say(" \(sum.n1) \(sum.op) \(sum.n2)")
    }
    
    var sumToBeSet = false
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        actionQueue.actionCompleted()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        stopListening()
        print("started talking")
    }

    func say(_ words: String) {
        let utterance = AVSpeechUtterance(string: words)
        utterance.pitchMultiplier = voicePitch
        utterance.rate = speechRate
        utterance.postUtteranceDelay = 0.15
        actionQueue.add {
            self.speaker.speak(utterance)
        }
    }

    //////////////////// Bits for Emma after here /////////////////////
    
    func checkAnswer(_ n: Int) {
        sumsAnswered += 1
        stopListening()
        meterSpeed = SlowMeterSpeed
        let timeTaken = Date().timeIntervalSince(timeSet)
        let isCorrect = sum.submitAnswer(answer: n, timeTaken: timeTaken)
        print("\(isCorrect) answer submitted in time : \(timeTaken)")
        if isCorrect {
            tickOrCross.image = #imageLiteral(resourceName: "tick")
            meterPercent += meterBoost
            score += 5 * level * (level + 1) // CHANGE THIS
            if meterPercent >= 1.0 {
                meterPercent = 1.0
                levelUp()
                return
            }
            let rand = arc4random_uniform(15)
            switch rand {
            case 0:
                say("That's right.")
            case 1:
                say("Well done, you're a superstar \(user.name)!")
            case 2:
                say("superstar")
            case 3,4:
                say("great job \(user.name)")
            case 5:
                say("well done \(user.name), have a song.")
                playMusic(name: "dance_song", ext: "mp3", length: 3)
            case 6, 7:
                say("nice work \(user.name)")
            case 8,9:
                if (picturePlace.image == nil || picturePlace.image == #imageLiteral(resourceName: "sad_cloud")) {
                    say("fantastic! Have a clown")
                    picturePlace.image = #imageLiteral(resourceName: "clown")
                } else if picturePlace.image == #imageLiteral(resourceName: "clown") {
                    say("fantastic! Have a rainbow")
                    picturePlace.image = #imageLiteral(resourceName: "rainbow")
                } else {
                    say("fantastic! Have a unicorn")
                    picturePlace.image = #imageLiteral(resourceName: "unicorn")
                }
            case 10, 11:
                if voicePitch == 1.0 {
                    say("great! I'll put on a silly voice")
                    voicePitch = (arc4random_uniform(10) >= 5) ? 2.0 : 0.5
                    say("hello")
                    say("oh no! It's stuck like that!")
                } else {
                    say("well done, that's right")
                    if voicePitch != 1.0 {
                        voicePitch = 1.0
                        say("phew, I got my voice back")
                    }
                }
            case 12:
                speechRate = 0.85
                say("hey that super fantastic amazing i'm so excited i'm talking really really really fast. Ha ha!")
                speechRate = 0.55
            case 13, 14:
                speechRate = 0.2
                say("ha ha i'm talking really slow")
                speechRate = 0.55
            default:
                say("That's right. Well done \(user.name)!")
            }

        } else {
            score -= 20 // CHANGE THIS
            let dice = arc4random_uniform(5)
            switch dice {
            case 0:
                say("wrong")
            case 1:
                say("incorrect")
            case 2:
                say("bing bong bing, bingly bongly bing, bing bong bing you're wrong!")
            case 3:
                say("oh no, that's not right")
            case 4:
                say("Hmm. Not quite. Have a sad cloud.")
                picturePlace.image = #imageLiteral(resourceName: "sad_cloud")
            case 5:
                say("that's not right. Sorry - I'll have to turn the screen black")
                view.backgroundColor = UIColor.black
            default:
                say("I'm sorry, that's not right.")
            }
            tickOrCross.image = #imageLiteral(resourceName: "cross")
            correctAnswer.text = "\(sum.answer)"

        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (isCorrect ? 2.25 : 8.0)) {
            self.setNewSum()
        }
    }
    
    var player: AVAudioPlayer?
    
    func playMusic(name: String, ext: String, length: TimeInterval) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        
        do {
            //try audioSession.setCategory(AVAudioSessionCategoryPlayback) //WILL THIS INTERFERE WITH RECORD?
            try audioSession.setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            guard let player = player else { return }
            actionQueue.add {
                player.play()
                let deadline = DispatchTime.now() + length
                DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                    player.stop()
                    self.actionQueue.actionCompleted()
                })
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return highScores.orderedScores.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return highScoresTableView.bounds.height / 11.0//30.0 * getFontScalingForScreenSize()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    var rankReached = 3
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row > 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "highScoresHeaderCell")!
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "highScoresCell") as! HighScoresTableViewCell
        let row = indexPath.row - 1
        let thisScore = highScores.orderedScores[row]
        cell.nameLabel.text = thisScore.name
        cell.levelLabel.text = "\(thisScore.levelReached)"
        cell.scoreLabel.text = "\(thisScore.score)"
        for medal in cell.medals {
            medal.alpha = (row == 0) ? 1.0 : 0.0
        }
        for arrow in cell.arrows {
            arrow.alpha = (user != nil && thisScore.name == user.name && thisScore.score == score && thisScore.levelReached == level) ? 1.0 : 0.0
        }
    return cell
    }
}

/////////////////////// other stuff ////////////////////////

fileprivate func findYesNo(inString str: String) -> String? {
    let words = str.split(separator: " ")
    for word in words {
        switch word.lowercased() {
        case "yes", "yeah", "sure":
            return "yes"
        case "no", "na", "nah":
            return "no"
        default: continue
        }
    }
    return nil
}



fileprivate func findNumbers(inString str: String) -> Int? {
    let words = str.split(separator: " ")
    for word in words {
        switch word.lowercased() {
        case "11", "eleven":
            return 11
        case "12", "twelve":
            return 12
        case "13", "thirteen", "30":
            return 13
        case "14", "fourteen", "40":
            return 14
        case "15", "fifteen", "50":
            return 15
        case "16", "sixteen", "60":
            return 16
        case "17", "seventeen", "70":
            return 17
        case "18", "eighteen", "80":
            return 18
        case "19", "nineteen", "90":
            return 19
        case "20", "twenty":
            return 20
        case "0", "zero":
            return 0
        case "1", "one":
            return 1
        case "2", "two", "too":
            return 2
        case "3", "three":
            return 3
        case "4", "four", "for":
            return 4
        case "5", "five", "fine", "fight":
            return 5
        case "6", "six", "sex":
            return 6
        case "7", "seven":
            return 7
        case "8", "eight", "ate", "hate", "kate":
            return 8
        case "9", "nine":
            return 9
        case "10", "ten":
            return 10
        default: continue
        }
    }
    return nil
}

fileprivate func getName(transcription: String) -> String {
    let rand = arc4random_uniform(16)
    if rand <= 3 { return getSillyName() }
    if transcription.lowercased() == "anna" && rand < 13 {
        return "Emma"
    }
    return transcription
}

fileprivate var sillyNames: [String] = [
    "Pingu",
    "Isadora Moon",
    "Shopkin",
    "Sweetie",
    "Giraffes",
    "",
]

fileprivate func getSillyName() -> String {
    let rand = Int(arc4random_uniform(UInt32(sillyNames.count) - 1))
    return sillyNames[rand]
}


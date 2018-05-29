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

class SumViewController: UIViewController, UITextFieldDelegate, SFSpeechRecognitionTaskDelegate, AVSpeechSynthesizerDelegate {

    // key numbers
    let updateInterval = 0.025
    let meterBoost = 0.2
    var sumsAnswered = 0
    var NormalMeterSpeed: Double {
        return 0.02 + Double(sumsAnswered) * 0.00025
    }
    let SlowMeterSpeed = 0.001
    
    var level = 1
    var score = 0
    
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
    /*
    var paused = false {
        didSet {
            if paused {
                stopListening()
                recognitionRequest = nil
                updating = false
            } else {
                setupSpeechRecogniser()
                startListening()
                updating = true
            }
        }
    }
 */
    enum ListeningType {
        case Name
        case NameConfirmation
        case Number
    }
    var listeningFor = ListeningType.Name
    
    var speechQueue = "" // are these both needed?
    var utterances: [AVSpeechUtterance] = []
    
    // objects
    var sum: Sum!
    var user: User!
    
    var speechRecogniser: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    let speaker = AVSpeechSynthesizer()
    
    // outlets
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var modalTitle: UILabel!
    @IBOutlet weak var modalLabel2: UILabel!
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
    var meterPercent = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speaker.delegate = self
        configureAudioSession()
        requestAuthorisations()
        
    }
    
    enum GameAction {
        case AskName
        case ListenForName
        case ConfirmName
        case ListenForConfirmation
        case SetSum
        case ListenForAnswer
        case CheckAnswer
        case GameOver
        case LevelUp
    }
    var nextAction = (GameAction.AskName,"")
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

    func update() {
        meterPercent -= meterSpeed * updateInterval
        if meterPercent <= 0.0 {
            paused = true
            loseGame()
        }
        meterHeight.constant =  (meterBox.bounds.height - 10.0) * CGFloat(meterPercent)
        scoreLabel.text = "\(score)"
        levelLabel.text = "\(level)"
    }
    
    func loseGame() {
        stopListening()
        actionQueue.actionCompleted()
        say("Game over")
        modalView.backgroundColor = UIColor.blue
        modalTitle.text = "Game Over"
        modalLabel2.text = "Final Score:"
        nameLabel.text = "\(score)"
        UIView.animate(withDuration: 1.5, animations: {
            self.modalView.alpha = 1.0
        })
        say("Well done, you scored \(score)")
    }
    
    func resetUI() {
        meterPercent = 0.5
        n1.text = ""
        n2.text = ""
        tickOrCross.image = nil
        answerInput.text = ""
    }
    
    func levelUp() {
        paused = true
        level += 1
        modalView.backgroundColor = UIColor.white
        modalTitle.text = "Level \(level)"
        modalLabel2.text = ""
        nameLabel.text = ""
        UIView.animate(withDuration: 1.0, animations: {
            self.modalView.alpha = 1.0
        }) { (success) in
            self.say("welcome to level \(self.level)")
            self.resetUI()
            let deadline = DispatchTime.now() + 2.0
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                self.playMusic(name: "dance_song", length: 10.0)
                let deadline2 = DispatchTime.now() + 10.0
                DispatchQueue.main.asyncAfter(deadline: deadline2, execute: {
                    UIView.animate(withDuration: 5.0, animations: {
                        self.modalView.alpha = 0.0
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
    /*
    func startListening() {
        
        print("starting listening")
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
            return
        }
        //recognitionTask?.cancel()//stopListening() // if there's already a task, cancel it
        print("listening...")
        setupSpeechRecogniser()
        recognitionTask = speechRecogniser?.recognitionTask(with: recognitionRequest!, delegate: self)
        self.audioEngine.prepare()
        do {try self.audioEngine.start()} catch {}
        print("Go ahead, I'm listening")
    }
 */
    
    func listen(for listeningFor: ListeningType) {
        print("listening for : \(listeningFor)")
        actionQueue.add {
            self.recognitionTask = self.speechRecogniser?.recognitionTask(with: self.recognitionRequest!, resultHandler: { (result, error) in
                guard result != nil else { return }
                let transcription = result!.bestTranscription.formattedString
                print("recognised speech : \(transcription)")
                switch listeningFor {
                case .Number:
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
                            self.startGame()
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
    
    /*
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        print("heard something")
        guard task == recognitionTask else {
            task.cancel()
            return
        }
        print("acting on heard speech")
        let speech = transcription.formattedString
        print("recognised speech : \(speech)")
        switch self.listeningFor {
        case .Number:
            if let num = findNumbers(inString: transcription.formattedString) {
                self.answerInput.text = "\(num)"
                self.checkAnswer(num)
            }
        case .Name:
            self.listeningFor = .NameConfirmation
            self.nameLabel.text = speech
            self.say("Is your name \(transcription)?")
        case .NameConfirmation:
            if let yesNo = findYesNo(inString: speech) {
                if yesNo == "yes" {
                    self.user = User(name: self.nameLabel.text!)
                    self.startGame()
                } else {
                    self.say("Oh! Sorry! What's your name?")
                    self.listeningFor = .Name
                }
            }
            
        }
    }
 */
    
    func stopListening() {
        recognitionTask?.cancel()
        audioEngine.stop()
    }
    
    var timeSet = Date()
    func setNewSum() {
        //self.listeningFor = .Number
        meterSpeed = NormalMeterSpeed
        tickOrCross.image = nil
        answerInput.text = ""
        correctAnswer.text = ""
        sum = user.pickSum(level: level)
        speak(sum: sum)
        n1.text = "\(sum.n1)"
        n2.text = "\(sum.n2)"
        timeSet = Date()
        listen(for: .Number)
    }
    
    func speak(sum: Sum) {
        say(" \(sum.n1) \(sum.op) \(sum.n2)")
    }
    
    var sumToBeSet = false
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        actionQueue.actionCompleted()
        /*
        if utterances.count == 0 { startListening() }
        if !paused {
            if sumToBeSet && utterances.count == 0 {
                sumToBeSet = false
                setNewSum()
            }
            if utterances.count > 0 {
                let utterance = utterances.popLast()!
                speaker.speak(utterance)
            }
        }
 */
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
        /*
        if speaker.isSpeaking {
            utterances.insert(utterance, at: 0)
        } else {
            
            speaker.speak(utterance)
        }
 */
    }
    
    /*
    func say(_ words: String, completion: () -> ()) {
        say(words)
        completion
    }
 */
    
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
            case 3:
                say("great job \(user.name)")
            case 4:
                say("well done \(user.name), have a song.")
                playMusic(name: "dance_song", length: 5)
            case 5, 6:
                say("nice work \(user.name)")
            case 7:
                say("that's right \(user.name), let's change the colour")
                let red = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let green = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let blue = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let colour = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
                view.backgroundColor = colour
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (isCorrect ? 1.0 : 2.5)) {
            self.setNewSum()
        }
    }
    
    var player: AVAudioPlayer?
    
    func playMusic(name: String, length: TimeInterval) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) //WILL THIS INTERFERE WITH RECORD?
            try AVAudioSession.sharedInstance().setActive(true)
            
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
    
}

/////////////////////// other stuff ////////////////////////

fileprivate func findYesNo(inString str: String) -> String? {
    let words = str.split(separator: " ")
    for word in words {
        switch word.lowercased() {
        case "yes":
            return "yes"
        case "no":
            return "no"
        default: return nil
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
        case "13", "thirteen":
            return 13
        case "14", "fourteen":
            return 14
        case "15", "fifteen":
            return 15
        case "16", "sixteen":
            return 16
        case "17", "seventeen":
            return 17
        case "18", "eighteen":
            return 18
        case "19", "nineteen":
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
        case "5", "five":
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
    if rand == 1 || rand == 2 { return getSillyName() }
    if transcription.lowercased() == "anna" && rand < 13 {
        return "Emma"
    }
    return transcription
}

fileprivate func getSillyName() -> String {
    let rand = arc4random_uniform(5)
    switch rand {
    case 0:
        return "Mr Tumble"
    case 1:
        return "Barnaby Bear"
    case 2:
        return "Wumplytoot"
    case 3:
        return "Pingu"
    case 4:
        return "Isadora Moon"
    case 5:
        return "Flibbertyjibbet"
    default:
        return "Wibble"
    }
}


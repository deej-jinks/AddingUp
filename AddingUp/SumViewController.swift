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

    var speechRecogniser: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    
    let speaker = AVSpeechSynthesizer()
    var voicePitch: Float = 1.0
    var speechRate: Float = 0.55
    var speechQueue = ""
    var utterances: [AVSpeechUtterance] = []
    
    @IBOutlet weak var n1: UILabel!
    @IBOutlet weak var n2: UILabel!
    @IBOutlet weak var answerInput: UILabel!
    @IBOutlet weak var correctAnswer: UILabel!
    @IBOutlet weak var tickOrCross: UIImageView!
    @IBOutlet weak var picturePlace: UIImageView!
    
    var sum: Sum!
    var user = User(name: "Emma")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speaker.delegate = self
        configureAudioSession()
        requestAuthorisations()
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
        setNewSum()
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
    
    func startListening() {
        self.recognitionTask = self.speechRecogniser!.recognitionTask(with: recognitionRequest!, resultHandler: { (result, error) in
            if let nonNilResult = result {
                let transcription = nonNilResult.bestTranscription.formattedString
                print(transcription)
                if let num = findNumbers(inString: transcription) {
                    self.answerInput.text = "\(num)"
                    self.checkAnswer(num)
                }
            }
        })
        self.audioEngine.prepare()
        do {try self.audioEngine.start()} catch {}
        print("Go ahead, I'm listening")
    }
    
    func stopListening() {
        recognitionTask?.cancel()
    }
    
    var timeSet = Date()
    func setNewSum() {
        tickOrCross.image = nil
        answerInput.text = ""
        correctAnswer.text = ""
        sum = user.pickSum()
        speak(sum: sum)
        n1.text = "\(sum.n1)"
        n2.text = "\(sum.n2)"
        timeSet = Date()
    }
    
    func speak(sum: Sum) {
        say(" \(sum.n1) \(sum.op) \(sum.n2)")
    }
    
    var sumToBeSet = false
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if sumToBeSet && utterances.count == 0 {
            setNewSum()
            sumToBeSet = false
        }
        if utterances.count > 0 {
            let utterance = utterances.popLast()!
            speaker.speak(utterance)
        } else {
            startListening()
        }
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
        if speaker.isSpeaking {
            utterances.insert(utterance, at: 0)
        } else {
            speaker.speak(utterance)
        }
    }
    
    //////////////////// Bits for Emma after here /////////////////////
    
    func checkAnswer(_ n: Int) {
        stopListening()
        let timeTaken = Date().timeIntervalSince(timeSet)
        let isCorrect = sum.submitAnswer(answer: n, timeTaken: timeTaken)
        print("\(isCorrect) answer submitted in time : \(timeTaken)")
        if isCorrect {
            let rand = arc4random_uniform(12)
            switch rand {
            case 0:
                say("That's right.")
            case 1:
                say("Well done, you're a superstar \(user.name)!")
            case 2:
                say("superstar")
            case 3:
                say("great")
            case 4:
                say("well done \(user.name), have a song. Heeeeey macarena ay!")
            case 5:
                say("nice work \(user.name)")
            case 6:
                say("that's right \(user.name), let's change the colour")
                let red = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let green = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let blue = CGFloat(arc4random())/CGFloat(UINT32_MAX)
                let colour = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
                view.backgroundColor = colour
            case 7,8:
                if (picturePlace.image != #imageLiteral(resourceName: "unicorn")) {
                    say("fantastic! Have a unicorn")
                    picturePlace.image = #imageLiteral(resourceName: "unicorn")
                } else {
                    say("fantastic! Have a rainbow")
                    picturePlace.image = #imageLiteral(resourceName: "rainbow")
                }
            case 9, 10, 11:
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
            default:
                say("That's right. Well done \(user.name)!")
            }
            tickOrCross.image = #imageLiteral(resourceName: "tick")
        } else {
            let rand = arc4random_uniform(5)
            switch rand {
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
            default:
                say("I'm sorry, that's not right.")
            }
            tickOrCross.image = #imageLiteral(resourceName: "cross")
            correctAnswer.text = "\(sum.answer)"
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (isCorrect ? 0.5 : 1.5)) {
            if !self.speaker.isSpeaking {
                self.setNewSum()
            } else {
                self.sumToBeSet = true
            }
        }
    }
}


/////////////////////// other stuff ////////////////////////

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
        case "2", "two", "too", "to":
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
        case "8", "eight", "ate":
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


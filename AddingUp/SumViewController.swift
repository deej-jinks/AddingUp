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
    var speechQueue = ""
    
    @IBOutlet weak var n1: UILabel!
    @IBOutlet weak var n2: UILabel!
    @IBOutlet weak var answerInput: UITextField! {
        didSet {
            self.answerInput.delegate = self
        }
    }
    @IBOutlet weak var tickOrCross: UIImageView!
    
    var sum: Sum!
    var user = User(name: "Emma")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        answerInput.delegate = self
        speaker.delegate = self
        configureAudioSession()
        requestAuthorisations()
    }
    
    func configureAudioSession() {
        do {
            try self.audioSession.setCategory(AVAudioSessionCategoryRecord)
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
                if let num = self.findNumbers(inString: transcription) {
                    
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
    
    func speak(sum: Sum) {
        if speaker.isSpeaking {
            speechQueue += " \(sum.n1) \(sum.op) \(sum.n2)"
        } else {
            speaker.speak(AVSpeechUtterance(string: "\(sum.n1) \(sum.op) \(sum.n2)"))
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if speechQueue != "" {
            speaker.speak(AVSpeechUtterance(string: speechQueue))
            speechQueue = ""
        } else {
            startListening()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        stopListening()
        print("started talking")
    }
    /*
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        stopListening()
        print("continued talking")
    }
 */
    
    func findNumbers(inString str: String) -> Int? {
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
            case "6", "six":
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

    var timeSet = Date()
    func setNewSum() {
       
        tickOrCross.image = nil
        sum = user.pickSum()
        speak(sum: sum)
        n1.text = "\(sum.n1)"
        n2.text = "\(sum.n2)"
        answerInput.text = ""
        answerInput.becomeFirstResponder()
        timeSet = Date()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == answerInput else { return }

        checkAnswer(Int(textField.text!)!)
    }
    
    func checkAnswer(_ n: Int) {
        stopListening()
        let timeTaken = Date().timeIntervalSince(timeSet)
        let isCorrect = sum.submitAnswer(answer: n, timeTaken: timeTaken)
        print("\(isCorrect) answer submitted in time : \(timeTaken)")
        if isCorrect {
            speaker.speak(AVSpeechUtterance(string: "That's right. Well done \(user.name)!"))
            tickOrCross.image = #imageLiteral(resourceName: "tick")
        } else {
            speaker.speak(AVSpeechUtterance(string: "I'm sorry, that's not right."))
            tickOrCross.image = #imageLiteral(resourceName: "cross")
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.setNewSum()
        }
    }

    
}


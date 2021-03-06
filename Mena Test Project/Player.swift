//
//  Player.swift
//  Mena Test Project
//
//  Created by Ivan Blagajić on 19/12/2017.
//  Copyright © 2017 modacity. All rights reserved.
//

import AudioKit
import RxSwift

class Player {

    let bank = AKFMOscillatorBank()
    let mixer: AKMixer
    let nodeRecorder: AKNodeRecorder
    var recordPlayer: AKAudioPlayer?

    let recordings = Variable<[String]>([])
    let recording = Variable<Bool>(false)
    var activeNotes = Set<MIDINoteNumber>()
    var sustain = false {
        didSet {
            if !sustain {
                stopAll()
            }
        }
    }

    init() {
        AKAudioFile.cleanTempDirectory()

        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }

        AKSettings.defaultToSpeaker = true

        do {
            recordPlayer = try AKAudioPlayer(file: AKAudioFile())
            recordPlayer?.volume = 2
        } catch {
            print(error.localizedDescription)
        }

        mixer = AKMixer(bank, recordPlayer)

        let microphone = AKMicrophone()
        let microphoneMixer = AKMixer(microphone)
        do {
            nodeRecorder = try AKNodeRecorder(node: microphoneMixer)
        } catch {
            fatalError()
        }

        setupOscillator()

        AudioKit.output = mixer
        AudioKit.start()

        refreshRecordings()
    }

    private func setupOscillator() {
        bank.attackDuration = 0.1
        bank.decayDuration = 0.3
        bank.sustainLevel = 0.1
        bank.releaseDuration = 0.5
    }

    func play(note: MIDINoteNumber) {
        bank.play(noteNumber: note, velocity: 80)
        activeNotes.insert(note)
    }

    func stop(note: MIDINoteNumber) {
        let offset = DispatchTime.now() + .milliseconds(Int(bank.releaseDuration * 1000))
        DispatchQueue.main.asyncAfter(deadline: offset) { [weak self] in
            if let sustainOn = self?.sustain,
                !sustainOn {
                self?.activeNotes.remove(note)
                self?.bank.stop(noteNumber: note)
            }
        }
    }

    func stopAll() {
        for note in activeNotes {
            bank.stop(noteNumber: note)
        }
        activeNotes.removeAll()
    }

    func toggleRecord() {
        if nodeRecorder.isRecording {
            finishRecording()
            recording.value = false
        } else {
            startRecording()
            recording.value = true
        }
    }

    private func startRecording() {
        do {
            try nodeRecorder.reset()
            try nodeRecorder.record()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func finishRecording() {
        nodeRecorder.stop()
        let name = "\(recordings.value.count)"
        nodeRecorder.audioFile?.exportAsynchronously(name: name, baseDir: .documents, exportFormat: .m4a)
        { [weak self] _, exportError in
            if let error = exportError {
                print("Export Failed \(error)")
            } else {
                self?.refreshRecordings()
            }
        }
    }

    private func refreshRecordings() {
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("error: can't fetch documents directory")
        }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            recordings.value = directoryContents.filter{ $0.pathExtension == "m4a" }
                .map { $0.lastPathComponent }.sorted { $0 > $1 }
        } catch {
            print(error.localizedDescription)
        }
    }

    func play(recordingNamed name: String) {
        recordPlayer?.stop()
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("error: can't fetch documents directory")
        }
        do {
            let url = documentsUrl.appendingPathComponent(name)
            let file = try AKAudioFile(forReading: url)
            try recordPlayer?.replace(file: file)
            recordPlayer?.play()
        } catch {
            print(error.localizedDescription)
        }
    }

}

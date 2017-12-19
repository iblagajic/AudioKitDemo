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

    let bank = AKOscillatorBank()
    let mixer: AKMixer
    let nodeRecorder: AKNodeRecorder
    var recordPlayer: AKAudioPlayer?

    let recordings = Variable<[String]>([])
    let recording = Variable<Bool>(false)

    init() {
        AKAudioFile.cleanTempDirectory()
        AKSettings.bufferLength = .medium

        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }

        AKSettings.defaultToSpeaker = true
        
        bank.attackDuration = 0.01
        bank.decayDuration = 0.1
        bank.sustainLevel = 0.1
        bank.releaseDuration = 0.3

        mixer = AKMixer(bank)

        do {
            nodeRecorder = try AKNodeRecorder(node: mixer)
        } catch {
            fatalError()
        }

        AudioKit.output = mixer
        AudioKit.start()

        refreshRecordings()
    }

    func play(note: Note) {
        AudioKit.output = mixer
        let midiNumber = note.midiNumber(inOctave: 4)
        bank.play(noteNumber: midiNumber, velocity: 80)
    }

    func stop(note: Note) {
        let midiNumber = note.midiNumber(inOctave: 4)
        bank.stop(noteNumber: midiNumber)
    }

    func toggleRecord() {
        if nodeRecorder.isRecording {
            finishRecording()
            recording.value = false
            try? nodeRecorder.reset()
        } else {
            startRecording()
            recording.value = true
        }
    }

    private func startRecording() {
        do {
            try nodeRecorder.record()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func finishRecording() {
        nodeRecorder.stop()
        let name = "recording_\(recordings.value.count)"
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
                .map { $0.lastPathComponent }
        } catch {
            print(error.localizedDescription)
        }
    }

    func play(recordingNamed name: String) {
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("error: can't fetch documents directory")
        }
        do {
            let url = documentsUrl.appendingPathComponent(name)
            let file = try AKAudioFile(forReading: url)
            recordPlayer = try AKAudioPlayer(file: file)
            AudioKit.output = recordPlayer
            recordPlayer?.play()
        } catch {
            print(error.localizedDescription)
        }
    }

    func stopPlaying() {
        recordPlayer?.stop()
    }

}

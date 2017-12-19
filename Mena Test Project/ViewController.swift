//
//  ViewController.swift
//  Mena Test Project
//
//  Created by Marc Gelfo on 12/16/17.
//  Copyright © 2017 modacity. All rights reserved.
//

import UIKit
import AudioKit
import RxSwift
import RxCocoa
import AudioKitUI

class ViewController: UIViewController, AKKeyboardDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var keyboardContainer: UIView!
    @IBOutlet weak var sustainPedal: UIButton!
    
    let player = Player()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        player.recordings
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "RecordingCell", cellType: UITableViewCell.self)) { (_, object, cell) in
                cell.textLabel?.text = "Play " + object
            }.disposed(by: disposeBag)
        tableView.rx.modelSelected(String.self).asDriver().drive(onNext: { [weak self] name in
            self?.player.play(recordingNamed: name)
        }).disposed(by: disposeBag)
        player.recording.asDriver().drive(onNext: { [weak self] isRecording in
            let title = isRecording ? "Done" : "Record"
            self?.recordButton.setTitle(title, for: .normal)
            self?.recordButton.backgroundColor = isRecording ? .gray : .red
        }).disposed(by: disposeBag)
        addKeyboard()
        styleRecordButton()
        styleSustainButton()
    }

    func noteOn(note: MIDINoteNumber) {
        player.play(note: note)
    }

    func noteOff(note: MIDINoteNumber) {
        player.stop(note: note)
    }

    @IBAction func record(_ sender: UIButton) {
        player.toggleRecord()
    }

    @IBAction func sustainPressed(_ sender: UIButton) {
        player.sustain = true
    }

    @IBAction func sustainReleased(_ sender: UIButton) {
        player.sustain = false
    }

    private func addKeyboard() {
        let keyboard = AKKeyboardView(width: 0, height: 0, firstOctave: 3, octaveCount: 1, polyphonic: true)
        keyboard.polyphonicMode = true
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboardContainer.addSubview(keyboard)
        keyboard.topAnchor.constraint(equalTo: keyboardContainer.topAnchor).isActive = true
        keyboard.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor).isActive = true
        keyboard.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor).isActive = true
        keyboard.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor).isActive = true
        keyboard.delegate = self
    }

    private func styleRecordButton() {
        recordButton.layer.cornerRadius = recordButton.frame.width/2
        recordButton.backgroundColor = .red
        recordButton.setTitleColor(.white, for: .normal)
    }

    private func styleSustainButton() {
        sustainPedal.setTitle("Sustain", for: .normal)
        sustainPedal.layer.cornerRadius = sustainPedal.frame.width/2
        sustainPedal.backgroundColor = .gray
        sustainPedal.setTitleColor(.white, for: .normal)
    }
}


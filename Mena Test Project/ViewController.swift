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

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!

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
        }).disposed(by: disposeBag)
    }

    @IBAction func keyTapped(_ sender: UIButton) {
        let note = Note(intValue: sender.tag)
        player.play(note: note)
    }

    @IBAction func keyReleased(_ sender: UIButton) {
        let note = Note(intValue: sender.tag)
        player.stop(note: note)
    }

    @IBAction func record(_ sender: UIButton) {
        player.toggleRecord()
    }
}


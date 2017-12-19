//
//  Note.swift
//  Mena Test Project
//
//  Created by Ivan Blagajić on 19/12/2017.
//  Copyright © 2017 modacity. All rights reserved.
//

enum Note: UInt8 {
    case c1 = 0
    case csharp
    case d
    case dsharp
    case e
    case f
    case fsharp
    case g
    case gsharp
    case a
    case asharp
    case b
    case c2

    init(intValue: Int) {
        let tag = UInt8(intValue)
        guard let note = Note(rawValue: tag) else {
            fatalError("error: unexpected note value")
        }
        self = note
    }

    func midiNumber(inOctave octave: UInt8?) -> UInt8 {
        // Lowest octave is marked as -1
        let multiplier = (octave ?? 4) + 1
        let numberOfNotes = Note.c2.rawValue
        return rawValue + numberOfNotes * multiplier
    }
}

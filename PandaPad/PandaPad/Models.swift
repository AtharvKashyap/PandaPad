//
//  Models.swift
//  PandaPad
//
//  Created by Atharv Kashyap on 8/14/24.
//

import Foundation
import OpenAI

enum VoiceChatState {
    case idle
    case recordingSpeech
    case processingSpeech
    case playingSpeech
    case error(Error)
}

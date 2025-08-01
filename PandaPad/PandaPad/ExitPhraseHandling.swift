//
//  ExitPhrases.swift
//  PandaPad
//
//  Created by Atharv Kashyap on 8/16/24.
//

import Foundation
struct ExitPhraseHandling {
    static let phrases: Set<String> = 
    [
        "bye", "bye panda", "see you later", "bye bye", "goodbye", "goodbye panda",
        "à plus tard", "au revoir panda", "au revoir", "à bientôt",
        "अलविदा", "बाई", "अलविदा पांडा",
        "totsiens panda", "totsiens",
        "وداعًا باندا", "وداعًا",
        "ցտեսություն պանդա", "ցտեսություն",
        "sağ ol panda", "sağ ol",
        "бывай, панда", "бывай",
        "zbogom panda", "zbogom",
        "довиждане панда", "довиждане",
        "adéu panda", "adéu",
        "再见熊猫", "再见",
        "zbogom panda", "zbogom",
        "sbohem panda", "sbohem",
        "farvel panda", "farvel",
        "dag panda", "dag",
        "nägemist panda", "nägemist",
        "hei hei panda", "hei hei",
        "adeus panda", "adeus",
        "tschüss panda", "tschüss",
        "αντίο πάντα", "αντίο",
        "להתראות פנדה", "להתראות",
        "viszlát panda", "viszlát",
        "bless panda", "bless",
        "selamat tinggal panda", "selamat tinggal",
        "ciao panda", "ciao",
        "さようならパンダ", "さようなら",
        "ವಿದಾಯ ಪಾಂಡಾ", "ವಿದಾಯ",
        "сау бол панда", "сау бол",
        "안녕 판다", "안녕",
        "uz redzēšanos panda", "uz redzēšanos",
        "sudie panda", "sudie",
        "чао панда", "чао",
        "selamat tinggal panda", "selamat tinggal",
        "निरोप पांडा", "निरोप",
        "poroporoaki panda", "poroporoaki",
        "विदा पाण्डा", "विदा",
        "ha det panda", "ha det",
        "خداحافظ پاندا", "خداحافظ",
        "do widzenia panda", "do widzenia",
        "tchau panda", "tchau",
        "la revedere panda", "la revedere",
        "пока панда", "пока",
        "збогом панда", "збогом",
        "zbohom panda", "zbohom",
        "adijo panda", "adijo",
        "adiós panda", "adiós",
        "kwa heri panda", "kwa heri",
        "hej då panda", "hej då",
        "paalam panda", "paalam",
        "போர்வாய்பாண்டா", "போர்வாய்",
        "ลาก่อนแพนด้า", "ลาก่อน",
        "hoşça kal panda", "hoşça kal",
        "бувай панда", "бувай",
        "خدا حافظ پانڈا", "خدا حافظ",
        "tạm biệt gấu trúc", "tạm biệt",
        "hwyl fawr panda", "hwyl fawr"
    ]
    
    static func isExitPhrase(in prompt: String) -> Bool {
        let normalizedPrompt = prompt.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        print("\n",normalizedPrompt,"\n")
        let words = normalizedPrompt.split(separator: " ")
        
        let lastOneWord = words.suffix(1).joined(separator: " ")
        let lastTwoWords = words.suffix(2).joined(separator: " ")
        let lastThreeWords = words.suffix(3).joined(separator: " ")
        
        for phrase in phrases{
            if normalizedPrompt.contains(phrase) {
                return true
            }
        }
        return phrases.contains(lastOneWord) || phrases.contains(lastTwoWords) || phrases.contains(lastThreeWords)
    }
}

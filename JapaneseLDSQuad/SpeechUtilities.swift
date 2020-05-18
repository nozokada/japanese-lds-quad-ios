//
//  SpeechUtilities.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/23/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

struct SpeechUtilities {
    
    static func correctPrimaryLang(speechText: String) -> String {
        var outputText = speechText
        outputText = outputText
            .replacingOccurrences(of: "聖徒", with: "せいと")
            .replacingOccurrences(of: "小羊", with: "こひつじ")
            .replacingOccurrences(of: "平安", with: "へいあん")
            .replacingOccurrences(of: "贖い主", with: "あがないぬし")
            .replacingOccurrences(of: "救い主", with: "すくいぬし")
            .replacingOccurrences(of: "すくい主", with: "すくいぬし")
            .replacingOccurrences(of: "創造主", with: "そうぞうぬし")
            .replacingOccurrences(of: "助け主", with: "たすけぬし")
            .replacingOccurrences(of: "主要", with: "しゅよう")
            .replacingOccurrences(of: "主", with: "しゅ")
            .replacingOccurrences(of: "御父", with: "おんちち")
            .replacingOccurrences(of: "御子", with: "おんこ")
            .replacingOccurrences(of: "御自身", with: "ごじしん")
            .replacingOccurrences(of: "御前", with: "みまえ")
            .replacingOccurrences(of: "レーマン人", with: "レーマンじん")
            .replacingOccurrences(of: "歴史家", with: "れきしか")
            .replacingOccurrences(of: "金版", with: "きんばん")
            .replacingOccurrences(of: "同胞", with: "はらから")
            .replacingOccurrences(of: "を証する", with: "をあかしする")
            .replacingOccurrences(of: "を証し", with: "をあかしし")
            .replacingOccurrences(of: "奥義", with: "おくぎ")
            .replacingOccurrences(of: "御座", with: "みざ")
            .replacingOccurrences(of: "紅海", with: "こうかい")
            .replacingOccurrences(of: "出て行った", with: "でていった")
            .replacingOccurrences(of: "宣べ伝え", with: "のべつたえ")
            .replacingOccurrences(of: "按手", with: "あんしゅ")
            .replacingOccurrences(of: "異言", with: "いげん")
            .replacingOccurrences(of: "る者", with: "るもの")
            .replacingOccurrences(of: "：", with: "；")
        
        return outputText
    }
    
    static func correctSecondaryLang(speechText: String) -> String {
        var outputText = speechText
        outputText = outputText.replacingOccurrences(of: "Nephi", with: "neefye")
        
        return outputText
    }
}

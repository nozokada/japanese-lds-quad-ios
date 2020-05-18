//
//  AppExtensions.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import AVFoundation
import StoreKit
import FirebaseAuth

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    var tagsRemoved: String {
        return replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression)
    }
    
    var verseAfterColonRemoved: String {
        return replacingOccurrences(of: "[：|:].*", with: "", options: .regularExpression)
    }
}

extension AVSpeechUtterance {
    
    var speakingPrimary: Bool {
        return voice?.language == Constants.Lang.primarySpeech
    }
    
    var speakingSecondary: Bool {
        return voice?.language == Constants.Lang.secondarySpeech
    }
}

extension SKProduct {
    
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}

extension AuthErrorCode {
    func getDescription(error: Error) -> String {
        if Utilities.shared.getSystemLang() != Constants.Lang.primary {
            return error.localizedDescription
        }
        switch self {
        case .emailAlreadyInUse:
            return "このメールアドレスはすでに使用されています"
        case .userDisabled:
             return "サービスの利用が停止されています"
        case .invalidEmail:
             return "メールアドレスの形式が正しくありません"
        case .wrongPassword:
             return "メールアドレスまたはパスワードが違います"
        case .userNotFound:
             return "メールアドレスまたはパスワードが違います"
        case .networkError:
             return "ネットワーク接続に失敗しました"
        case .weakPassword:
             return "パスワードは6文字以上にしてください"
        case .internalError:
             return "エラーが発生しました。しばらく時間をおいて再度お試しください"
        @unknown default:
            return error.localizedDescription
        }
    }
}

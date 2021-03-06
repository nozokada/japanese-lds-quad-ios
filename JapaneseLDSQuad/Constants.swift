//
//  Constants.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

struct Constants {
    
    struct File {
        static let initialRealm = "init.realm"
    }
    
    struct Version {
        static let realmSchema: UInt64 = 3
    }
    
    struct StoryBoardID {
        static let books = "books"
        static let chapters = "chapters"
        static let pages = "pages"
        static let content = "content"
        static let notes = "notes"
        static let settings = "settings"
        static let speech = "speech"
        static let purchase = "purchase"
        static let account = "account"
        static let signIn = "signIn"
        static let register = "register"
        static let password = "password"
        static let dialogue = "dialogue"
    }
    
    struct RestorationID {
        static let highlights = "highlights"
        static let account = "account"
    }
    
    struct ReuseID {
        static let bookCell = "bookCell"
        static let chapterCell = "chapterCell"
        static let searchResultCell = "searchResultCell"
        static let bookmarkCell = "bookmarkCell"
        static let highlightCell = "highlightCell"
    }
    
    struct AppInfo {
        static let bundleID = "com.nozokada.JapaneseLDSQuad"
        static let allFeaturesPassProductID = "com.nozokada.JapaneseLDSQuad.allFeaturesPass"
    }
    
    struct CollectionName {
        static let users = "users"
        static let bookmarks = "bookmarks"
        static let highlights = "highlights"
        static let scriptures = "scriptures"
    }
    
    struct FieldName {
        static let username = "username"
        static let createdAt = "createdAt"
        static let modifiedAt = "modifiedAt"
        static let text = "text"
        static let note = "note"
        static let scripture = "scripture"
        static let highlights = "highlights"
        static let content = "content"
        static let primary = "primary"
        static let secondary = "secondary"
    }
    
    struct Count {
        static let sectionsInBooksView = 1
        static let sectionsInTopBooksView = 2
        static let rowsForStandardWorks = 5
        static let rowsForResources = 2
        static let columnsForHighlightsView = 2
    }
    
    struct Config {
        static let font = "alternativeFontEnabled"
        static let night = "nightModeEnabled"
        static let dual = "dualEnabled"
        static let side = "sideBySideEnabled"
        static let size = "fontSize"
        static let rate = "speechRate"
        static let pass = "passPurchased"
        static let sync = "syncEnabled"
        static let lastSynced = "lastSyncedAt"
    }
    
    struct Lang {
        static let primary = "ja"
        static let secondary = "en"
        static let primarySpeech = "ja-JP"
        static let secondarySpeech = "en-US"
    }
    
    struct Font {
        static let kaku = "HiraKakuProN-W3"
        static let min = "HiraMinProN-W3"
    }
    
    struct Size {
        static let viewCornerRadius: CGFloat = 5
        static let highlightCellBorderWidth: CGFloat = 1
        static let highlightCellPadding: CGFloat = 6
        static let highlightCellLabelVerticalPadding: CGFloat = 12
        static let highlightCellLabelHorizontalPadding: CGFloat = 8
        static let noteViewTitleVerticalPadding: CGFloat = 20
        static let speechViewButtonVerticalPadding: CGFloat = 20
        static let settingsViewDimension = CGSize(width: 300, height: 300)
    }
    
    struct TextSize {
        static let standard: Float = 20
    }
    
    struct TextColor {
        static let day = UIColor.black
        static let night = UIColor(red: 0.73, green: 0.73, blue: 0.73, alpha: 1.0)
    }
    
    struct CellColor {
        static let day = UIColor.white
        static let night = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    }
    
    struct NavigationBarColor {
        static let day = UIColor(red: 0.26, green: 0.28, blue: 0.30, alpha: 1.0)
        static let night = UIColor(red: 0.26, green: 0.28, blue: 0.30, alpha: 1.0)
    }
    
    struct BackgroundColor {
        static let day = UIColor.white
        static let night = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        static let daySearchBar = UIColor(red: 0.79, green: 0.79, blue: 0.81, alpha: 1.0)
        static let nightSearchBar = UIColor(red: 0.20, green: 0.20, blue: 0.18, alpha: 1.0)
    }
    
    struct Rate {
        static let slideDurationInSec = 0.3
        static let speechRateMultiplierStep: Float = 0.1
        static let speechRateMaximumMultiplier: Float = 1.6
        static let speechRateMinimumMultiplier: Float = 0.4
    }
    
    struct ChapterType {
        static let number = "number"
        static let title = "title"
    }
    
    struct ContentType {
        static let hymn = "hymn"
        static let gs = "gs"
        static let aux = "aux"
        static let main = "main"
    }
    
    struct AnnotationType {
        static let bookmark = "bookmark"
        static let highlight = "highlight"
    }
    
    struct PaidContent {
        static let books = ["jst"]
    }
    
    struct Prefix {
        static let highlight = "highlight_"
    }
    
    struct RegexPattern {
        static let tags = "<((?!.?name|.?span).*?)ruby>|<(.*?)>"
        static let passage = "([123新](?!；)|ジ―)?((?<=[\\d章編>])；|[^\\x01-\\x7Eあ-を訳（［：；。，－]{1,5})(\\d{1,3}－\\d{1,3}|\\d{1,3})(?![^\\x01-\\x7E：；章編])：?(\\d{1,3}－\\d{1,3}|\\d{1,3})?(，\\d{1,3}－\\d{1,3}|，\\d{1,3})*"
        static let bar = "－.*"
    }
    
    struct Dictionary {
        static let activeLinks = [
            "1ニフ": "1_ne",
            "2ニフ": "2_ne",
            "ヤコ": "jacob",
            "エノ": "enos",
            "ジェロ": "jarom",
            "オム": "omni",
            "モ言": "w_of_m",
            "モサ": "mosiah",
            "アル": "alma",
            "ヒラ": "hel",
            "3ニフ": "3_ne",
            "4ニフ": "4_ne",
            "モル": "morm",
            "エテ": "ether",
            "モロ": "moro",
            "教義": "dc",
            "モセ": "moses",
            "アブ": "abr"]
        
        static let inactiveLinks = [
            "ジ―歴史": "js_h",
            "ジ―マタ": "js_m",
            "マタイ": "matt",
            "マタ": "matt",
            "マコ": "mark",
            "マルコ": "mark",
            "ルカ": "luke",
            "ヨハ": "john",
            "ヨハネ": "john",
            "使徒": "acts",
            "ロマ": "rom",
            "1コリント": "1_cor",
            "1コリ": "1_cor",
            "2コリ": "2_cor",
            "ガラ": "gal",
            "エペ": "eph",
            "ピリ": "philip",
            "コロ": "col",
            "1テサ": "1_thes",
            "2テサ": "2_thes",
            "1テモ": "1_tim",
            "2テモ": "2_tim",
            "テト": "titus",
            "ピレ": "philem",
            "ヘブ": "heb",
            "新約ヤコブ": "james",
            "新ヤコ": "james",
            "1ペテ": "1_pet",
            "2ペテ": "2_pet",
            "1ヨハ": "1_jn",
            "2ヨハ": "2_jn",
            "3ヨハ": "3_jn",
            "ユダ": "jude",
            "黙示": "rev",
            "創世": "gen",
            "出エジプト": "ex",
            "出エ": "ex",
            "レビ": "lev",
            "民数": "num",
            "申命": "deut",
            "ヨシ": "josh",
            "士師": "judg",
            "ルツ": "ruth",
            "サ上": "1_sam",
            "サ下": "2_sam",
            "列上": "1_kgs",
            "列王下": "2_kgs",
            "列下": "2_kgs",
            "歴上": "1_chr",
            "歴下": "2_chr",
            "エズ": "ezra",
            "ネヘ": "neh",
            "エス": "esth",
            "ヨブ": "job",
            "詩篇": "ps",
            "箴言": "prov",
            "伝道": "eccl",
            "雅歌": "song",
            "イザヤ": "isa",
            "イザ": "isa",
            "エレミヤ書": "jer",
            "エレ": "jer",
            "哀歌": "lam",
            "エゼキエル": "ezek",
            "エゼ": "ezek",
            "ダニ": "dan",
            "ホセ": "hosea",
            "ヨエ": "joel",
            "アモ": "amos",
            "オバ": "obad",
            "ヨナ": "jonah",
            "ミカ": "micah",
            "ナホ": "nahum",
            "ハバ": "hab",
            "ゼパ": "zeph",
            "ハガ": "hag",
            "ゼカ": "zech",
            "マラキ": "mal",
            "マラ": "mal",
            "；": "；"]
    }
}

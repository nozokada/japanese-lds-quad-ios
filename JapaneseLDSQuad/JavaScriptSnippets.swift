//
//  JavaScriptSnippets.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

struct JavaScriptSnippets {
    
    static func updateDualMode() -> String {
        let displayValue = Utilities.shared.dualEnabled ? "" : "none"
        return """
            var elements = document.getElementsByClassName('secondary');
            for (element of elements) {
                element.style.display = '\(displayValue)';
            }
        """
    }
    
    static func updateSideBySideMode() -> String {
        let methodName = Utilities.shared.sideBySideEnabled ? "add" : "remove"
        return """
            var elements = document.querySelectorAll('.verse,.hymn-verse,.paragraph');
            for (element of elements) {
                element.classList.\(methodName)('side');
            }
        """
    }
    
    static func updateAppearance() -> String {
        let font = Utilities.shared.getCSSFont()
        let fontSize = Utilities.shared.fontSizeMultiplier
        let fontColor = Utilities.shared.getCSSTextColor()
        let backgroundColor = Utilities.shared.getCSSBackgroundColor()
        return """
            var elements = document.querySelectorAll('body,tr,.verse-number');
            for (element of elements) {
                element.style.color = '\(fontColor)'
                if (element.classList.contains('verse-number')) { continue; }
                element.style.backgroundColor = '\(backgroundColor)'
                element.style.fontFamily = '\(font)'
                element.style.fontSize = '\(fontSize)em'
            }
        """
    }
    
    static func updateVerse(scripture: Scripture) -> String {
        let bookmarked = BookmarksManager.shared.get(bookmarkId: scripture.id) != nil
        let methodName = bookmarked ? "add" : "remove"
        return """
        var verse = document.getElementById('\(scripture.id)');
        var primarySpan = verse.querySelectorAll('span[lang="\(Constants.Lang.primary)"]')[0];
        var secondarySpan = verse.querySelectorAll('span[lang="\(Constants.Lang.secondary)"]')[0];
        primarySpan.innerHTML = '\(scripture.scripture_primary)';
        secondarySpan.innerHTML = '\(scripture.scripture_secondary)';
        verse.classList.\(methodName)('bookmarked');
        """
    }
    
    static func getAnchorOffset() -> String {
        return """
            getAnchorOffset();
            function getAnchorOffset() {
               var anchor = document.getElementById('anchor');
               if (anchor == null) {
                   return 0;
               } else {
                   return anchor.offsetTop;
               }
            }
            """
    }
    
    static func updateBookmarkStatus(verseId: String) -> String {
        return """
            var verse = document.getElementById('\(verseId)');
            if (verse.classList.contains('bookmarked')) {
                verse.classList.remove('bookmarked');
            } else {
                verse.classList.add('bookmarked');
            }
            """
    }
    
    static func SpotlightTargetVerses() -> String {
        return """
            var verses = document.getElementsByClassName('targeted');
            for (verse of verses) {
                verse.style.backgroundColor = '#ffff66';
                verse.style.transition = 'background-color 1s linear';
                setTimeout(function() {
                    verse.style.background = 'transparent';
                }, 600);
            }
            """
    }
    
    static func getScriptureId() -> String {
        return """
            var selection = window.getSelection();
            var scriptureId = '';
            if(selection) {
                if(selection.rangeCount) {
                    var range = selection.getRangeAt(0);
                    scriptureId = findScriptureId(range.startContainer);
                }
            }
            scriptureId
            """
    }
    
    static func getScriptureContent() -> String {
        return """
            var selection = window.getSelection();
            var scriptureContent = '';
            if(selection) {
                if(selection.rangeCount) {
                    var range = selection.getRangeAt(0);
                    scriptureContent = getScriptureContent(range.startContainer);
                }
            }
            scriptureContent
            """
    }
    
    static func getScriptureLang() -> String {
        return """
            var selection = window.getSelection();
            var scriptureContentLang = '';
            if(selection) {
                if(selection.rangeCount) {
                    var range = selection.getRangeAt(0);
                    scriptureContentLang = getScriptureContentLang(range.startContainer);
                }
            }
            scriptureContentLang
            """
    }
    
    static func removeHighlight(textId: String) -> String {
        return """
            var highlightedText = document.getElementById('\(textId)');
            var parent = highlightedText.parentNode;
            while(highlightedText.firstChild)
                parent.insertBefore(highlightedText.firstChild, highlightedText);
            parent.removeChild(highlightedText);
            var scriptureContent = getScriptureContent(parent.firstChild);
            scriptureContent
            """
    }
    
    static func getScriptureLang(textId: String) -> String {
        return """
            var highlightedText = document.getElementById('\(textId)');
            var scriptureContentLang = getScriptureContentLang(highlightedText);
            scriptureContentLang
            """
    }
    
    static func getTextToHighlight(textId: String) -> String {
        return """
            var selection = window.getSelection();
            var highlightedText = '';
            if(selection) {
                if(selection.rangeCount) {
                    var range = selection.getRangeAt(0);
                    var startContainerTagName = range.startContainer.parentElement.tagName;
                    var startContainerNodeName = range.startContainer.nodeName;
                    if(startContainerTagName != 'SPAN') {
                        while(startContainerNodeName == 'RUBY'|| startContainerNodeName == 'RT' ||
                            startContainerNodeName == '#text') {
                            range.setStartBefore(range.startContainer);
                            startContainerNodeName = range.startContainer.nodeName;
                        }
                    }
                    var endContainerTagName = range.endContainer.parentElement.tagName;
                    var endContainerNodeName = range.endContainer.nodeName;
                    if(endContainerTagName != 'SPAN') {
                        while(endContainerNodeName == 'RUBY' || endContainerNodeName == 'RT' ||
                            endContainerNodeName == '#text') {
                            range.setEndAfter(range.endContainer);
                            endContainerNodeName = range.endContainer.nodeName;
                        }
                    }
                    highlightText(range, '\(textId)');
                    highlightedText = range.toString();
                }
            }
            highlightedText
            """
    }
}

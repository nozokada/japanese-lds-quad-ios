//
//  JavaScriptFunctions.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

struct JavaScriptSnippets {
    static func getHighlightedTextScript(textId: String) -> String {
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
    
    static func getScriptureIdScript() -> String {
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
    
    static func getScriptureContentScript() -> String {
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
    
    static func getScriptureLanguageScript() -> String {
        return """
            var selection = window.getSelection();
            var scriptureContentLanguage = '';
            if(selection) {
                if(selection.rangeCount) {
                    var range = selection.getRangeAt(0);
                    scriptureContentLanguage = getScriptureContentLanguage(range.startContainer);
                }
            }
            scriptureContentLanguage
            """
    }
    
    static func getScriptureContentLanguageScript(textId: String) -> String {
        return """
            var highlightedText = document.getElementById('\(textId)');
            var scriptureContentLanguage = getScriptureContentLanguage(highlightedText);
            scriptureContentLanguage
            """
    }
    
    static func getScriptureContentScript(textId: String) -> String {
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
    
    static func getBookmarkUpdateScript(verseId: String) -> String {
        return """
            var verse = document.getElementById('\(verseId)');
            if (verse.classList.contains('bookmarked')) {
                verse.classList.remove('bookmarked');
            }
            else {
                verse.classList.add('bookmarked');
            }
            """
    }
    
    static func getAnchorOffsetScript() -> String {
        return """
            getAnchorOffset();
            function getAnchorOffset() {
               var anchor = document.getElementById('anchor');
               if (anchor == null) {
                   return 0;
               }
               else {
                   return anchor.offsetTop;
               }
            }
            """
    }
    
    static func getVerseSpotlightScript(verseId: String) -> String {
        return """
            var verse = document.getElementById('\(verseId)');
            verse.style.backgroundColor = '#ffff66';
            verse.style.transition = 'background-color 1s linear';
            setTimeout(function() {
               verse.style.background = 'transparent';
            }, 600);
            """
    }
}

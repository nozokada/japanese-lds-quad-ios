//
//  JavaScriptFunctions.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/13/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

struct JavaScriptFunctions {
    
    static func getAllFunctions() -> String {
        return """
            \(getScriptureId())
            \(getScriptureContent())
            \(getScriptureContentLanguage())
            \(highlightText())
            \(callMarkSelector())
            """
    }
    
    static func getScriptureId() -> String {
        return """
            function findScriptureId(node) {
                var currentNode = node;
                while(!currentNode.parentElement.classList.contains('verse'))
                    currentNode = currentNode.parentNode;
                while(!currentNode.parentElement.hasAttribute('id'))
                    currentNode = currentNode.parentNode;
                return currentNode.parentElement.getAttribute('id');
            }
            """
    }
    
    static func getScriptureContent() -> String {
        return """
            function getScriptureContent(node) {
                var currentNode = node;
                while(!currentNode.parentElement.classList.contains('verse'))
                    currentNode = currentNode.parentNode;
                var currentElement = currentNode.parentElement;
                return currentElement.getElementsByTagName('span')[0].innerHTML;
            }
            """
    }
    
    static func getScriptureContentLanguage() -> String {
        return """
            function getScriptureContentLanguage(node) {
                var currentNode = node;
                while(!currentNode.parentElement.classList.contains('verse'))
                    currentNode = currentNode.parentNode;
                var currentElement = currentNode.parentElement;
                return currentElement.getElementsByTagName('span')[0].getAttribute('lang');
            }
            """
    }
    
    static func highlightText() -> String {
        return """
            function highlightText(range, highlightedTextId) {
                var mark = document.createElement('mark');
                mark.setAttribute('id', highlightedTextId);
                mark.setAttribute('onclick', 'callMarkSelector(\"' + highlightedTextId + '\");');
                range.surroundContents(mark);
            }
            """
    }
    
    static func callMarkSelector() -> String {
        return """
            function callMarkSelector(markId) {
                window.location = markId + '/highlight';
            }
            """
    }
}

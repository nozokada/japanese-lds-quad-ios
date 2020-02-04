//
//  ContentWebView.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import WebKit

class ContentWebView: WKWebView {

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        loadJavascriptFunctions()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        loadJavascriptFunctions()
//    }
//
//    convenience init() {
//        self.init(frame: CGRect.zero)
//    }
//
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        switch action {
//        case #selector(copy(_:)), Selector(("_define:")):
//            return true
//        default:
//            return false
//        }
//    }
//
//    func loadJavascriptFunctions() {
//        let highlightText = """
//            function highlightText(range, highlightedTextId) {
//                var mark = document.createElement('mark');
//                mark.setAttribute('id', highlightedTextId);
//                mark.setAttribute('onclick', 'callMarkSelector(\"' + highlightedTextId + '\");');
//                range.surroundContents(mark);
//            }
//            """
//
//        let getScriptureId = """
//            function findScriptureId(node) {
//                var currentNode = node;
//                while(currentNode.parentElement.className != 'verse')
//                    currentNode = currentNode.parentNode;
//                while(!currentNode.parentElement.hasAttribute('id'))
//                    currentNode = currentNode.parentNode;
//                return currentNode.parentElement.getAttribute('id');
//            }
//            """
//
//        let getScriptureContent = """
//            function getScriptureContent(node) {
//                var currentNode = node;
//                while(currentNode.parentElement.className != 'verse')
//                    currentNode = currentNode.parentNode;
//                var currentElement = currentNode.parentElement;
//                return currentElement.getElementsByTagName('span')[0].innerHTML;
//            }
//            """
//
//        let getScriptureContentLanguage = """
//            function getScriptureContentLanguage(node) {
//                var currentNode = node;
//                while(currentNode.parentElement.className != 'verse')
//                    currentNode = currentNode.parentNode;
//                var currentElement = currentNode.parentElement;
//                return currentElement.getElementsByTagName('span')[0].getAttribute('lang');
//            }
//            """
//
//        let callMarkSelector = """
//            function callMarkSelector(markId) {
//                window.location = markId + '/highlight';
//            }
//            """
//
//        stringByEvaluatingJavaScript(from:
//            """
//            \(highlightText)
//            \(getScriptureId)
//            \(getScriptureContent)
//            \(getScriptureContentLanguage)
//            \(callMarkSelector)
//            """
//        )
//    }
}

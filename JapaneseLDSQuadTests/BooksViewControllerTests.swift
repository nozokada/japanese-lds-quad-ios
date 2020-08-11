//
//  BooksViewControllerTests.swift
//  JapaneseLDSQuadTests
//
//  Created by Nozomi Okada on 8/11/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import XCTest
@testable import JapaneseLDSQuad

class BooksViewControllerTests: XCTestCase {
    
    var viewController: BooksViewController!

    override func setUp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.viewController =  storyboard.instantiateViewController(identifier: Constants.StoryBoardID.books) as? BooksViewController
        self.viewController.loadViewIfNeeded()
        self.viewController.tableView.reloadData()
    }
    
    func testStandardWorksCells() {
        let cell = self.viewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(cell?.textLabel?.text, "旧約聖書")
    }
}

//
//  BooksViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/2/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class BooksViewController: UIViewController {
    
    var targetBook: Book!
    var targetBookName: String!
    var books: Results<Book>!
    var isTopMenu = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setSettingsBarButton()
        targetBook = targetBook ?? Utilities.shared.getBook(linkName: "jlq")
        targetBookName = targetBookName ?? "rootViewTitle".localized
        navigationItem.title = targetBookName
        isTopMenu = targetBook.parent_book == nil
        books = targetBook.child_books.sorted(byKeyPath: "id")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.standard)
        tableView.rowHeight = UITableView.automaticDimension
        reload()
    }
    
    func initTargetBook(targetBook: Book) {
        self.targetBook = targetBook
        targetBookName = targetBook.name_primary
    }
}

extension BooksViewController: SettingsViewDelegate {

    func reload() {
        tableView.reloadData()
    }
}

extension BooksViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isTopMenu {
            return Constants.Count.sectionsInTopBooksView
        }
        return Constants.Count.sectionsInBooksView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isTopMenu {
            return section == 0
                ? Constants.Count.rowsForStandardWorks
                : Constants.Count.rowsForResources
        }
        return books.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isTopMenu {
            return section == 0
                ? "standardWorksGroupedTableViewLabel".localized
                : "resourcesGroupedTableViewLabel".localized
        }
        return Utilities.shared.getSystemLang() == Constants.Lang.primary
            ? targetBook.name_primary
            : targetBook.name_secondary
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.ReuseID.bookCell)
        let cellColor = Utilities.shared.getCellColor()
        let book = books[indexPath.row + groupedCellsOffset(section: indexPath.section)]

        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        cell.textLabel?.text = book.name_primary
        cell.textLabel?.font = Utilities.shared.getFont()
        cell.textLabel?.textColor = Utilities.shared.getTextColor()
        
        if Utilities.shared.dualEnabled {
            cell.detailTextLabel?.text = book.name_secondary
            cell.detailTextLabel?.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
            cell.detailTextLabel?.textColor = .gray
        }
        
        if Utilities.shared.isPaid(book: book) {
            cell.textLabel?.isEnabled = PurchaseManager.shared.allFeaturesUnlocked
            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.allFeaturesUnlocked
        }
        return cell
    }
    
    func groupedCellsOffset(section: Int) -> Int {
        return isTopMenu && section > 0 ? Constants.Count.rowsForStandardWorks : 0
    }
}


extension BooksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedBook = books[indexPath.row + groupedCellsOffset(section: indexPath.section)]
        
        if Utilities.shared.isPaid(book: selectedBook) {
            if !PurchaseManager.shared.allFeaturesUnlocked {
                presentPuchaseViewController()
                return
            }
        }
        
        if selectedBook.child_books.count > 0 {
            guard let viewController = storyboard?.instantiateViewController(
                withIdentifier: Constants.StoryBoardID.books) as? BooksViewController else {
                return
            }
            viewController.initTargetBook(targetBook: selectedBook)
            navigationController?.pushViewController(viewController, animated: true)
        }
        else if selectedBook.child_scriptures.sorted(byKeyPath: "id").last?.chapter == 1 {
            guard let viewController = storyboard?.instantiateViewController(
                withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController else {
                return
            }
            viewController.initData(targetScriptureData: TargetScriptureData(book: selectedBook, chapter: 1))
            navigationController?.pushViewController(viewController, animated: true)
        }
        else {
            guard let viewController = storyboard?.instantiateViewController(
                withIdentifier: Constants.StoryBoardID.chapters) as? ChaptersViewController else {
                return
            }
            viewController.initTargetBook(targetBook: selectedBook)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

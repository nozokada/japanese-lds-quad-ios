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
    
    var realm: Realm!
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
        realm = try! Realm()
        targetBook = targetBook ?? realm.objects(Book.self).filter("id = '0'").first
        targetBookName = targetBookName ?? "rootViewTitle".localized
        navigationItem.title = targetBookName
        isTopMenu = targetBook.parent_book == nil
        books = targetBook.child_books.sorted(byKeyPath: "id")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.FontSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
        reload()
    }
    
    func initTargetBook(targetBook: Book) {
        self.targetBook = targetBook
        targetBookName = targetBook.name_primary
    }
}

extension BooksViewController: SettingsChangeDelegate {

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
        return Locale.current.languageCode == Constants.LanguageCode.primary
            ? targetBook.name_primary
            : targetBook.name_secondary
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.ReuseID.bookCell)
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.CellColor.night
            : Constants.CellColor.day
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font)
            ? Constants.Font.min
            : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        let book = books[indexPath.row + groupedCellsOffset(section: indexPath.section)]

        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        cell.textLabel?.text = book.name_primary
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.FontColor.night
            : Constants.FontColor.day
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            cell.detailTextLabel?.text = book.name_secondary
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize / 1.6))
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        
        if Constants.PaidContent.books.contains(book.link) {
            cell.isUserInteractionEnabled = PurchaseManager.shared.isPurchased
            cell.textLabel?.isEnabled = PurchaseManager.shared.isPurchased
            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.isPurchased
        }
        return cell
    }
    
    func groupedCellsOffset(section: Int) -> Int {
        return isTopMenu && section > 0 ? Constants.Count.rowsForStandardWorks : 0
    }
}


extension BooksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = books[indexPath.row + groupedCellsOffset(section: indexPath.section)]
        if selectedBook.child_books.count > 0 {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.books) as? BooksViewController {
                viewController.initTargetBook(targetBook: selectedBook)
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
        else if selectedBook.child_scriptures.sorted(byKeyPath: "id").last?.chapter == 1 {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
                viewController.initData(targetScriptureData: TargetScriptureData(book: selectedBook, chapter: 1))
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
        else {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.chapters) as? ChaptersViewController {
                viewController.initTargetBook(targetBook: selectedBook)
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

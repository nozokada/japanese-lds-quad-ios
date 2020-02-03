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
    var booksList: Results<Book>!
    
    var targetBookName = NSLocalizedString("rootViewTitle", comment: "Title shown in root view")
    var targetBook: Book!
    
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var dualSwitch: UIBarButtonItem!
//    @IBOutlet weak var passageLookUpViewButton: UIBarButtonItem!
//    @IBOutlet weak var highlightsViewButton: UIBarButtonItem!
    
    let numberOfSectionsForTopView = 2
    let numberOfSectionsForDefault = 1
    let numberOfRowsForStandardWorks = 5
    let numberOfRowsForResources = 2
    let sectionNumberOfStandardWorks = 0
    let sectionNumberOfResources = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        self.title = targetBookName
        targetBook = targetBook ?? realm.objects(Book.self).filter("id = '0'").first
        booksList = targetBook.child_books.sorted(byKeyPath: "id")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.FontSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
//        reload()
    }
    
//    @IBAction func rootButtonTapped(_ sender: Any) {
//        popToRootViewController()
//    }
//
//    @IBAction func passageLookupViewButtonTapped(_ sender: Any) {
//        presentPassageLookupViewController()
//    }
//
//    @IBAction func searchButtonTapped(_ sender: Any) {
//        presentSearchViewController()
//    }
//
//    @IBAction func bookmarksButtonTapped(_ sender: Any) {
//        presentBookmarksViewController()
//    }
//
//    @IBAction func highlightsButtonTapped(_ sender: Any) {
//        presentHighlightsViewController()
//    }
//
//    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
//        presentSettingsTableViewController(sender)
//    }
//
//    @IBAction func dualSwitchToggled(_ sender: Any) {
//        changeDualMode()
//    }
//
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return .none
//    }
}


//extension BooksViewController: UpperBarButtonsDelegate {
//
//    func reload() {
//        updateDualSwitch()
//        updateAdditionalFeatureBarButtons()
//        tableView.reloadData()
//    }
//}


extension BooksViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if targetBook.parent_book == nil {
            return numberOfSectionsForTopView
        }
        return numberOfSectionsForDefault
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if targetBook.parent_book == nil {
            return section == sectionNumberOfStandardWorks ?
                numberOfRowsForStandardWorks : numberOfRowsForResources
        }
        return booksList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if targetBook.parent_book == nil {
            return section == sectionNumberOfStandardWorks ?
                NSLocalizedString("standardWorksGroupedTableViewLabel", comment: "Label for Standard Works") :
                NSLocalizedString("resourcesGroupedTableViewLabel", comment: "Label for Resources")
        }
        
        return Locale.current.languageCode == Constants.LanguageCode.primary ?
            targetBook.name_primary : targetBook.name_secondary
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            Constants.CellColor.night : Constants.CellColor.day
        
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font) ?
            Constants.Font.min : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        
        let groupedTableCellOffset = targetBook.parent_book == nil && indexPath.section == sectionNumberOfResources ?
            numberOfRowsForStandardWorks : 0
        
        let book = booksList[indexPath.row + groupedTableCellOffset]
        
//        if Constants.PaidContents.Books.contains(book.link) {
//            cell.isUserInteractionEnabled = PurchaseManager.shared.isPurchased
//            cell.textLabel?.isEnabled = PurchaseManager.shared.isPurchased
//            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.isPurchased
//        }

        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        cell.textLabel?.text = book.name_primary
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            Constants.FontColor.night : Constants.FontColor.day
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            cell.detailTextLabel?.text = book.name_secondary
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize / 1.6))
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        return cell
    }
}


extension BooksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let groupedTableCellOffset = targetBook.parent_book == nil && indexPath.section == sectionNumberOfResources ?
            numberOfRowsForStandardWorks : 0
        
        let nextBook = booksList[indexPath.row + groupedTableCellOffset]
        if nextBook.child_books.count > 0 {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: "books") as? BooksViewController {
                viewController.targetBookName = nextBook.name_primary
                viewController.targetBook = nextBook
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
//        else if nextBook.child_scriptures.sorted(byKeyPath: "id").last?.chapter == 1 {
//            if let viewController = storyboard?.instantiateViewController(withIdentifier: "content") as? ContentViewController {
//                viewController.targetBookName = nextBook.name_primary
//                viewController.targetBook = nextBook
//                viewController.targetChapterId = AppUtility.getChapterId(bookId: nextBook.id, chapter: 1)
//                self.navigationController?.pushViewController(viewController, animated: true)
//            }
//        }
//        else {
//            if let viewController = storyboard?.instantiateViewController(withIdentifier: "chapters") as? ChaptersViewController {
//                viewController.targetBookName = nextBook.name_primary
//                viewController.targetBook = nextBook
//                self.navigationController?.pushViewController(viewController, animated: true)
//            }
//        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


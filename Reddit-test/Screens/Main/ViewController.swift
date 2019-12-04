//
//  ViewController.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 02.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

   @IBOutlet private weak var table:UITableView?
   @IBOutlet private weak var loadingIndicator:UIActivityIndicatorView?
   
   private lazy var model = Model.defaultModel
   
   override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
      model.delegate = self
      let nib = UINib.init(nibName: "TableViewCell", bundle: nil)
      table?.register(nib, forCellReuseIdentifier: TableViewCell.reuseIdentifier)
      table?.estimatedRowHeight = 170.0
      table?.rowHeight = UITableView.automaticDimension
      table?.isHidden = true
      loadingIndicator?.startAnimating()
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      subscribeForThumbLoadingNotification()
      
      if model.entriesCount == 0 {
         model.getNextEntries()
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      unsubscribeFromNotifications()
   }
   
   deinit {
      unsubscribeFromNotifications()
   }
   
   private func subscribeForThumbLoadingNotification() {
      
      let noteName = NSNotification.Name(kThumbnailCachingFinishedNotification)
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleThumbnailNotification(_:)),
                                             name: noteName,
                                             object: nil)
      
      let errorNoteName = NSNotification.Name(kPostsLoadingErrorNotification)
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleThumbnailNotification(_:)),
                                             name: errorNoteName,
                                             object: model)
   }
   
   private func unsubscribeFromNotifications() {
      NotificationCenter.default.removeObserver(self)
   }
   
   @objc func handleThumbnailNotification(_ note:Notification) {
      if let obj = note.object as? Model,
         obj === model {
         if let info = note.userInfo, let error = info["error"] as? Error {
            displayAlertWith(title:"Posts loading faled", message: error.localizedDescription)
         }
         return
      }
      
      guard let userInfo = note.userInfo,
         let thumbURL = userInfo["url"] as? String,
         let pathToUpdate = model.indexPathForThumbUrl(thumbURL) else { return }
      
      if let visiblePaths = table?.indexPathsForVisibleRows,
         visiblePaths.contains(pathToUpdate) {
         table?.reloadRows(at: [pathToUpdate], with: UITableView.RowAnimation.none)
      }
   }
   
   private func pushFullSizeScreen() {
      
      let fullSizeScreen = FullSizeImageViewController(nibName: "FullSizeImageViewController",
                                                       bundle: nil)
         
      self.navigationController?.pushViewController(fullSizeScreen, animated: true)
   }
   
   private func displayAlertWith(title:String, message:String?) {
      let alert = UIAlertController(title: title,
                                    message: message,
                                    preferredStyle: .alert)
      let closeAction = UIAlertAction(title: "Close",
                                      style: UIAlertAction.Style.cancel) { (action) in
         alert.dismiss(animated: true, completion: nil)
      }
      alert.addAction(closeAction)
      present(alert, animated: true, completion: nil)
   }
   
   private func saveCurrentPageInfo() {
      
      guard let paths = table?.indexPathsForVisibleRows,
            let topPath = paths.first,
            let entry = model.entryFor(topPath) else { return }
      
      model.currentTopPost = entry.id
//      print("Scrolled to currentTopPost:  \(model.currentTopPost!)")
   }
   
   @objc func scrollToTopMostPost() {
      guard let topPostId = model.currentTopPost,
            let indexPath = model.indexPathForPostId(topPostId) else { return }
      
//      print("Scrolling to: \(topPostId)")
      
      table?.scrollToRow(at: indexPath, at: .top, animated: false)
   }
}

//MARK: - ModelDelegate

extension ViewController:ModelDelegate {
   func modelDidGetNextEntries() {
      
      if (model.entriesCount == 0) {
         model.getNextEntries() //load from the network
      }
      else {
         table?.delegate = self
         table?.dataSource = self
         table?.reloadData()
         
         loadingIndicator?.stopAnimating()
         table?.isHidden = false
         
         self.perform(#selector(scrollToTopMostPost),
                 with: nil,
                 afterDelay: 0.0,
                 inModes: [RunLoop.Mode.default])
      }
   }
}

//MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
      tableView.deselectRow(at: indexPath, animated: true)
      
      guard let redditPost = model.entryFor(indexPath),
            let imageURL = redditPost.imageURL,
            let cell = tableView.cellForRow(at: indexPath) as? TableViewCell,
            cell.isTappable else { return }
         
      model.setCurrentFullSizeImageURL(imageURL)
         
      pushFullSizeScreen()
   }
   
   func tableView(_ tableView: UITableView,
                  willDisplay cell: UITableViewCell,
                  forRowAt indexPath: IndexPath) {
      
      //thumbnails lazy loading
      if let aCell = cell as? TableViewCell {
         aCell.thumbnail = model.thumbnailFor(indexPath)
      }
      
      //some easy unsafe pagination
      if indexPath.row == (model.entriesCount - 1) {
         model.getNextEntries()
      }
   }
   
   //MARK: UIScrollViewDelegate
   func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      saveCurrentPageInfo()
   }
   
   func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      if !decelerate {
         saveCurrentPageInfo()
      }
   }
   
   func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
      saveCurrentPageInfo()
   }
}

//MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {

   func tableView(_ tableView: UITableView,
                  numberOfRowsInSection section: Int) -> Int {
      return model.entriesCount
   }

   func tableView(_ tableView: UITableView,
                  cellForRowAt indexPath: IndexPath) -> UITableViewCell {

      guard let cell = tableView.dequeueReusableCell(withIdentifier:TableViewCell.reuseIdentifier,
                                                     for: indexPath) as?  TableViewCell else {

         return TableViewCell(style: .default, reuseIdentifier:TableViewCell.reuseIdentifier)
      }
      
      if let redditPost = model.entryFor(indexPath) {
         cell.title = redditPost.title
         cell.author = redditPost.author
         cell.commentsCount = redditPost.commentsCount ?? 0
         cell.datePublished = Date(timeIntervalSince1970: TimeInterval(redditPost.created ?? 0) )
         cell.isTappable = redditPost.isTappable
      }

      return cell
   }
}


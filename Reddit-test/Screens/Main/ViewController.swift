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
   @IBOutlet private weak var backgroundLogo:UIImageView?
   @IBOutlet private weak var tableViewBottom:NSLayoutConstraint?
   
   
   private lazy var model = Model.defaultModel
   
   private var needsFullReload = false
   private var needsToLoadNewData = true
   private var currentOffset:CGFloat = 0.0
   
   override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
      model.delegate = self
      let nib = UINib.init(nibName: "TableViewCell", bundle: nil)
      table?.register(nib, forCellReuseIdentifier: TableViewCell.reuseIdentifier)
      table?.estimatedRowHeight = 170.0
      table?.rowHeight = UITableView.automaticDimension
      table?.isHidden = true
      backgroundLogo?.isHidden = false
      loadingIndicator?.startAnimating()
      needsFullReload = true
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
   
   //MARK: -
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
   
   //MARK: -
   
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
   }
   
   @objc func scrollToTopMostPost() {
      guard let topPostId = model.currentTopPost,
            let indexPath = model.indexPathForPostId(topPostId) else { return }
      
//      print("Scrolling to: \(topPostId)")
      
      UIView .animate(withDuration: 0.5) {[weak self] in
         self?.table?.scrollToRow(at: indexPath, at: .top, animated: false)
      }
   }
   
   private func beginPageLoadingAnimation( _ animationHasBegun:(() -> Void)?) {
      
      
      tableViewBottom?.constant = -100.0
      UIView.animate(withDuration: 0.25, animations:({[weak self] in
         self?.view.layoutIfNeeded()
      }), completion: {_ in
         self.loadingIndicator?.startAnimating()
         animationHasBegun?()
      })
   }
   
   private func finishPageLoadingAnimation() {
      
      tableViewBottom?.constant = 0.0
      
      UIView.animate(withDuration: 0.25, animations: {[weak self] in
         self?.view.layoutIfNeeded()
      }) { [weak self] _ in
         self?.loadingIndicator?.stopAnimating()
         
         self?.table?.reloadData()
      }
   }
}

//MARK: - ModelDelegate

extension ViewController:ModelDelegate {
   
   func modelDidGetNextEntries() {
      
      if (model.entriesCount == 0) {
         beginPageLoadingAnimation {
            self.model.getNextEntries() //load from the network
         }
         
      }
      else {
         table?.delegate = self
         table?.dataSource = self
         
         if needsFullReload {
            table?.reloadData()
         }
         
         
         table?.isHidden = false
         backgroundLogo?.isHidden = true
         
         if needsFullReload {
         self.perform(#selector(scrollToTopMostPost),
                 with: nil,
                 afterDelay: 0.5,
                 inModes: [RunLoop.Mode.default])
         }
         
         needsFullReload = false
         
         finishPageLoadingAnimation()
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
         needsToLoadNewData = true
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
   
   //load next page only after user`s request
   func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      currentOffset = table?.contentOffset.y ?? 0.0
   }
   
   func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                  withVelocity velocity: CGPoint,
                                  targetContentOffset: UnsafeMutablePointer<CGPoint>) {
      
      let targetOffset = targetContentOffset.pointee
      
      if velocity.y > 2.5 && targetOffset.y == currentOffset  {
         beginPageLoadingAnimation {[weak self] in
            self?.model.getNextEntries()
         }
      }
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


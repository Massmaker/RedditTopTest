//
//  FullSizeImageViewController.swift
//  Reddit-test
//
//  Created by Ivan Yavorin on 03.12.2019.
//  Copyright © 2019 Ivan Yavorin. All rights reserved.
//

import UIKit

class FullSizeImageViewController: UIViewController {

   var photoURLString:String?
   
   @IBOutlet private weak var imageView:UIImageView?
   @IBOutlet private weak var loadingIndicator:UIActivityIndicatorView?
   
   override func viewWillAppear(_ animated: Bool) {
      
      super.viewWillAppear(animated)
      
      loadingIndicator?.startAnimating()
      
      Model.defaultModel.getFullSizeImage { [weak self] (aImage) in
         self?.loadingIndicator?.stopAnimating()
         self?.imageView?.image = aImage
         self?.displaySaveToGalleryButtonIfNeeded()
      }
   }
   
   override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      displaySaveToGalleryButtonIfNeeded()
   }
   
   private func displaySaveToGalleryButtonIfNeeded() {
      if let _ = imageView?.image {
         let barButton = UIBarButtonItem(barButtonSystemItem: .save,
                                         target: self,
                                         action: #selector(saveImage))
         self.navigationItem.rightBarButtonItem = barButton
      }
      else {
         self.navigationItem.rightBarButtonItem = nil
      }
   }
   
   @objc func saveImage() {
      guard let image = imageView?.image else { return }
      let aQueue = DispatchQueue.init(label: "background",
                                      qos: DispatchQoS.background,
                                      attributes: [])
      aQueue.async {
         UIImageWriteToSavedPhotosAlbum(image,
                                        self,
                                        #selector(FullSizeImageViewController
                                          .image(_:didFinishSavingWithError:contextInfo:)),
                                        nil)
         //the completion selector is called on MainThread
      }
      
   }
   
   /// the format of the completion handler selector
   /// for "UIImageWriteToSavedPhotosAlbum"
   @objc func image(_ image:UIImage,
                    didFinishSavingWithError error:Error?,
                    contextInfo ctxInfo:UnsafeRawPointer) {
      
      if let anError = error {
         imageSavingFailed(anError.localizedDescription)
      }
      else {
         imageSavingFinished(self)
      }
   }
   
   private func imageSavingFinished(_ sender:AnyObject) {
     presentCloseAlertWith(title: "Image Saved",
                           message: "Image was saved to Saved Photos")
   }
   
   private func imageSavingFailed(_ errorMessage:String) {
      presentCloseAlertWith(title: "Image saving failed",
                            message: errorMessage)
   }
   
   private func presentCloseAlertWith(title:String, message:String) {
      
      let alert = UIAlertController(title:title ,
                                    message:message ,
                                    preferredStyle: .alert)
      
      let closeAction = UIAlertAction(title: "Close",
                                      style: .cancel) { _ in
         alert.dismiss(animated: true, completion: nil)
      }
      
      alert.addAction(closeAction)
      
      present(alert, animated: true, completion: nil)
   }
}

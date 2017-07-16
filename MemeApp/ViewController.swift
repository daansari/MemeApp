//
//  ViewController.swift
//  MemeApp
//
//  Created by Danish Ahmed Ansari on 7/13/17.
//  Copyright © 2017 DeepTurf. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var shareButton: UIBarButtonItem!    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    
    //    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    var originalImage: UIImage?
    var memedImage: UIImage?
    
    let textFieldDelegate = TextFieldDelegate()
    
    var scrollViewOriginY: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        shareButton.isEnabled = false
        
        topTextField.delegate = textFieldDelegate
        bottomTextField.delegate = textFieldDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollViewOriginY = self.view.frame.origin.y
        print("scrollViewOriginY - \(scrollViewOriginY)")
        
        subscribeToKeyboardNotifications()
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        let memeTextAttributes:[String:Any] = [
            NSStrokeColorAttributeName: UIColor.black,
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSStrokeWidthAttributeName: -5
        ]
        
        configure(textfield: topTextField, text: "TOP", defaultAttributes: memeTextAttributes)
        configure(textfield: bottomTextField, text: "BOTTOM", defaultAttributes: memeTextAttributes)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToKeyboardNotifications()
    }
    
    //    MARK: TextField UI
    func configure(textfield: UITextField, text: String?, defaultAttributes: [String: Any]?) {
        if let text = text {
            textfield.text = text
        }
        
        if let defaultAttributes = defaultAttributes {
            textfield.defaultTextAttributes = defaultAttributes
        }
        
        textfield.textAlignment = .center
        textfield.borderStyle = .none
    }
    
//    MARK: - IBAction
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        presentImagePickerWith(source: .photoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        presentImagePickerWith(source: .camera)
    }
    
    func presentImagePickerWith(source: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        present(imagePicker, animated: true) {
            
        }
    }
    
    @IBAction func shareAnImage(_ sender: Any) {
        memedImage = generateMemedImage()
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: originalImage!, memedImage: memedImage!)
        
        let vc = UIActivityViewController(activityItems: [meme.memedImage], applicationActivities: [])
        vc.completionWithItemsHandler = { (_, successful,_,_) in
            if successful {
                self.save()
            }
        }
        present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        shareButton.isEnabled = true
        cancelButton.isEnabled = true
        
        configure(textfield: topTextField, text: "TOP", defaultAttributes: nil)
        configure(textfield: bottomTextField, text: "BOTTOM", defaultAttributes: nil)
        originalImage = nil
        memedImage = nil
        memeImageView.image = nil
        
        shareButton.isEnabled = false
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image: UIImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            memeImageView.image = image
            originalImage = image
            shareButton.isEnabled = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
//    //    MARK: - Text Field Delegate
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
//    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        if textField.text == "TOP" || textField.text == "BOTTOM" {
//            textField.text = ""
//        }
//    }
    
    //    Move the view when keyboard covers the textfield
    func keyboardWillShow(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            self.view.frame.origin.y = scrollViewOriginY - getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            self.view.frame.origin.y = scrollViewOriginY
        }
    }
    
//    Get Keyboard Height
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
//    MARK: - Memed Image Save and Share
    func save() {
        if let memedImage = self.memedImage {
            UIImageWriteToSavedPhotosAlbum(memedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func generateMemedImage() -> UIImage {
        
        //        Render view to an image
        showOrHideNavBarAndToolbar(on: true)
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        showOrHideNavBarAndToolbar(on: false)
        return memedImage
    }
    
    func showOrHideNavBarAndToolbar(on: Bool) {
        self.navigationController?.setNavigationBarHidden(value, animated: true)
        toolbar.isHidden = on
    }
    
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage
        var memedImage: UIImage        
    }
    
//    MARK: - Transition Method
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        scrollViewOriginY = self.view.frame.origin.y
    }


}


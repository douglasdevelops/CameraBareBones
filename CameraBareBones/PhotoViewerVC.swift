//
//  PhotoViewerVC.swift
//  CameraBareBones
//
//  Created by Douglas Spencer on 8/29/17.
//  Copyright © 2017 Douglas Spencer. All rights reserved.
//

import UIKit

class PhotoViewerVC: UIViewController {
    
    @IBOutlet weak var myPhotoImageView: UIImageView!
    
    var photoFromCamera: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photoFromCamera {
            myPhotoImageView.image = photo
        }
    }

    @IBAction func Back_Pressed(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}

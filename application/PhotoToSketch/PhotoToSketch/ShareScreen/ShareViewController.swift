//
//  ShareViewController.swift
//  PhotoToSketch
//
//  Created by Fatma Naz Levent on 3.10.2021.
//

import UIKit

class ShareViewController: UIViewController {

	var processedImage : UIImage!
	
	@IBOutlet var targetImageView: UIImageView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		targetImageView.image = processedImage
    }
    
	@IBAction func backTapped(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction func retryTapped(_ sender: Any) {
		let vc =  self.navigationController?.viewControllers.filter({$0 is CameraViewController}).first as! CameraViewController
		vc.closeButtonTapped(UIButton())
		self.navigationController?.popToViewController(vc, animated: true)
	}
	
	@IBAction func shareTapped(_ sender: Any) {
		let activityItem: [AnyObject] = [processedImage as! AnyObject]
		let avc = UIActivityViewController(activityItems: activityItem as [AnyObject], applicationActivities: nil)
		self.present(avc, animated: true, completion: nil)
	}
	
}

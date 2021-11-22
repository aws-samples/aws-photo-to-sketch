//
//  PhotoToSketchLoader.swift
//  PhotoToSketch
//
//  Created by Fatma Naz Levent on 3.10.2021.
//
//  Loading indicator view is taken from : https://www.advancedswift.com/loading-overlay-view-fade-in-swift/
//  

import Foundation
import UIKit

class PhotoToSketchLoader: UIViewController {
	
	static let instance = PhotoToSketchLoader()
	
	func showLoader() {
		DispatchQueue.main.async {
			let loadingVC = PhotoToSketchLoader.instance
			loadingVC.modalPresentationStyle = .overCurrentContext
			loadingVC.modalTransitionStyle = .crossDissolve
			self.topViewController()?.present(loadingVC, animated: true, completion: nil)
		}
	}
	
	func hideLoader(){
		DispatchQueue.main.async {
			PhotoToSketchLoader.instance.dismiss(animated: true, completion: nil)
		}
	}
	
	func topViewController() -> UIViewController? {
		let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
		if var topController = keyWindow?.rootViewController {
			while let presentedViewController = topController.presentedViewController {
				topController = presentedViewController
			}
			return topController
		} else {
			return nil
		}
	}
	
	
	var loadingActivityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView()
		indicator.style = .large
		indicator.color = .white
		indicator.startAnimating()
		indicator.autoresizingMask = [
			.flexibleLeftMargin, .flexibleRightMargin,
			.flexibleTopMargin, .flexibleBottomMargin
		]
		return indicator
	}()
	
	var blurEffectView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: .dark)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.alpha = 0.8
		blurEffectView.autoresizingMask = [
			.flexibleWidth, .flexibleHeight
		]
		return blurEffectView
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		blurEffectView.frame = self.view.bounds
		view.insertSubview(blurEffectView, at: 0)
		loadingActivityIndicator.center = CGPoint(
			x: view.bounds.midX,
			y: view.bounds.midY
		)
		view.addSubview(loadingActivityIndicator)
	}
}

//
//  EffectApplyViewController.swift
//  PhotoToSketch
//
//  Created by Fatma Naz Levent on 3.10.2021.
//


import UIKit
import AVFoundation

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class EffectApplyViewController: UIViewController {

	@IBOutlet var rullerMiddleView: UIView!
	@IBOutlet var rulerSliderCollectionView: UICollectionView!
	@IBOutlet var effectsCollectionView: UICollectionView!
	
	@IBOutlet var targetView: UIView!
	@IBOutlet var originalImageView: UIImageView!
	@IBOutlet var targetImageView: UIImageView!
	
	@IBOutlet var cancelButton: UIButton!
	@IBOutlet var doneButton: UIButton!
	
	@IBOutlet var intensityBigView: UIView!
	@IBOutlet var intensityLabel: UILabel!
	@IBOutlet var intensityArrowImage: UIImageView!
	@IBOutlet var intensityViewHeightConstant: NSLayoutConstraint!
	
	let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	var intensityState = IntensityState.closed
	var targetImage : UIImage!
	var processedImage : UIImage!
	var depthData: AVDepthData?
	var shareImage : UIImage!
	var processedCIImage : CIImage!
	var maskingIntensity: CGFloat = 0.0
	var maskScale: CGFloat = 0.0
	var appliedEffect : PhotoEffect!
	var allGlobalPhotoEffects = [
		PhotoEffect(id: "1", name: "Vincent van Gogh", coverImage: UIImage(named: "vangogh")!),
		PhotoEffect(id: "2", name: "Georges Seurat", coverImage:  UIImage(named: "georges")!),
		PhotoEffect(id: "3", name: "Pablo Picasso", coverImage:  UIImage(named: "pablo")!),
		PhotoEffect(id: "4", name: "Franz Marc", coverImage:  UIImage(named: "franz")!)
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupViews()
		setupLabels()
		checkIntensityView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.rulerSliderCollectionView.scrollToItem(at: IndexPath(row: 11, section: 0), at: .right, animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		applyEffect(effect: allGlobalPhotoEffects[0])
	}
	
	func setupViews(){
		self.processedImage = self.targetImage
		self.originalImageView.image = self.targetImage
	}
	
	func setupLabels(){
		self.cancelButton.setTitle("Cancel", for: .normal)
		self.doneButton.setTitle("Done", for: .normal)
	}
	
	func checkIntensityView(){
		if(self.intensityState == .opened){
			intensityViewHeightConstant.constant = 80
			rulerSliderCollectionView.isHidden = false
			rullerMiddleView.isHidden = false
			intensityArrowImage.image = UIImage(systemName: "add")
			UIView.animate(withDuration: 0.5) {
				self.view.layoutIfNeeded()
			}
		}else if(self.intensityState == .closed){
			intensityViewHeightConstant.constant = 40
			rulerSliderCollectionView.isHidden = true
			rullerMiddleView.isHidden = true
			intensityArrowImage.image = UIImage(systemName: "add")
			UIView.animate(withDuration: 0.5) {
				self.view.layoutIfNeeded()
			}
		}
	}
	
	@IBAction func intensityTapped(_ sender: Any) {
		if(self.intensityState == .opened){
			self.intensityState = .closed
		}else if(self.intensityState == .closed){
			self.intensityState = .opened
		}
		self.checkIntensityView()
	}
	
	@IBAction func cancelTapped(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction func doneTapped(_ sender: Any) {
		self.shareImage = self.targetView.asImage()
		self.performSegue(withIdentifier: "share", sender: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if(segue.identifier == "share"){
			let dest = segue.destination as! ShareViewController
			dest.processedImage = self.shareImage
		}
	}
}

extension EffectApplyViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if(scrollView == rulerSliderCollectionView){
			let intensity = Int(scrollView.contentOffset.x / 85.0 * 10)
			self.maskingIntensity = CGFloat(intensity) / CGFloat(100)
			intensityLabel.text = "Intensity" + " " + "%" + intensity.description
			setMaskingIntensity(to: self.maskingIntensity)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if(collectionView == rulerSliderCollectionView){
			return 12
		}else{
			return allGlobalPhotoEffects.count
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if(collectionView == rulerSliderCollectionView){
			if(indexPath.row == 0 || indexPath.row == 11){
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCellId", for: indexPath) as! IntensityEmptyCollectionViewCell
				return cell
			}else{
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! IntensityCollectionViewCell
				return cell
			}
		}else{
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! EffectCollectionViewCell
			cell.loaderIndicator.startAnimating()
			cell.img.image = allGlobalPhotoEffects[indexPath.row].coverImage
			cell.img.layer.cornerRadius = 6
			cell.img.clipsToBounds = true
			cell.titleLabel.text = allGlobalPhotoEffects[indexPath.row].name
			cell.titleLabel.adjustsFontSizeToFitWidth = true
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if(collectionView == effectsCollectionView){
			self.applyEffect(effect: allGlobalPhotoEffects[indexPath.row])
		}
	}
	
	func applyEffect(effect : PhotoEffect){
		
		PhotoToSketchLoader.instance.showLoader()
		
		let imageData:Data = targetImage.pngData() ?? Data()
		let imageBase64 = imageData.base64EncodedString()
		let effectType = effect.id
		
		let parameters = "{\n    \"image\" : \"\(imageBase64)\",\n    \"effectType\" : \"\(effectType)\"\n}"
		let postData = parameters.data(using: .utf8)
		var request = URLRequest(url: URL(string: "https://v79143dgn5.execute-api.us-east-1.amazonaws.com/production/apply")!,timeoutInterval: Double.infinity)
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.httpBody = postData
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data else {
				print(String(describing: error))
				PhotoToSketchLoader.instance.hideLoader()
				return
			}
			
			let stringResult = String(data: data, encoding: .utf8)!
			let jsonData = Data(stringResult.utf8)
			let responseObject: ResponseResult = try! JSONDecoder().decode(ResponseResult.self, from: jsonData)
			//print("RESULT : \(responseObject.image ?? "NO IMAGE")")
			
			DispatchQueue.main.async {
				let imgDecoded = self.decodeBase64(toImage: responseObject.image)
				let imgMirrored = UIImage(cgImage: imgDecoded.cgImage!, scale: 1.0, orientation: .leftMirrored)
				let resultImg = imgMirrored //.rotate(radians: .pi/2)
				self.processedImage = resultImg
				self.targetImageView.image = resultImg
				self.targetImageView.alpha = 1.0
			}
			
			PhotoToSketchLoader.instance.hideLoader()
		}
		task.resume()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if(collectionView == rulerSliderCollectionView){
			if(indexPath.row == 0 || indexPath.row == 11){
				return CGSize(width: collectionView.frame.width / 2, height: 40)
			}else{
				return CGSize(width: 85, height: 40)
			}
			
		}else{
			return CGSize(width: 80, height: 90)
		}
	}
	
}


extension EffectApplyViewController : URLSessionDelegate {
	
	func decodeBase64(toImage strEncodeData: String!) -> UIImage {
		if let decData = Data(base64Encoded: strEncodeData, options: .ignoreUnknownCharacters) {
			return UIImage(data: decData)!
		}
		return UIImage()
	}
	
	func setMaskingIntensity(to value: CGFloat) {
		maskingIntensity = value
		DispatchQueue.main.async {
			self.targetImageView.alpha = self.maskingIntensity
		}
	}
	
}

enum IntensityState {
	case opened , closed
}

extension UIView {
	func asImage() -> UIImage {
		if #available(iOS 10.0, *) {
			let renderer = UIGraphicsImageRenderer(bounds: bounds)
			return renderer.image { rendererContext in
				layer.render(in: rendererContext.cgContext)
			}
		} else {
			UIGraphicsBeginImageContext(self.frame.size)
			self.layer.render(in:UIGraphicsGetCurrentContext()!)
			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			return UIImage(cgImage: image!.cgImage!)
		}
	}
}

extension UIImage {
	func rotate(radians: Float) -> UIImage? {
		var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
		// Trim off the extremely small float value to prevent core graphics from rounding it up
		newSize.width = floor(newSize.width)
		newSize.height = floor(newSize.height)

		UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
		let context = UIGraphicsGetCurrentContext()!

		// Move origin to middle
		context.translateBy(x: newSize.width/2, y: newSize.height/2)
		// Rotate around middle
		context.rotate(by: CGFloat(radians))
		// Draw the image at its center
		self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage
	}
}


struct PhotoEffect{
	let id : String
	let name : String
	let coverImage : UIImage
}

struct ResponseResult : Decodable {
	let image : String?
}

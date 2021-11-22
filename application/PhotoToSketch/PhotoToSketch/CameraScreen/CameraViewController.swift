//
//  CameraViewController.swift
//  PhotoToSketch
//
//  Created by Fatma Naz Levent on 3.10.2021.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewController: UIViewController {

	@IBOutlet var cameraSwitchView: UIView!
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var cameraView: UIView!
	@IBOutlet var cameraSwitchLabel: UILabel!
	@IBOutlet var closeButton: UIButton!
	@IBOutlet var recordButton: UIButton!
	@IBOutlet var galleryButton: UIButton!
	
	private let photoOutput = AVCapturePhotoOutput()
	private var captureSession : AVCaptureSession!
	private var imagePicker = UIImagePickerController()
	var captureState = CaptureState.capturing
	var cameraState = CameraState.back
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupViews()
		setupLabels()
		openCamera()
		cameraSwitchTapped(UIButton())
		self.navigationController?.isNavigationBarHidden = true
	}
	
	func setupViews(){
		self.recordButton.layer.cornerRadius = 20.0
		checkRecordState()
	}
	
	func setupLabels(){
		self.cameraSwitchLabel.text = "Camera Switch"
	}
	
	func checkRecordState(){
		if(self.captureState == .capturing){
			self.galleryButton.isHidden = false
			let img = UIImage(systemName: "record.circle")
			self.recordButton.setImage(img, for: .normal)
			self.recordButton.tintColor = .white
			self.cameraView.isHidden = false
			self.imageView.isHidden = true
			self.cameraSwitchView.isHidden = false
			if(self.captureSession != nil){
				self.captureSession.startRunning()
			}
		}else if(self.captureState == .captured){
			self.galleryButton.isHidden = true
			let img = UIImage(systemName: "stop")
			self.recordButton.setImage(img, for: .normal)
			self.recordButton.tintColor = .white
			self.cameraView.isHidden = true
			self.imageView.isHidden = false
			self.cameraSwitchView.isHidden = true
			if(self.captureSession != nil){
				self.captureSession.stopRunning()
			}
		}
	}
	
	@IBAction func cameraSwitchTapped(_ sender: Any) {

		if let session = self.captureSession {
			guard let currentCameraInput: AVCaptureInput = session.inputs.first else {
				return
			}

			session.beginConfiguration()
			session.removeInput(currentCameraInput)

			var newCamera: AVCaptureDevice! = nil
			if let input = currentCameraInput as? AVCaptureDeviceInput {
				if (input.device.position == .back) {
					cameraState = .front
					newCamera = cameraWithPosition(position: .front)
				} else {
					cameraState = .back
					newCamera = cameraWithPosition(position: .back)
				}
			}

			var err: NSError?
			var newVideoInput: AVCaptureDeviceInput!
			do {
				newVideoInput = try AVCaptureDeviceInput(device: newCamera)
			} catch let err1 as NSError {
				err = err1
				newVideoInput = nil
			}

			if newVideoInput == nil || err != nil {
				print("Error creating capture device input: \(err?.localizedDescription ?? "ERROR")")
			} else {
				session.addInput(newVideoInput)
			}

			session.commitConfiguration()
		}
	}
	
	func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
		for device in discoverySession.devices {
			if device.position == position {
				return device
			}
		}
		return nil
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		if(self.captureState == .capturing){
			
		}else if(self.captureState == .captured){
			self.captureState = .capturing
			self.checkRecordState()
		}
	}
	
	@IBAction func captureTapped(_ sender: Any) {
		if(self.captureState == .capturing){
			let photoSettings = AVCapturePhotoSettings()
			//XCODE-12 BUG
			//if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
				//photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
				
			//}
			photoOutput.capturePhoto(with: photoSettings, delegate: self)
		}else if(self.captureState == .captured){
			self.performSegue(withIdentifier: "effect", sender: nil)
		}
	}
	
	@IBAction func chooseFromGalleryTapped(_ sender: Any) {
		self.imagePicker.delegate = self
		self.imagePicker.allowsEditing = false
		self.imagePicker.sourceType = .savedPhotosAlbum
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if(segue.identifier == "effect"){
			let dest = segue.destination as! EffectApplyViewController
			dest.targetImage = self.imageView.image!
		}
	}
	
}

extension CameraViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
			self.imageView.contentMode = .scaleAspectFill
			self.imageView.image = pickedImage
			self.captureState = .captured
			self.checkRecordState()
		}

		dismiss(animated: true, completion: nil)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.imagePicker = UIImagePickerController()
		dismiss(animated: true, completion: nil)
	}
	
}

extension CameraViewController : AVCapturePhotoCaptureDelegate {
	
	private func openCamera() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized: // the user has already authorized to access the camera.
			self.setupCaptureSession()
		case .notDetermined: // the user has not yet asked for camera access.
			AVCaptureDevice.requestAccess(for: .video) { (granted) in
				if granted { // if user has granted to access the camera.
					print("the user has granted to access the camera")
					DispatchQueue.main.async {
						self.setupCaptureSession()
					}
				} else {
					print("the user has not granted to access the camera")
					self.handleDenied()
				}
			}
			
		case .denied:
			print("the user has denied previously to access the camera.")
			self.handleDenied()
		case .restricted:
			print("the user can't give camera access due to some restriction.")
			self.handleDenied()
		default:
			print("something has wrong due to we can't access the camera.")
			self.handleDismiss()
		}
	}
	
	func handleDenied(){
		DispatchQueue.main.async {
			let alert = UIAlertController(title: "Camera Access Denied", message: "Camera Access Denied!. In order to use this app, please go to Settings and give access to ", preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction(title: "Go To Settings", style: .cancel, handler: { (_) in
				let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
				UIApplication.shared.open(settingsUrl)
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	private func setupCaptureSession() {
		self.captureSession = AVCaptureSession()
		
		if let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) {
			do {
				let input = try AVCaptureDeviceInput(device: captureDevice)
				if captureSession.canAddInput(input) {
					captureSession.addInput(input)
				}
			} catch let error {
				print("Failed to set input device with error: \(error)")
			}
			
			if captureSession.canAddOutput(photoOutput) {
				captureSession.addOutput(photoOutput)
			}
			
			self.captureSession.beginConfiguration()
			self.captureSession.sessionPreset = .high
			self.captureSession.commitConfiguration()
			
			self.cameraView.layer.sublayers?.removeAll()
			let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			cameraLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 120.0)
			cameraLayer.videoGravity = .resizeAspectFill
			self.cameraView.layer.addSublayer(cameraLayer)
			
			captureSession.startRunning()
		}
	}
	
	@objc private func handleDismiss() {
		
	}

	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		guard let imageData = photo.fileDataRepresentation() else { return }
		var previewImage = UIImage(data: imageData)
		if(cameraState == .front){
			previewImage = UIImage(cgImage: previewImage!.cgImage!, scale: previewImage!.scale, orientation: .leftMirrored)
		}
		imageView.image = previewImage
		self.captureState = .captured
		self.checkRecordState()
	}
	
}


enum CameraState {
	case front , back
}

enum CaptureState {
	case capturing , captured
}

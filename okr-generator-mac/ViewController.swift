//
//  ViewController.swift
//  okr-generator-mac
//
//  Created by Jak Tiano on 4/12/19.
//  Copyright © 2019 Jak Tiano. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {

	@IBOutlet weak var webView: WKWebView!
	@IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var webViewWidthConstraint: NSLayoutConstraint!


	override func viewDidLoad() {

		super.viewDidLoad()

		// Do any additional setup after loading the view.
		loadWebView()
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func generatePNG(_ sender: Any) {

		webView.takeSnapshot(with: nil, completionHandler: { (image, error) in
			if let i = image {
				let path = self.userDesktop() + "/image.png"
				self.savePNG(image: i, size: self.getCardSize(), path: path)
			}
			if let e = error {
				print("snapshot error \(e)")
			}
		})
	}
	public func getCardSize() -> CGSize {

		return CGSize(width: webViewWidthConstraint.constant, height: webViewHeightConstraint.constant)
	}
	public func userDesktop() -> String {
		let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
		let userDesktopDirectory = paths[0]
		return userDesktopDirectory
	}
	func savePNG(image: NSImage, size: CGSize, path:String) {

		let sizedImage = image.resizeImage(width: size.width/2, size.height/2)
		let url = URL(fileURLWithPath: path)
		print("saving to url: \(url) with size: \(size)")
		let imageRep = NSBitmapImageRep(data: sizedImage.tiffRepresentation!)
		let pngData = imageRep?.representation(using: .png, properties: [:])
		do {
			try pngData?.write(to: url, options: .atomic)
		} catch {
			print("couldn't save png")
		}
	}

	// WebKit Stuff

	func loadWebView () {

		guard let fileURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "okr-generator") else {
			print("failed to get url to index.html")
			return
		}

		// load file
		webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)

		// adjust height
		webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
			self.webViewHeightConstraint.constant = height as! CGFloat + 20
		})

	}
}

extension NSImage {

	func resizeImage(width: CGFloat, _ height: CGFloat) -> NSImage {

		let img = NSImage(size: CGSize(width:width, height:height))

		img.lockFocus()
		let ctx = NSGraphicsContext.current
		ctx?.imageInterpolation = .high
		self.draw(in: NSMakeRect(0, 0, width, height), from: NSMakeRect(0, 0, size.width, size.height), operation: .copy, fraction: 1)
		img.unlockFocus()

		return img
	}
}

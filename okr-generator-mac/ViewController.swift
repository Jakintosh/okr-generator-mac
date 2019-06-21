//
//  ViewController.swift
//  okr-generator-mac
//
//  Created by Jak Tiano on 4/12/19.
//  Copyright © 2019 Jak Tiano. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, NSTextFieldDelegate {

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}

    // web view
	@IBOutlet weak var webView: WKWebView!
	@IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var webViewWidthConstraint: NSLayoutConstraint!

    // text fields
    @IBOutlet weak var objectiveHeader: NSTextField!
	@IBOutlet weak var objectiveText: NSTextField!
	@IBOutlet weak var keyResultHeader: NSTextField!

	// html ids
	private let objectiveHeaderId = "obj-header"
	private let objectiveTextId = "obj"
	private let keyResultHeaderId = "kr-header"

	// nsview stuff
	override func viewDidLoad() {

		super.viewDidLoad()

		// Do any additional setup after loading the view.
		loadWebView()

		objectiveHeader.preferredMaxLayoutWidth = 200

		objectiveHeader.delegate = self
		objectiveText.delegate = self
		keyResultHeader.delegate = self
	}

	// IBActions
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
	@IBAction func addKeyResult(_ sender: Any) {
		print("add key result")

		let textField = NSTextField(string: "Key Result")
		self.view.addSubview(textField)
	}

	// generation helpers
	public func getCardSize() -> CGSize {
		return CGSize(width: webViewWidthConstraint.constant, height: webViewHeightConstraint.constant)
	}
	public func userDesktop() -> String {
		let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
		let userDesktopDirectory = paths[0]
		return userDesktopDirectory
	}
	func savePNG(image: NSImage, size: CGSize, path:String) {
		let url = URL(fileURLWithPath: path)
		print("saving to url: \(url) with size: \(size)")
		let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
		let pngData = imageRep?.representation(using: .png, properties: [:])
		do {
			try pngData?.write(to: url, options: .atomic)
		} catch {
			print("couldn't save png")
		}
	}

	// key result ui stuff
	

	// delegate stuff
	func controlTextDidChange(_ obj: Notification) {

		updateWebView()
	}

	// WebKit stuff
	func loadWebView() {

		guard let fileURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "okr-generator") else {
			print("failed to get url to index.html")
			return
		}

		// load file
		webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)

		// configure view
		updateWebView()
	}
	func updateWebView() {

		// update text fields
		setHTML(text: getStringFromTextField(field: objectiveHeader), for: objectiveHeaderId)
		setHTML(text: getStringFromTextField(field: objectiveText), for: objectiveTextId)
		setHTML(text: getStringFromTextField(field: keyResultHeader), for: keyResultHeaderId)

		// adjust height
		getDocumentHeight { height in
			self.webViewHeightConstraint.constant = height
		}
	}

	// text field stuff
	func getStringFromTextField(field: NSTextField) -> String {

		if field.stringValue.isEmpty {
			if let placeholder = field.placeholderString {
				if !placeholder.isEmpty {
					return placeholder
				}
			}
		}
		return field.stringValue
	}

	// HTML stuff
	func setHTML(text: String, for id: String) {

		webView.evaluateJavaScript(
			"var e = document.getElementById(\"\(id)\");" +
			"e.innerHTML = \"\(text)\";"
			, completionHandler: { (_, _) in })
	}
	func getDocumentHeight( onComplete: @escaping (CGFloat) -> Void ) {

		webView.evaluateJavaScript("document.body.clientHeight;",
			completionHandler: { (h: Any?, error: Error?) in
				onComplete(h as! CGFloat)
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

//
//  ViewController.swift
//  WebViewToPdf
//
//  Created by Matthew on 24/11/2018.
//  Copyright © 2018 Matthew Usdin. All rights reserved.
//

import UIKit
import WebKit
import PDFGenerator
import MessageUI

class ViewController: UIViewController, WKUIDelegate, MFMailComposeViewControllerDelegate, WKNavigationDelegate {

    var webView: WKWebView!
    var imageWeb: UIImage!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(frame: CGRect(x: 100, y:  100, width: 100, height: 50))
        button.setTitle("Go PDF", for: .normal)
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        let myURL = URL(string:"https://www.apple.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        webView.addSubview(button)
    }
    
    @objc func buttonAction(sender : UIButton!){
        print("button tapped!")
        
        webView.evaluateJavaScript("document.body.textContent") { (result, error) in
            if let result = result {
                print(result)
            }
        }
        
//        generatePDF()
        
    }
    
    func generatePDF() {
        let v1 = UIScrollView(frame: CGRect(x: 0.0,y: 0, width: 100.0, height: 100.0))
        let v2 = UIView(frame: CGRect(x: 0.0,y: 0, width: 100.0, height: 200.0))
        let v3 = UIView(frame: CGRect(x: 0.0,y: 0, width: 100.0, height: 200.0))
        v1.backgroundColor = .red
        v1.contentSize = CGSize(width: 100.0, height: 200.0)
        v2.backgroundColor = .green
        v3.backgroundColor = .blue
        
        let dst = URL(fileURLWithPath: NSTemporaryDirectory().appending("sample1.pdf"))
        // outputs as Data
        do {
            
            let wholeImage = self.webView.takeScreenshot()
            let imageData = imageWeb!.pngData()
            
            let data = try PDFGenerator.generated(by: self.webView)
            sendMail(pdf: imageData!)

            try data.write(to: dst, options: .atomic)
            

        } catch (let error) {
            print(error)
        }
        
        // writes to Disk directly.
        do {
            try PDFGenerator.generate([v1, v2, v3], to: dst)
        } catch (let error) {
            print(error)
        }
    }

    
    func sendMail(pdf : Data) {
        if( MFMailComposeViewController.canSendMail()){
            print("Can send email.")

            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self

            //Set to recipients
            mailComposer.setToRecipients(["test@gmail.com"])

            //Set the subject
            mailComposer.setSubject("email with document pdf")

            //set mail body
            mailComposer.setMessageBody("This is what they sound like.", isHTML: false)
//            let pathPDF = "\(NSTemporaryDirectory())contract.pdf"

            mailComposer.addAttachmentData(pdf, mimeType: "application/pdf", fileName: "sample1.pdf")

            //this will compose and present mail to user
            self.present(mailComposer, animated: true, completion: nil)
        }

        else{
            print("email is not supported")
        }
        
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
        
    }
    
    /// Takes the screenshot of the screen and returns the corresponding image
    ///
    /// - Parameter shouldSave: Boolean flag asking if the image needs to be saved to user's photo library. Default set to 'true'
    /// - Returns: (Optional)image captured as a screenshot
    open func takeScreenshot(_ shouldSave: Bool = true) -> UIImage? {
        var screenshotImage :UIImage?
        let layer = UIApplication.shared.keyWindow!.layer
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        layer.render(in:context)
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = screenshotImage, shouldSave {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        return screenshotImage
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if #available(iOS 11.0, *) {
            webView.takeSnapshot(with: nil) { (image, error) in
                print("webView takeSnapshot")
                //Do your stuff with image
                self.imageWeb = image
            }
        }
    }
}

extension WKWebView {
    func takeScreenshot() -> UIImage? {
        let currentSize = self.frame.size
        let currentOffset = self.scrollView.contentOffset
        
        self.frame.size = self.scrollView.contentSize
        self.scrollView.setContentOffset(CGPoint.zero, animated: false)
        
        let rect = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        self.drawHierarchy(in: rect, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.frame.size = currentSize
        self.scrollView.setContentOffset(currentOffset, animated: false)
        
        return image
    }

}

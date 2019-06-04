//
//  WkWebVC.swift
//  TestApp
//
//  Created by DerekYang on 2018/9/28.
//  Modified by DerekYang on 2018/10/16.
//  Copyright © 2018年 DKY. All rights reserved.
//


import UIKit
import WebKit
import SafariServices

public let AppShellVer = "2.0.6"

public let DEF_FUNC_CLEAR_CACHE = "clearCache"
public let DEF_FUNC_OPEN_SAFARI = "openSafari"

struct ST_URL_RESULT: Codable
{
    let name: String?
    let url: String?
}

class WkWebVC: UIViewController {
    
    var urlStr = "" {
        didSet {
            if let _url = URL(string: self.urlStr) {
                let request = URLRequest(url: _url)//, cachePolicy: .reloadRevalidatingCacheData)
                DispatchQueue.main.async {
//                                    print("url="+self.urlStr)
                    self.m_webView?.load(request)
                }
            }
        }
    }
    var m_isRoot = true
    var m_flag = false
    var m_topConstraint: NSLayoutConstraint? = nil
    
    var m_webView: WKWebView? = nil
    var m_indicator: UIActivityIndicatorView? = nil
    let m_configuration = WKWebViewConfiguration()
    
    var m_closeBtn: DragButton? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupWebView()
        self.setupIndicator()
        self.setupCloseBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupIndicator()
    {
        if(nil == self.m_indicator) {
            self.m_indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            if let indicator =  self.m_indicator {
                indicator.color = UIColor.gray
                view.addSubview(indicator)
                indicator.translatesAutoresizingMaskIntoConstraints = false
                indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            }
        }
    }
    
    func clearCache()
    {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: {
                //                print("clear")
            })
            //            for record in records {
            //                if record.displayName.contains("facebook") {
            //                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
            //                        print("Deleted: " + record.displayName);
            //                    })
            //                }
            //            }
        }
    }
  
    func openSafari(url: URL)
    {
      DispatchQueue.main.async {
        if #available(iOS 10, *) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
          UIApplication.shared.openURL(url)
        }
      }
    }
  
    func openFastLink(urls: [String])
    {
        let q = DispatchQueue.global()
        for urlStr in urls {
            q.async {
                
                if let url = URL(string: urlStr) {
                    
                    let urlRequest = URLRequest(url: url)
                    
                    // set up the session
                    let config = URLSessionConfiguration.default
                    let session = URLSession(configuration: config)
                    
                    // make the request
                    let task = session.dataTask(with: urlRequest) {
                        (data, response, error) in
                        
                        if(self.m_flag) {
                            return
                        }
                        
                        // check for any errors
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        // make sure we got data
                        guard let _ = data else {
                            print("Error: did not receive data")
                            return
                        }
                        // parse the result as JSON, since that's what the API provides
                        
                        self.m_flag = true
                        DispatchQueue.main.async {
                            // 程式碼片段 ...
                            self.m_webView?.load(urlRequest)
                        }
                    }
                    task.resume()
                }
            }
        }
    }
    
    func setupCloseBtn()
    {
        self.m_closeBtn = DragButton(frame: CGRect.zero)
        
        if let btn = self.m_closeBtn {
            
            let image = UIImage(named: "close")
            btn.setImage(image, for: .normal)
            //            btn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
            btn.clickClosure = {
                [weak self]
                (btn) in
                //单击回调
                self?.clickClose(sender: btn)
            }
            self.view.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 11.0, *) {
                btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
                btn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
            } else {
                // Fallback on earlier versions
                self.edgesForExtendedLayout = []
                
                btn.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
                btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
            }
            btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }
    }
    
    @objc func clickClose(sender: UIButton)
    {
        self.dismiss(animated: true)
    }
}

extension WkWebVC: WKNavigationDelegate, WKUIDelegate
{
    func setupWebView() {
        if(nil != self.m_webView) {
            return
        }
        
        m_configuration.allowsInlineMediaPlayback = true
        m_configuration.userContentController.add(self, name: DEF_FUNC_CLEAR_CACHE)
        m_configuration.userContentController.add(self, name: DEF_FUNC_OPEN_SAFARI)
        
        // js代码片段
        //        let jsStr = "let deviceInfo = ''"
        
        // 根据JS字符串初始化WKUserScript对象
        //        let userScript = WKUserScript(source: jsStr, injectionTime:.atDocumentEnd, forMainFrameOnly: true)
        //        let userContentController = WKUserContentController()
        //        userContentController.addUserScript(userScript)
        
        // 根据生成的WKUserScript对象，初始化WKWebViewConfiguration
        //        configuration.userContentController = userContentController
        
        self.m_webView = WKWebView(frame: CGRect.zero, configuration: m_configuration)
        if let webView = self.m_webView {
          
            //      "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16A366"
            let deviceModel = UIDevice.current.model
            let systemName = UIDevice.current.systemName
            let sysVersion = UIDevice.current.systemVersion
            let modelName = UIDevice.current.modelName
            webView.customUserAgent =  "Mozilla/5.0 (\(deviceModel);\(systemName) \(sysVersion)) AppleWebKit (KHTML, like Gecko) Mobile AppShellVer:\(AppShellVer) model:\(modelName)"
          
            webView.allowsBackForwardNavigationGestures = true
            webView.navigationDelegate = self
            
            webView.uiDelegate = self
            
            self.view.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 11.0, *) {
                webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
                webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
                webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            } else {
                // Fallback on earlier versions
                self.edgesForExtendedLayout = []
                m_topConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)
                // webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                m_topConstraint?.isActive = true
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            }
        }
        
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //        print("didStartProvisionalNavigation")
        
        m_indicator?.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //        print("didCommit")
        
        m_indicator?.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        print("didFinish")
        
        m_indicator?.stopAnimating()
        
        //        webView.evaluateJavaScript("navigator.userAgent")  { (result, error) in
        //            if let _result = result as? String {
        //                print(_result)
        //            }
        //        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        //        print("didFail, error: \(error.localizedDescription)")
        
        m_indicator?.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        //        print("didFailProvisionalNavigation, error: \(error.localizedDescription)")
        
        m_indicator?.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        //        print("didReceiveServerRedirectForProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let url = navigationResponse.response.url {
            //            print("decidePolicyFor navigationResponse response url: \(url.absoluteString)")
            
            if url.absoluteString.hasSuffix("close.html") {
                m_webView?.isHidden = true
            }
        }
        
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
       
        if let url = navigationAction.request.url {
//            print(url.scheme!)
            if(url.absoluteString.prefix(4).lowercased() == "http") {
                    let vc = WkWebVC()
                    
                    vc.m_isRoot = false
                    vc.setupWebView()
                    vc.urlStr = url.absoluteString
                    //                print("open:"+vc.urlStr)
                    if let btn = vc.m_closeBtn {
                        vc.view.bringSubview(toFront: btn)
                    }
                    self.present(vc, animated: true)
//                }
            } else {
                DispatchQueue.main.async {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
        }
        return nil
    }
    
}


extension WkWebVC: WKScriptMessageHandler
{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
    {
//        print(message.name)
      if message.name == DEF_FUNC_CLEAR_CACHE {
        self.clearCache()
      } else if message.name == DEF_FUNC_OPEN_SAFARI {
        if let dic = message.body as? NSDictionary,
          let urlStr = dic["url"] as? String,
          let url = URL(string: urlStr) {
          let type = dic["type"] as? Int ?? 1
          if(type == 1) {
            self.openSafari(url: url)
          } else {
            let safariVC = SFSafariViewController(url: url)
            self.present(_: safariVC, animated: true, completion: nil)
          }
        }
      }
    }
}



extension String{
    //判斷版號
    func greaterThanNowVer() -> Bool {
        //        let result = new.compare(self, options: .numeric)
        //        return result == .orderedAscending
        if let infoDictionary = Bundle.main.infoDictionary,
            let local = infoDictionary["CFBundleShortVersionString"] as? String,
            let build = infoDictionary["CFBundleVersion"] as? String {
            let result = (local + "." + build).compare(self, options: .numeric)
            //            print(local + "." + build)
            if(local == self) {
                return false
            } else {
                return result == .orderedAscending
            }
        }
        return true
    }
    
    func greaterAndEqual(ver: String) -> Bool
    {
        if(ver == self) {
            return true
        } else {
            let result = ver.compare(self, options: .numeric)
            return result == .orderedAscending
        }
    }
    
    //handle URL
    func encodeUrl() -> String?
    {
        return self.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
    }
    func decodeUrl() -> String?
    {
        return self.removingPercentEncoding
    }
}


extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
}


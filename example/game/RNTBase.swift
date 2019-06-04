//
//  RNTBaseView.swift
//  RNProject
//
//  Created by DerekYang on 2018/11/6.
//  Copyright © 2018 Facebook. All rights reserved.
//
//

class RNTBase: UIView
{
  @objc var srcUrl = "" {
    didSet {
      if let vc = myVC {
        vc.urlStr = srcUrl
      }
    }
  }
  weak var myVC: BaseVC?
  
  var config: NSDictionary = [:] {
    didSet {
      setNeedsLayout()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  required init?(coder aDecoder: NSCoder) { fatalError("nope") }
  
  override func layoutSubviews()
  {
    super.layoutSubviews()
    
    if myVC == nil {
      embed()
    } else {
      myVC?.view.frame = bounds
    }
  }
  
  private func embed()
  {
    guard let parentVC = parentViewController else {
      return
    }
    let mystoryboard = UIStoryboard.init(name: "Main", bundle:nil)
    if let vc = mystoryboard.instantiateViewController(withIdentifier: "BaseVC") as? BaseVC {
      parentVC.addChild(vc)
      addSubview(vc.view)
      vc.urlStr = srcUrl
      vc.view.frame = bounds
      vc.didMove(toParent: parentVC)
      self.myVC = vc
    }
  }
  

}





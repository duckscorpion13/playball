//
//  RNTGame.swift
//  fngame
//
//  Created by DerekYang on 2018/3/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

class RNTMenu: UIView
{
  
  weak var myVC: UIViewController?
  
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
    let vc = mystoryboard.instantiateViewController(withIdentifier: "MenuVC")
    parentVC.addChild(vc)
    addSubview(vc.view)
    vc.view.frame = bounds
    vc.didMove(toParent: parentVC)
    self.myVC = vc
  }
}

extension UIView {
  var parentViewController: UIViewController? {
    var parentResponder: UIResponder? = self
    while parentResponder != nil {
      parentResponder = parentResponder!.next
      if let viewController = parentResponder as? UIViewController {
        return viewController
      }
    }
    return nil
  }
}




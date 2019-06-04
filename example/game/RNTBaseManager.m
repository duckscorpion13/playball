//
//  RNTBaseViewManager.m
//  RNProject
//
//  Created by DerekYang on 2018/11/6.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "example-Swift.h"
#import <React/RCTViewManager.h>

@interface RNTBaseManager: RCTViewManager
  @end

@implementation RNTBaseManager
  
  RCT_EXPORT_MODULE()
  
  
- (UIView *)view
{
    
    return  [RNTBase new];
    
}
//RCT_REMAP_VIEW_PROPERTY(testFlag, testFlag, BOOL)
  RCT_EXPORT_VIEW_PROPERTY(srcUrl, NSString)
//  RCT_CUSTOM_VIEW_PROPERTY(testFlag, BOOL, RNTBase) {
//    RNTBase *base = view;
//    base.testFlag = [RCTConvert BOOL:json];
//  }
  
@end



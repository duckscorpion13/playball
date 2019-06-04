//
//  Bridge.m
//  RNProject
//
//  Created by DerekYang on 2018/8/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <WebKit/WebKit.h>

@interface Bridge : RCTViewManager

@end


@implementation Bridge

RCT_EXPORT_MODULE(Bridge)

RCT_EXPORT_METHOD(clearCache)
{
  
  //// Date from
  NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970: 0];
  //// Execute
  dispatch_async(dispatch_get_main_queue(), ^{
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes: [WKWebsiteDataStore allWebsiteDataTypes]
                                               modifiedSince: dateFrom
                                           completionHandler: ^{
                                                                // Done
                                                                printf("clear cache\n");
                                           }
    ];
  });
 
}
@end

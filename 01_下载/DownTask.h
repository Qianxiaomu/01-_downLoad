//
//  DownTask.h
//  01_下载
//
//  Created by qingyun on 15/10/16.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownTask : NSObject
@property (nonatomic, assign)long long totalReadSecond;
@property (nonatomic, strong)NSString *speed;
@property (nonatomic, strong)NSDate *lastSecondDate;

- (NSString*)formatByteCount:(long long)size;

@end

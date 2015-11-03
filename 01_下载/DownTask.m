//
//  DownTask.m
//  01_下载
//
//  Created by qingyun on 15/10/16.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "DownTask.h"

@implementation DownTask
- (NSString*)formatByteCount:(long long)size
{
    return [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}

@end

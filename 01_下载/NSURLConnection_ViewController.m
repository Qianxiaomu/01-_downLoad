//
//  NSURLConnection_ViewController.m
//  01_下载
//
//  Created by qingyun on 15/10/13.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "NSURLConnection_ViewController.h"
#import "HeaderDefine.h"
@interface NSURLConnection_ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *downloadStatus;

@end

@implementation NSURLConnection_ViewController

-(void)saveDataToDisk:(NSData *)data
{
    NSString *savePath = [NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES)lastObject];
    savePath = [savePath stringByAppendingPathComponent:@"名扬的01_下载效果图展示"];
    [data writeToFile:savePath atomically:YES];
    NSLog(@"%@",savePath);
}



- (IBAction)downLoad:(UIButton *)sender {
    _downloadStatus.text = @"下载中...";
    //gcd 并发队列
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *url = [[NSURL alloc]initWithString:baseURL];
        
        NSMutableURLRequest *request= [NSMutableURLRequest requestWithURL:url];
        
    //方法一:
#if 0
        NSURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        //NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *)response;
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (data) {
                [self saveDataToDisk:data];
                NSLog(@"保存成功");
                _downloadStatus.text = @"下载完成";
            }else
            {
                NSLog(@"下载失败，错误信息: %@",error);
                _downloadStatus.text = @"下载失败";
            }
 
        });
#endif
        //方法二:
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (!connectionError) {
                //[self saveDataToDisk:data];
                NSLog(@"保存成功");
                _downloadStatus.text = @"下载完成";
            }else
            {
                NSLog(@"下载失败，错误信息: %@",connectionError);
                _downloadStatus.text = @"下载失败";
            }
        }];
        
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

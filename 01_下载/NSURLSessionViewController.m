//
//  NSURLSessionViewController.m
//  01_下载
//
//  Created by qingyun on 15/10/13.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "NSURLSessionViewController.h"
#import "HeaderDefine.h"
@interface NSURLSessionViewController ()
@property (weak, nonatomic) IBOutlet UILabel *downloadstusta;

@end

@implementation NSURLSessionViewController
- (IBAction)download:(UIButton *)sender {
    _downloadstusta.text = @"下载中...";
    NSURL *url = [NSURL URLWithString:baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        __block void (^updataUI)();
        if (!error) {
            NSLog(@"下载后的临时保存路径:%@",location);
            NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory , NSUserDomainMask, YES)lastObject];
            savePath = [savePath stringByAppendingPathComponent:@"名扬的01_下载效果图展示"];
            NSURL *saveUrl = [NSURL fileURLWithPath:savePath];
            NSError *saveError;
            NSFileManager *fileManger = [NSFileManager defaultManager];
            if ([fileManger fileExistsAtPath:savePath]) {
                [fileManger removeItemAtPath:savePath error:&saveError];
                if (saveError) {
                    NSLog(@"移除旧的目标文件失败－错误信息为:%@",saveError.localizedDescription);
                        updataUI = ^{
                        _downloadstusta.text = @"下载失败";
                    };
                }
            }else
            {
                NSLog(@"下载失败，错误信息为:%@",error.localizedDescription);
                _downloadstusta.text = @"下载失败";
            }
            if (!saveError) {
                    //把源文件复制到目标文件，当目标文件存在时，会抛出一个错误到 error 参数指向的对象实例
                    //方法一（path 不能有 file:// 前缀）
                    //[fileManger copyItemAtPath:[location path] toPath:savePath error:&error];
                    
                    //方法二
                    [fileManger copyItemAtURL:location toURL:saveUrl error:&saveError];
                    if (!error) {
                        NSLog(@"保存成功");
                        NSLog(@"保存的路径为:%@",savePath);
                        updataUI= ^{
                            _downloadstusta.text = @"下载完成";
                        };
                    }else {
                        NSLog(@"保存失败－错误信息为:%@",saveError.localizedDescription);
                        updataUI= ^{
                            _downloadstusta.text = @"下载失败";
                        };
                    }
                }
        }
        dispatch_async(dispatch_get_main_queue(),updataUI);
    }];
    [downloadTask resume];
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

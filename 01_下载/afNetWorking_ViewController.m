//
//  afNetWorking_ViewController.m
//  01_下载
//
//  Created by qingyun on 15/10/13.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "afNetWorking_ViewController.h"
#import "HeaderDefine.h"
#import "MBProgressHUD.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "DownTask.h"

@interface afNetWorking_ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (strong, nonatomic)MBProgressHUD *hud;
@property (strong, nonatomic)NSTimer *timer;

@property (weak, nonatomic) IBOutlet UILabel *downloadStatus;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;



- (void)showAlert:(NSString *)msg;
- (void)checkNetwork;
- (void)layoutUI;
- (NSMutableURLRequest *)downloadRequest;
- (NSURL *)saveURL:(NSURLResponse *)response deleteExistFile:(BOOL)deleteExistFile;
- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength;

@end

@implementation afNetWorking_ViewController

-(void)showAlert:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"网络情况" message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
}
-(void)checkNetwork
{
    NSURL *baseurl = [NSURL URLWithString:@"https://www.baidu.com/"];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:baseurl];
    NSOperationQueue *operationQueue = manager.operationQueue;
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [self showAlert:@"Wi-Fi 网络下"];
                [operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                [self showAlert:@"2G/3G/4G 蜂窝移动网络下"];
                [operationQueue setSuspended:YES];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                [self showAlert:@"未连接网络"];
                [operationQueue setSuspended:YES];
                break;
        }
    }];
    [manager.reachabilityManager startMonitoring];
}
-(void)layoutUI
{
    //进度效果
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    _hud.mode = MBProgressHUDModeDeterminate;
    _hud.labelText = @"下载中...";
    [_hud hide:YES];
    [self.view addSubview:_hud];
    
    //检查网络情况
    [self checkNetwork];
    
    //启动网络活动指示器；会根据网络交互情况，实时显示或隐藏网络活动指示器；他通过「通知与消息机制」来实现 [UIApplication sharedApplication].networkActivityIndicatorVisible 的控制
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

-(NSMutableURLRequest *)downloadRequest
{
    NSURL *url = [NSURL URLWithString:baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    return request;
}


- (NSURL *)saveURL:(NSURLResponse *)response deleteExistFile:(BOOL)deleteExistFile
{
    NSString *fileName = response ?[response suggestedFilename]:_downloadStatus.text;
    
    
    NSURL *saveUrl =[[NSFileManager defaultManager]URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    saveUrl = [saveUrl URLByAppendingPathComponent:fileName];
    NSString *savePath = [saveUrl path];
    if (deleteExistFile) {
        NSError *saveError;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:savePath]) {
            [fileManager removeItemAtPath:savePath error:&saveError];
            if (saveError) {
                NSLog(@"移除旧的文件失败，错误信息为:%@",saveError.localizedDescription);
            }
        }
        
    }
    return saveUrl;

}

- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hud.progress = (float)receiveDataLength/totalDataLength;
        if (receiveDataLength == totalDataLength) {
            _downloadStatus.text = receiveDataLength < 0 ? @"下载失败":@"下载完成";
            [_hud hide:YES];
        }else
        {
            _downloadStatus.text = @"下载中...";
            [_hud hide:YES];
        }
    });
}


- (IBAction)NSURLVCDownLoad:(UIButton *)sender {
    NSMutableURLRequest *request = [self downloadRequest];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    NSString *savePath = [[self saveURL:nil deleteExistFile:NO]path];

    [operation setDownloadProgressBlock:^void(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateProgress:totalBytesRead totalDataLength:totalBytesExpectedToRead];
            
            
            DownTask *downTask = [DownTask new];
            //计算一秒中的速度
            downTask.totalReadSecond += bytesRead;//123
            //获取当前时间
            
            NSDate *currentDate = [NSDate date];
            downTask.lastSecondDate =currentDate;
            //当前时间和上一秒时间做对比，大于等于一秒就去计算
            //downTask.lastSecondDate = 0;
            //[NSThread sleepForTimeInterval:1];
            NSDate *currentData1 = [NSDate date];
            
            //dispatch_async(dispatch_get_main_queue(), ^{
                if ([currentData1 timeIntervalSinceDate:downTask.lastSecondDate] >= 1) {
                    //时间差
                    double time = [currentData1 timeIntervalSinceDate:downTask.lastSecondDate];
                    //计算速度
                    long long speed = downTask.totalReadSecond/1;
                    //把速度转成KB或M
                    downTask.speed = [downTask formatByteCount:speed];
                    //维护变量，将计算过的清零
                    downTask.totalReadSecond = 0.0;
                    //维护变量，记录这次计算的时间
                    downTask.lastSecondDate = currentDate;
                };
  
            //});
            
            _progress.text = [NSString stringWithFormat:@"%lld/%lld/%@",totalBytesRead,totalBytesExpectedToRead,downTask.speed];
        });
    }];
    
    [operation setCompletionBlockWithSuccess:^void(AFHTTPRequestOperation *operation, id responseObjc) {
        NSLog(@"已经接收完所有响应数据");
        [self updateProgress:100 totalDataLength:100];
        NSData *data = (NSData *)responseObjc;
        [data writeToFile:savePath atomically:YES];
        
    } failure:^void(AFHTTPRequestOperation * operation, NSError * error) {
        [self updateProgress:-1 totalDataLength:-1];
        NSLog(@"下载失败，错误信息为:%@",error.localizedDescription);
    }];
    [operation start];
    
    
    
}
- (IBAction)NSURLSessionDownLoad:(UIButton *)sender {
    
    NSMutableURLRequest *request = [self downloadRequest];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 60.0;
    sessionConfiguration.allowsCellularAccess = YES;
    sessionConfiguration.HTTPMaximumConnectionsPerHost =4;
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:sessionConfiguration];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^ NSURL * (NSURL * targetPath, NSURLResponse * response) {
        NSLog(@"下载后的临时保存路径:%@", targetPath);
        return [self saveURL:response deleteExistFile:YES];
    } completionHandler:^void(NSURLResponse *response, NSURL * filePath, NSError *error) {
        if (!error) {
            NSLog(@"下载后的保存路径:%@", filePath); //为上面代码块返回的路径
            
            [self updateProgress:100 totalDataLength:100];
        } else {
            NSLog(@"下载失败，错误信息:%@", error.localizedDescription);
            
            [self updateProgress:-1 totalDataLength:-1];
        }
        
        [_hud hide:YES];
    }];
    [manager setDownloadTaskDidWriteDataBlock:^void(NSURLSession * session, NSURLSessionDownloadTask * task,  int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateProgress:totalBytesWritten totalDataLength:totalBytesExpectedToWrite];
            _progress.text = [NSString stringWithFormat:@"%lld/%lld",totalBytesWritten,totalBytesExpectedToWrite];
        });
        
    }];
    [manager setDownloadTaskDidFinishDownloadingBlock:^ NSURL *(NSURLSession * session, NSURLSessionDownloadTask * task, NSURL * savePath) {
        NSLog(@"已经接收完所有响应数据，下载后的临时保存路径:%@", savePath);
        return [self saveURL:nil deleteExistFile:YES];
        
    }];
    [task resume];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutUI];
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

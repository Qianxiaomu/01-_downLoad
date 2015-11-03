//
//  NSURLSessionDelegate_ViewController.m
//  01_下载
//
//  Created by qingyun on 15/10/13.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "NSURLSessionDelegate_ViewController.h"
#import "HeaderDefine.h"
//#import "AFNetworkActivityIndicatorManager.h"
@interface NSURLSessionDelegate_ViewController ()<NSURLSessionDownloadDelegate>
@property (weak, nonatomic) IBOutlet UILabel *downloadStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (weak, nonatomic) IBOutlet UILabel *progressLab;

- (NSURLSession *)defaultSession;
- (NSURLSession *)backgroundSession;
- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength;
@end

@implementation NSURLSessionDelegate_ViewController

-(NSURLSession *)defaultSession
{
    /*
     NSURLSession 支持进程三种会话：
     1、defaultSessionConfiguration：进程内会话（默认会话），用硬盘来缓存数据。
     2、ephemeralSessionConfiguration：临时的进程内会话（内存），不会将 cookie、缓存储存到本地，只会放到内存中，当应用程序退出后数据也会消失。
     3、backgroundSessionConfiguration：后台会话，相比默认会话，该会话会在后台开启一个线程进行网络数据处理。
     */
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //请求超时时间；默认为60秒
    sessionConfiguration.timeoutIntervalForRequest = 60.0;
    //是否允许蜂窝网络访问（2G/3G/4G）
    sessionConfiguration.allowsCellularAccess = YES;
    //限制每次最多连接数；在 iOS 中默认值为4
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 4;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    return session;
}

-(NSURLSession *)backgroundSession
{
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"k.NSURLSessionDelegate_ViewController"];
        //请求超时时间；默认为60秒
        sessionConfiguration.timeoutIntervalForRequest = 60.0;
        //是否允许蜂窝网络访问（2G/3G/4G）
        sessionConfiguration.allowsCellularAccess = YES;
        //限制每次最多连接数；在 iOS 中默认值为4
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 4;
        //是否自动选择最佳网络访问，仅对后台会话有效
        sessionConfiguration.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];

    });
    return session;
}

-(void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength
{
    //使用主队列异步方式（主线程）执行更新 UI 操作
    dispatch_async(dispatch_get_main_queue(), ^{
        if (receiveDataLength == totalDataLength) {
            _downloadStatus.text = @"下载完成";
            _activityIndicator.hidden = YES;
        }else
        {
            _downloadStatus.text = @"下载中...";
            _activityIndicator.hidden = NO;
            [_activityIndicator startAnimating];
            _progressView.progress = (float)receiveDataLength/totalDataLength;
        }
    });
}
- (IBAction)download:(id)sender {
    NSURL *url = [NSURL URLWithString:baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession *session = [self defaultSession];
    _downloadTask = [session downloadTaskWithRequest:request];
    [_downloadTask resume];
    /*
     会话任务状态
     typedef NS_ENUM(NSInteger, NSURLSessionTaskState) {
     NSURLSessionTaskStateRunning = 0, //正在执行
     NSURLSessionTaskStateSuspended = 1, //已挂起
     NSURLSessionTaskStateCanceling = 2, //正在取消
     NSURLSessionTaskStateCompleted = 3, //已完成
     } NS_ENUM_AVAILABLE(NSURLSESSION_AVAILABLE, 7_0);
     */
    
}
- (IBAction)cancle:(UIButton *)sender {
    [_downloadTask cancel];
}
- (IBAction)resume:(UIButton *)sender {
    [_downloadTask suspend];
}
- (IBAction)reset:(UIButton *)sender {
    [_downloadTask resume];
}

#pragma mark -NSURLSessionDownloadDelegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"已经接受到响应数据%lld字节，总数据长度为%lld字节...",totalBytesWritten, totalBytesExpectedToWrite);
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressLab.text = [NSString stringWithFormat:@"%lldB/%lldB",totalBytesWritten,totalBytesExpectedToWrite];
        [self updateProgress:totalBytesWritten totalDataLength:totalBytesExpectedToWrite];

    });
    
    
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    //下载文件会临时保存，正常流程下系统最终会自动清除此临时文件；保存路径目录根据会话类型而有所不同：
    //「进程内会话（默认会话）」和「临时的进程内会话（内存）」，路径目录为：/tmp，可以通过 NSTemporaryDirectory() 方法获取
    //「后台会话」，路径目录为：/Library/Caches/com.apple.nsurlsessiond/Downloads/com.kenmu.KMDownloadFile
    NSLog(@"已经接收完所有响应数据，下载后的临时保存路径是:%@",location);
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.progress = 1.0;
    });
    __block void (^updataUI)();
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,  NSUserDomainMask, YES)lastObject];
    savePath = [savePath stringByAppendingPathComponent:@"名扬的01_下载效果图展示"];
    NSURL *saveUrl = [NSURL fileURLWithPath:savePath];
    NSError *saveError;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:savePath]) {
        [fileManager removeItemAtPath:savePath error:&saveError];
        if (saveError) {
            NSLog(@"移除旧的目标文件失败，错误信息:%@",saveError.localizedDescription);
            updataUI = ^{
                _downloadStatus.text = @"下载失败";
            };
        }
        
    }
    if (!saveError) {
        [fileManager copyItemAtURL:location toURL:saveUrl error:&saveError];
        if (!saveError) {
            NSLog(@"保存成功");
            updataUI = ^{
                _downloadStatus.text=@"下载完成";
            };
        }else
        {
            NSLog(@"保存失败，错误信息为:%@",saveError.localizedDescription);
            updataUI = ^{
                _downloadStatus.text = @"下载失败";
            };
        }
    }
    dispatch_async(dispatch_get_main_queue(), updataUI);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"无论下载成功还是失败，最终都会执行一次");
    if (error) {
        NSString *str = error.localizedDescription;
        NSLog(@"下载失败，错误信息:%@",str);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _downloadStatus.text = [str isEqualToString:@"cancelled"] ? @"下载已取消":@"下载失败";
            _activityIndicator.hidden = YES;
            _progressView.progress = 0.0;
        });
    }
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

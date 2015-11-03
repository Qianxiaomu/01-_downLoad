//
//  NSURLConnectionDelegate_ViewController.m
//  01_下载
//
//  Created by qingyun on 15/10/13.
//  Copyright (c) 2015年 lmy. All rights reserved.
//

#import "NSURLConnectionDelegate_ViewController.h"
#import "HeaderDefine.h"
@interface NSURLConnectionDelegate_ViewController ()<NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *downloadStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLab;
@property (strong, nonatomic)NSTimer *timer;
@property (strong, nonatomic) NSMutableData *receivedData;

@property (assign, nonatomic) NSInteger totalDataLength;

@end

@implementation NSURLConnectionDelegate_ViewController
// 判断本地是否有缓存
-(BOOL)isExistCacheInMemory:(NSURLRequest *)request
{
    BOOL isExistCache = NO;
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache setMemoryCapacity:1024 * 1024];
    NSCachedURLResponse *response = [cache cachedResponseForRequest:request];
    if (response != nil ) {
        NSLog(@"内存中存在对应请求的响应缓存");
        isExistCache = YES;
    }
    return isExistCache;
}
-(void)loadUI
{
    //刷新ui部分
    NSInteger receiveDataLength = _receivedData.length;
    if (receiveDataLength == _totalDataLength) {
        _downloadStatus.text = @"下载完成";
        _activityIndicator.hidden = YES;
    }else{
        _downloadStatus.text = @"下载中...";
        _activityIndicator.hidden = NO;
        [_activityIndicator startAnimating] ;
        _progressView.progress = (float)receiveDataLength/_totalDataLength;
        
    }

}
- (IBAction)download:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:baseURL];
    /*
    cachePolicy:缓存策略
    1、NSURLRequestUseProtocolCachePolicy 协议缓存，根据 response 中的 Cache-Control 字段判断缓存是否有效，如果缓存有效则使用缓存数据否则重新从服务器请求
    2、NSURLRequestReloadIgnoringLocalCacheData 不使用缓存，直接请求新数据
    3、NSURLRequestReloadIgnoringCacheData 等同于 NSURLRequestReloadIgnoringLocalCacheData
    4、NSURLRequestReturnCacheDataElseLoad 直接使用缓存数据不管是否有效，没有缓存则重新请求
    5、NSURLRequestReturnCacheDataDontLoad 直接使用缓存数据不管是否有效，没有缓存数据则失败
    
   timeoutInterval:超时时间设置（默认60s
     */
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    if ([self isExistCacheInMemory:request]) {
        request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    [connection start];
    }
#pragma mark -NSURLConnectionDataDelegate
//即将发送请求
-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    NSLog(@"即将发送请求");
    return request;
}
//已经接受到响应  并且只执行一次
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"已经接受到响应");
    _receivedData = [NSMutableData new];
    _progressView.progress = 0.0;
    //通过响应头中的 Content-Length 获取到整个响应的总长度
    /*
     {
     "Accept-Ranges" = bytes;
     "Cache-Control" = "max-age=7776000";
     "Content-Length" = 592441;
     "Content-Type" = "application/x-zip-compressed";
     Date = "Wed, 02 Sep 2015 13:17:01 GMT";
     Etag = "\"d8f617371f9cd01:0\"";
     "Last-Modified" = "Mon, 01 Jun 2015 03:58:27 GMT";
     Server = "Microsoft-IIS/7.5";
     "X-Powered-By" = "ASP.NET";
     }
     */
    NSDictionary *headFiledDic = [(NSHTTPURLResponse *)response allHeaderFields];
    _totalDataLength = [[headFiledDic objectForKey:@"Content-Length"]integerValue];
    
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"已经接收到响应数据，数据长度为%lu字节...",(unsigned long)[data length]);
//    _timer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(connection:didReceiveData:) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    [_receivedData appendData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _progressLab.text = [NSString stringWithFormat:@"%luB/%luB/%lub/s",(unsigned long)[_receivedData length],(unsigned long)_totalDataLength,(unsigned long)data.length];
        [self loadUI];
    });
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"已经接收完所有响应数据");
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.progress = 1.0;
    });
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory , NSUserDomainMask, YES)lastObject];
    savePath = [savePath stringByAppendingPathComponent:@"名扬的01_下载效果图展示"];
    [_receivedData writeToFile:savePath atomically:YES];
}
 //如果连接超时或者连接地址错误可能就会报错
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"连接错误，错误信息为:%@",error.localizedDescription);
    _downloadStatus.text = @"连接错误";
    
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

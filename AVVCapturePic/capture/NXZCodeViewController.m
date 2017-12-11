//
//  NXZCodeViewController.m
//  AVVCapturePic
//
//  Created by 牛新怀 on 2017/12/11.
//  Copyright © 2017年 牛新怀. All rights reserved.
//
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define OffWidth [UIScreen mainScreen].bounds.size.width / 375
#define OffHeight [UIScreen mainScreen].bounds.size.height / 667
#define LIGHTBUTTONTAG      100

#import "NXZCodeViewController.h"
#import "QRView.h"
#import "Masonry.h"
#import "UIColor+HexColor.h"
@interface NXZCodeViewController ()<UIAlertViewDelegate>
{
    QRView *_qrRectView;//自定义的扫描视图
    UIButton *_lightingBtn;//照明按钮
    BOOL captureIs_Select;
}

@property (nonatomic, strong) UILabel * topDetailLabel;
@property (nonatomic, strong) UILabel * detailLabel;
@end

@implementation NXZCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"扫一扫";
}


-(void)viewWillAppear:(BOOL)animated{
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        //第一次用户接受
                    }else{
                        //用户拒绝
                        [self ocrOnFail:@"用户拒绝授权，无法扫描"];
                        
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                });
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            
            break;
        }
        default:
            break;
    }
    NSString * mediaType = AVMediaTypeVideo;// 媒体权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];// 读取设备权限
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {// 用户明确地拒绝授权，或者相机设备无法访问
        
        self.noneCameraPermissionsBlock();
        
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    if (!_captureSession.running)
    {
        [self startReading];
        
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [self stopReading];
    [_qrRectView stopScan];
}


-(void)delayMinTime{
    [self.navigationController popViewControllerAnimated:YES];
}
- (BOOL)startReading {
    NSError *error;
    //硬件设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //输入源
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        return NO;
    }
    
    //会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    //将输入源添加到会话里
    [_captureSession addInput:input];
    
    //输出源-元数据的output
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //将输出添加到会话中
    [_captureSession addOutput:captureMetadataOutput];
    
    //创建队列
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    //给output设置代理,并添加队列
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    captureMetadataOutput.rectOfInterest = CGRectMake(((SCREEN_HEIGHT-64) / 2 - 220 / 2 -40)/SCREEN_HEIGHT, (SCREEN_WIDTH / 2 - 220 / 2)/SCREEN_WIDTH, 220/SCREEN_HEIGHT, 220/SCREEN_WIDTH);
    captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeInterleaved2of5Code,AVMetadataObjectTypeUPCECode];
    
    //视频预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
    [self configuredZBarReaderMaskView];
    [_qrRectView startScan];
    
    //开始运行会话
    [_captureSession startRunning];
    
    return YES;
}
/**
 *自定义扫描二维码视图样式
 *@param 初始化扫描二维码视图的子控件
 */
- (void)configuredZBarReaderMaskView{
    //扫描的矩形方框视图
    _qrRectView = [[QRView alloc] init];
    _qrRectView.transparentArea = CGSizeMake(220, 220);
    _qrRectView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.7];
    [self.view addSubview:_qrRectView];
    [_qrRectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).with.offset(0);
        make.left.equalTo(self.view).with.offset(0);
        make.right.equalTo(self.view).with.offset(0);
        make.bottom.equalTo(self.view).with.offset(0);
    }];
    
    self.topDetailLabel.hidden = NO;
    self.topDetailLabel.text = @"请将二维码/条形码放入框中即可自动扫描";
    self.topDetailLabel.center = CGPointMake(SCREEN_WIDTH/2, 100*OffHeight);
    self.topDetailLabel.bounds = CGRectMake(0, 0, SCREEN_WIDTH, 10*OffHeight);
    [_qrRectView addSubview:self.topDetailLabel];
    //照明按钮
    _lightingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_lightingBtn setTitle:@"打开照明" forState:UIControlStateNormal];
    [_lightingBtn setImage:[UIImage imageNamed:@"CJKTLightingImage"] forState:UIControlStateNormal];
    [_lightingBtn.titleLabel setFont:[UIFont systemFontOfSize:10]];
    
    
    [_lightingBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, -20, 0)];
    [_lightingBtn setTitleEdgeInsets:UIEdgeInsetsMake(93, -50, 0, 0)];
    [_lightingBtn setTitleColor:[UIColor uiColorFromString:@"#c2c2c2"] forState:UIControlStateNormal];
    [_lightingBtn setBackgroundColor:[UIColor clearColor]];
    _lightingBtn.tag = LIGHTBUTTONTAG;
    captureIs_Select = NO;
    [_lightingBtn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_qrRectView addSubview:_lightingBtn];
    [_lightingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_qrRectView).with.offset(-100*OffHeight);
        make.centerX.equalTo(_qrRectView);
        make.size.mas_equalTo(CGSizeMake(50, 70));
    }];
    
}
- (void)buttonClicked:(UIButton *)sender{
    captureIs_Select =!captureIs_Select;
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (captureIs_Select) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                // torchIsOn = YES;
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                // torchIsOn = NO;
            }
            [device unlockForConfiguration];
        }
    }
    
    
}

-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    [_captureSession stopRunning];
    [_qrRectView stopScan];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@/n%@",metadataObjects,connection);
        if (metadataObjects != nil && [metadataObjects count] > 0)
        {
            
            AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
            NSLog(@"%@",metadataObj.stringValue);
            NSString *msgStr=metadataObj.stringValue;
            //@"http://qr.bookln.cn/qr.html?crcode=110000000F00000000000000B3ZX1CEC"
            [self ocrOnFail:msgStr];
            
            
        }else{
            [self ocrOnFail:@"扫描失败"];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        
    });
    
}
- (void)ocrOnFail:(NSString *)error {
    NSLog(@"%@", error);
    NSString *msg = [NSString stringWithFormat:@"%@", error];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"识别信息" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [_captureSession startRunning];
            [_qrRectView startScan];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    [_captureSession stopRunning];
}

-(UILabel *)topDetailLabel{
    if (!_topDetailLabel) {
        _topDetailLabel = [[UILabel alloc]init];
        _topDetailLabel.font = [UIFont systemFontOfSize:10*OffHeight];
        _topDetailLabel.textColor = [UIColor uiColorFromString:@"#c2c2c2"];
        _topDetailLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _topDetailLabel;
}

@end

//
//  NXZCodeViewController.h
//  AVVCapturePic
//
//  Created by 牛新怀 on 2017/12/11.
//  Copyright © 2017年 牛新怀. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^CKUniversityBlock)(NSString * contents);
typedef void(^CKNoPermissionsBlock)();

@interface NXZCodeViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate>
{
    //会话
    AVCaptureSession *_captureSession;
    //摄像头预览
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
}

@property (nonatomic,assign)BOOL qrcodeFlag ;
@property (nonatomic,copy) CKUniversityBlock wenhuiUniversityConfirmBlock;
@property (nonatomic,copy) CKNoPermissionsBlock noneCameraPermissionsBlock;

@end

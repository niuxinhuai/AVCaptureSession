//
//  QRView.h
//  AVVCapturePic
//
//  Created by 牛新怀 on 2017/12/11.
//  Copyright © 2017年 牛新怀. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRView : UIView

/**
 *  透明的区域
 */
@property (nonatomic, assign) CGSize transparentArea;

- (void)startScan;
- (void)stopScan;

@end

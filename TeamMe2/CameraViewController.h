//
//  FirstViewController.h
//  TeamMe2
//
//  Created by Ofer Livny on 4/30/15.
//  Copyright (c) 2015 Ofer Livny. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreMotion;

#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>

@interface CameraViewController : UIViewController {
    CFURLRef        soundFileURLRef;
    SystemSoundID   soundFileObject;

    __weak IBOutlet UIButton *TagButton;
    __weak IBOutlet UILabel *LookUpLabel;
}


@property (nonatomic) AVCaptureVideoPreviewLayer *_previewLayer;
@property (nonatomic) AVCaptureSession *_captureSession;

@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic, strong) IBOutlet UILabel *xAxis;
@property (nonatomic, strong) IBOutlet UILabel *yAxis;
@property (nonatomic, strong) IBOutlet UILabel *zAxis;

- (IBAction)TagPressed:(id)sender;



@end


// test



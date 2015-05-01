//
//  FirstViewController.h
//  TeamMe2
//
//  Created by Ofer Livny on 4/30/15.
//  Copyright (c) 2015 Ofer Livny. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>


// OpenCV addition: http://docs.opencv.org/doc/tutorials/ios/hello/hello.html
//#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>
//#endif

using namespace cv;


@interface CameraViewController : UIViewController <CvVideoCameraDelegate> {
    UIButton *TagButton2;
    UILabel *LookUpLabel2;
    __weak IBOutlet UIView *CameraView;
    __weak IBOutlet UILabel *PerfLabel;
    
    CvVideoCamera* videoCamera;
}


@property (nonatomic) AVCaptureVideoPreviewLayer *_previewLayer;
@property (nonatomic) AVCaptureSession *_captureSession;

@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic, strong) IBOutlet UILabel *xAxis;
@property (nonatomic, strong) IBOutlet UILabel *yAxis;
@property (nonatomic, strong) IBOutlet UILabel *zAxis;

@property (nonatomic, retain) CvVideoCamera* videoCamera;


- (IBAction)TagPressed:(id)sender;



@end


// test



//
//  FirstViewController.m
//  TeamMe2
//
//  Created by Ofer Livny on 4/30/15.
//  Copyright (c) 2015 Ofer Livny. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

@synthesize videoCamera;

#define kUseCamera YES
#define kUseAccelerometer YES
#define kAnimate NO
#define kPlaySounds YES
#define kUseOpenCV YES

#define kAccelerometerUpdateInterval 0.1

#define kLookUpMaxShiftPortrate (-700)
#define kLookUpMaxShiftLandscape (-500)
#define kLookUpMinScale 1
#define kLookUpMaxScale 2

#define kTagAnimationScale 1.1
#define kTagAnimationDuration 0.5


#define SoundIDCameraInit 1004 // 1007
#define SoundIDCameraStart 1004 // 1008
#define SoundIDCameraStop 1004 // 1009

- (void) playSystemSoundWithID: (int) systemSoundID {
    AudioServicesPlaySystemSound (systemSoundID);
}

- (void) initCameraOpenCV {
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:CameraView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;

//    self.videoCamera.grayscale = NO;

}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    NSLog(@"processing image");
//    NSLog(@"Image res: %d x %d x %d , type: %d ",
//          image.size().width,
//          image.size().height,
//          image.channels(),
//          image.type());
    // Do some OpenCV stuff with the image
    NSDate *start = [NSDate date];
    

    Mat gray;
    cvtColor(image,gray,CV_BGRA2GRAY);
    Canny(gray, gray, 50, 150);
    cvtColor(gray,image,CV_GRAY2BGRA);

    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];

    NSString *newtitle = [NSString stringWithFormat:@"Tag! (%04.0fms)",executionTime*1000.0];
    // This must happen on main thread.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [TagButton2 setTitle:newtitle forState: UIControlStateNormal];
    });

//    NSLog(@"Execution Time: %f", executionTime);

}
#endif

- (void) initCamera {
    NSLog(@"Initializing Camera");
    if (kUseOpenCV) {
        [self initCameraOpenCV];
    }
    //-- Setup Capture Session.
    self._captureSession = [[AVCaptureSession alloc] init];
    
    //-- Creata a video device and input from that Device.  Add the input to the capture session.
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(videoDevice == nil)
        assert(0);
    
    //-- Add the device to the session.
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                                                        error:&error];
    if(error)
        assert(0);
    
    [self._captureSession addInput:input];
    
    //-- Configure the preview layer
    self._previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self._captureSession];
    self._previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self updatePreviewLayer];
    
    //-- Add the layer to the view that should display the camera input
    [CameraView.layer addSublayer:self._previewLayer];
    [self playSystemSoundWithID:SoundIDCameraInit];
    
}

- (void) updatePreviewLayer {
    [self._previewLayer setFrame:CGRectMake(0, 0,
                                            self.view.frame.size.width,
                                            self.view.frame.size.height)];
    

}
- (void) startCamera {
    //-- Start the camera
    NSLog(@"Starting camera");
    if (kUseCamera) {
        if (kUseOpenCV) [self.videoCamera start];
        else [self._captureSession startRunning];
    }
    if (kPlaySounds) [self playSystemSoundWithID:SoundIDCameraStart];
    [self.view bringSubviewToFront:PerfLabel];
    [self.view bringSubviewToFront:TagButton2];
    [self.view bringSubviewToFront:LookUpLabel2];

}

- (void) stopCamera {
    //-- Stop the camera
    NSLog(@"Stopping camera");
    if (kUseCamera) {
        if (kUseOpenCV) [self.videoCamera stop];
        else [self._captureSession stopRunning];
    }
    if (kPlaySounds) [self playSystemSoundWithID:SoundIDCameraStop];

}




-(void) scaleButtonWithScale: (CGFloat) scale withDuration: (CGFloat) duration withSelector: (SEL) selector {
    
    CALayer *layer;
    layer = TagButton2.layer;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:selector];
    transform = CGAffineTransformScale(transform, 1, scale);
    [layer setAffineTransform: transform];
    [UIView commitAnimations];
    NSAssert(kAnimate,@"...");
}
-(void)scaleButtonUp{
    [self scaleButtonWithScale:kTagAnimationScale withDuration: kTagAnimationDuration withSelector: @selector(scaleButtonDown)];
}

-(void)scaleButtonDown{
        [self scaleButtonWithScale:1.0/kTagAnimationScale withDuration: kTagAnimationDuration withSelector: @selector(scaleButtonUp)];
    
}



- (void) initAnimations {
    if (kAnimate) [self scaleButtonUp];

}

- (CMAcceleration) smooth: (CMAcceleration) rotate {
    static CMAcceleration rotate0 = {0,0,0};
    const NSTimeInterval dt = kAccelerometerUpdateInterval;
    const double RC = 0.2;
    const double alpha = dt / (RC + dt);
    
    rotate0.x = alpha * rotate0.x + ( 1.0 - alpha ) * rotate.x;
    rotate0.y = alpha * rotate0.y + ( 1.0 - alpha ) * rotate.y;
    rotate0.z = alpha * rotate0.z + ( 1.0 - alpha ) * rotate.z;
    
    return rotate0;

}
- (void) animateLookupWithAcceleration: (CGFloat) y {
    
    CGFloat yPixelOffset = [self getRelevantShift] * fabs(y);
    CGFloat scale = kLookUpMinScale + ( 1 - fabs(y) ) * kLookUpMaxScale;
//    LookUpLabel.text = [NSString stringWithFormat:@"Look up!", yPixelOffset];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, yPixelOffset);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAccelerometerUpdateInterval/2.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    transform = CGAffineTransformScale(transform, scale, scale);
    [LookUpLabel2 setTransform: transform];
    [UIView commitAnimations];

}

- (void) initMotionManager {
    if (!kUseAccelerometer) return;
    NSLog(@"initializing Accelerometer");
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = kAccelerometerUpdateInterval;
    if ([self.motionManager isAccelerometerAvailable])
    {
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                   withHandler: ^(CMAccelerometerData *accData, NSError *error)
         {
             CMAcceleration rotate = [self smooth:accData.acceleration];
             CGFloat y = [self getRelevantAxis: rotate];
             [self animateLookupWithAcceleration: y];
         }];
    } else
        NSLog(@"Accelerator not active");
}

- (CGFloat) getRelevantShift {
    CGFloat shift;
    static UIDeviceOrientation lastOrientation = UIDeviceOrientationUnknown;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationFaceUp) orientation = lastOrientation;
    lastOrientation = orientation;
    switch (orientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            shift = kLookUpMaxShiftLandscape;
            break;
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
            shift = kLookUpMaxShiftPortrate;
            break;
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        default:
            NSLog(@"Warning - bad orientation");
            shift = 0;
            break;
    }
    return shift;
}

- (CGFloat) getRelevantAxis: (CMAcceleration) rotate {

    CGFloat y;
    static UIDeviceOrientation lastOrientation = UIDeviceOrientationUnknown;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationFaceUp) orientation = lastOrientation;
    lastOrientation = orientation;
    
    switch (orientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            y = 1-fabs(rotate.z);
            break;
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
            y = rotate.y;
            break;
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        default:
            y = 0;
            NSLog(@"Warning - bad orientation");
            break;
    }
    return y;
}

- (void) stopMotionManager {
    if (!kUseAccelerometer) return;
    if ([self.motionManager isAccelerometerActive]) {
        NSLog(@"Stopping Accelerometer");
        [self.motionManager stopAccelerometerUpdates];
    }
}

- (void) initButtons {
    UIView *view = self.view;
    LookUpLabel2 = [[UILabel alloc] init];
    [LookUpLabel2 setTranslatesAutoresizingMaskIntoConstraints:NO];
    LookUpLabel2.text = @"Look up!";
    [LookUpLabel2 setTextColor: [UIColor blackColor]];
    [LookUpLabel2 setBackgroundColor: [UIColor whiteColor]];
    
    
    TagButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [TagButton2.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [TagButton2 setTranslatesAutoresizingMaskIntoConstraints:NO];
    [TagButton2 setTitle:@"Tag This Place" forState:UIControlStateNormal];
    [TagButton2 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [TagButton2 setEnabled:YES];

    [view addSubview:LookUpLabel2];
    [view addSubview:TagButton2];

    NSLayoutConstraint *constraint = [NSLayoutConstraint
                                      constraintWithItem:LookUpLabel2
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:view
                                      attribute:NSLayoutAttributeCenterX
                                      multiplier:1.0
                                      constant:0];

    [view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint
                  constraintWithItem:LookUpLabel2
                  attribute:NSLayoutAttributeBaseline
                  relatedBy:NSLayoutRelationLessThanOrEqual
                  toItem:view
                  attribute:NSLayoutAttributeBaseline
                  multiplier:1.0
                  constant:-200];
    
    [view addConstraint:constraint];

    constraint = [NSLayoutConstraint
                  constraintWithItem:TagButton2
                  attribute:NSLayoutAttributeBaseline
                  relatedBy:NSLayoutRelationEqual
                  toItem:view
                  attribute:NSLayoutAttributeBottom
                  multiplier:1.0
                  constant: -100];

    [view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint
                  constraintWithItem:TagButton2
                  attribute:NSLayoutAttributeCenterX
                  relatedBy:NSLayoutRelationEqual
                  toItem:view
                  attribute:NSLayoutAttributeCenterX
                  multiplier:1.0
                  constant: 0];
    
    [view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint
                  constraintWithItem:TagButton2
                  attribute:NSLayoutAttributeWidth
                  relatedBy:NSLayoutRelationEqual
                  toItem:view
                  attribute:NSLayoutAttributeWidth
                  multiplier:1.0
                  constant: 0];
    
    [view addConstraint:constraint];



}

- (void)viewDidLoad {
    NSLog(@"view Did Load");
    [super viewDidLoad];
    if (kUseCamera) [self initCamera];
    [self initButtons];
    [self initAnimations];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"view Did Rotate");
    [self updatePreviewLayer];
}


- (void) viewDidAppear:(BOOL)animated {
    NSLog(@"view Did Appear");
    [self startCamera];
    [self initMotionManager];
}

- (void) viewDidDisappear:(BOOL)animated {
    NSLog(@"view Did Disappear");
    [self stopCamera];
    [self stopMotionManager];
}
- (void)didReceiveMemoryWarning {
    NSLog(@"view Did Receive Memory Warning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)TagPressed:(id)sender {
    NSLog(@"Press!");

}
@end

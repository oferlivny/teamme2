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

#define kUseCamera YES
#define kUseAccelerometer YES
#define kAnimate YES
#define kPlaySounds YES

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

- (void) initCamera {
    NSLog(@"Initializing Camera");
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
    [self.view.layer addSublayer:self._previewLayer];
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
    if (kUseCamera) [self._captureSession startRunning];
    if (kPlaySounds) [self playSystemSoundWithID:SoundIDCameraStart];
    [self.view bringSubviewToFront:TagButton];
    [self.view bringSubviewToFront:LookUpLabel];

}

- (void) stopCamera {
    //-- Stop the camera
    NSLog(@"Stopping camera");
    if (kUseCamera) [self._captureSession stopRunning];
    if (kPlaySounds) [self playSystemSoundWithID:SoundIDCameraStop];

}




-(void) scaleButtonWithScale: (CGFloat) scale withDuration: (CGFloat) duration withSelector: (SEL) selector {
    
    CALayer *layer;
    layer = TagButton.layer;
    
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
    [UIView setAnimationDuration:kAccelerometerUpdateInterval];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    transform = CGAffineTransformScale(transform, scale, scale);
    [LookUpLabel setTransform: transform];
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
            NSAssert(0,@"Should not be here");
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
            NSAssert(0,@"Should not be here");
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


- (void)viewDidLoad {
    NSLog(@"view Did Load");
    [super viewDidLoad];
    [self initCamera];
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

//
//  RSVideoRecorderControllerViewController.m
//  RSVedioRecorder
//
//  Created by SOTSYS024 on 13/02/17.
//  Copyright © 2017 Rahul. All rights reserved.
//

#import "RSVideoRecorderController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>



@interface RSVideoRecorderController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    UIImagePickerController *videoRecorder;
    UIImagePickerControllerCameraDevice device;
}

@end

@implementation RSVideoRecorderController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated{
    if ([self isVideoRecodingAvailable]) {
        videoRecorder = [UIImagePickerController new];
        videoRecorder.sourceType = UIImagePickerControllerSourceTypeCamera;
        videoRecorder.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        videoRecorder.mediaTypes = @[(NSString*)kUTTypeMovie];
        videoRecorder.videoQuality = UIImagePickerControllerQualityTypeMedium;
        videoRecorder.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        videoRecorder.delegate = self;
        [self configeVideoRecorder];
        [self presentViewController:videoRecorder animated:true completion:nil];
    }
}

-(BOOL)isVideoRecodingAvailable {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *arr = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([arr containsObject:(NSString*)kUTTypeMovie]) {
            return true;
        }
    }
    return false;
}

-(void)configeVideoRecorder {
    videoRecorder.cameraViewTransform = CGAffineTransformIdentity;
    videoRecorder.showsCameraControls = true;
    if ([UIImagePickerController isFlashAvailableForCameraDevice:device]) {
        videoRecorder.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSURL *url = info[UIImagePickerControllerMediaURL];
    self.completion(url,true);
    [picker dismissViewControllerAnimated:true completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.completion(nil,false);
    [picker dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

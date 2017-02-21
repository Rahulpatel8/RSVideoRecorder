//
//  ViewController.m
//  RSVedioRecorder
//
//  Created by SOTSYS024 on 13/02/17.
//  Copyright © 2017 Rahul. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVKit.h>
#import "RSVideoRecorderController.h"
@interface ViewController () {
    BOOL isVideo;
}
@property NSURL *videoUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    if (!isVideo) {
        RSVideoRecorderController *video = [[RSVideoRecorderController alloc] init];
        [video setCompletion:^(NSURL* url, BOOL seccess) {
            if (seccess) {
                isVideo = true;
                self.videoUrl = url;
                [self videoWithString:url];
            }
        }];
        [self presentViewController:video animated:true completion:nil];
    }
}

-(void)detectOrientation {
    NSLog(@"Orintation changed.");
}


-(void)videoWithString:(NSURL*)url {
        //AVAsset
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:url  options:nil];
        //AVComposition
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
        //AVCompositionTrack
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        //AVAssetTrack
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, clipVideoTrack.timeRange.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    
    //Check if video is potraite or not, and set size as per video orientation.
    CGSize videoSize;
    CGAffineTransform firstTransform = clipVideoTrack.preferredTransform;
    if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)  {
        videoSize= CGSizeMake([clipVideoTrack naturalSize].height, [clipVideoTrack naturalSize].width);
    }
    if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)  {
        videoSize= CGSizeMake([clipVideoTrack naturalSize].height, [clipVideoTrack naturalSize].width);
    }
    if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)   {
        videoSize= [clipVideoTrack naturalSize];
    }
    if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0) {
        videoSize= [clipVideoTrack naturalSize];
    }
    //Text Layer
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:100];
    [subtitle1Text setFrame:CGRectMake(0, videoSize.height/2-100, videoSize.width, 200)];
    [subtitle1Text setString:@"Text goes here"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    [subtitle1Text setBackgroundColor:[[UIColor redColor] CGColor]];
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    overlayLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);//Size must be same as videoComposion.renderSize
    [overlayLayer setMasksToBounds:YES];
    //Parent Layer and Video Layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
        //AVVideoComposition
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:videoAsset];
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        //Instruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
        //Layer Instruction
    AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    [firstlayerInstruction setTransform:firstTransform atTime:kCMTimeZero];
    videoComp.renderSize = videoSize;
        //set layer instruction and instrucrion
    mainInstruction.layerInstructions = [NSArray arrayWithObject:firstlayerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
        //AVExportSession.
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.videoComposition = videoComp;
        //Set path to save
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* VideoName = [NSString stringWithFormat:@"%@/mynewwatermarkedvideo.mp4",documentsDirectory];
    NSURL *exportUrl = [NSURL fileURLWithPath:VideoName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:VideoName])
    {
        [[NSFileManager defaultManager] removeItemAtPath:VideoName error:nil];
    }
    assetExport.outputFileType = AVFileTypeMPEG4;
    assetExport.outputURL = exportUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self exportDidFinish:assetExport];
         });
     }
     ];
}

-(void)exportDidFinish:(AVAssetExportSession*)session
{
    NSURL *exportUrl = session.outputURL;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:exportUrl completionBlock:^(NSURL *assetURL, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error) {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 } else {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 }
             });
         }];
    }
}

@end

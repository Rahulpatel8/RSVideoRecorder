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
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    if (!isVideo) {
        RSVideoRecorderController *video = [[RSVideoRecorderController alloc] init];
        [video setCompletion:^(NSURL* url, BOOL seccess) {
            if (seccess) {
                isVideo = true;
                self.videoUrl = url;
                [self saveVideo];
//                [self videoWithString:url];
            }
        }];
        [self presentViewController:video animated:true completion:nil];
    }
}

-(void)detectOrientation {
    NSLog(@"Orintation changed.");
}

-(void)saveVideo {
    AVURLAsset *videoAssetURL = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    //Create a layer.
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoTrack = [[videoAssetURL tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetURL.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    
    CGAffineTransform transformToApply = videoTrack.preferredTransform;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    [layerInstruction setTransform:transformToApply atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:videoAssetURL.duration];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake( kCMTimeZero, videoAssetURL.duration);
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, 30); //select the frames per second
    videoComposition.renderScale = 1.0;
    videoComposition.renderSize = CGSizeMake(640, 640); //select you video size
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    
    exportSession.outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"videoname.MOV"]];
    exportSession.outputFileType = AVFileTypeMPEG4; //very important select you video format (AVFileTypeQuickTimeMovie, AVFileTypeMPEG4, etc...)
    exportSession.videoComposition = videoComposition;
    exportSession.shouldOptimizeForNetworkUse = NO;
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetURL.duration);
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        switch ([exportSession status]) {
                
            case AVAssetExportSessionStatusCompleted: {
                
                NSLog(@"Triming Completed");
                
                    //generate video thumbnail
                AVURLAsset *videoAssetURL = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
                AVAssetImageGenerator *genrateAsset = [[AVAssetImageGenerator alloc] initWithAsset:videoAssetURL];
                genrateAsset.appliesPreferredTrackTransform = YES;
                CMTime time = CMTimeMakeWithSeconds(0.0,600);
                NSError *error = nil;
                CMTime actualTime;
                
                CGImageRef cgImage = [genrateAsset copyCGImageAtTime:time actualTime:&actualTime error:&error];
                CGImageRelease(cgImage);
                
                break;
            }
            default: {
                break;
            }
        }
    }];
}


-(void)videoWithString:(NSURL*)url {
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:url  options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    
    CGAffineTransform firstTransform = videoAsset.preferredTransform;
    if (firstTransform.a == 0 && firstTransform.d == 0 && (firstTransform.b == 1.0 || firstTransform.b == -1.0) && (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
        firstTransform = CGAffineTransformMakeRotation(M_PI);
         [compositionVideoTrack setPreferredTransform:firstTransform];
    }
    else {
         [compositionVideoTrack setPreferredTransform:videoAsset.preferredTransform];
    }
    
    CGSize videoSize = [clipVideoTrack naturalSize];
    CALayer *parentLayer = [CALayer layer];
    
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = @"Text goes here";
    titleLayer.font = CFBridgingRetain(@"Helvetica");
    titleLayer.fontSize = 60;
    //?? titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.bounds = CGRectMake(100, 100, videoSize.width, videoSize.height); //You may need to adjust this for proper display
    [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);

    AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    AVAssetTrack *firstAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    BOOL isFirstVideoPortrait = NO;
    
    if (firstTransform.a == 0 && firstTransform.d == 0 && (firstTransform.b == 1.0 || firstTransform.b == -1.0) && (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
        isFirstVideoPortrait = YES;
        firstTransform = CGAffineTransformMakeRotation(M_PI);
    }
    
    if(isFirstVideoPortrait)
    {
        [firstlayerInstruction setTransform:firstTransform atTime:kCMTimeZero];
        videoComp.renderSize = CGSizeMake(firstAssetTrack.naturalSize.height ,firstAssetTrack.naturalSize.width);
    }
    else
    {
        [firstlayerInstruction setTransform:firstAssetTrack.preferredTransform atTime:kCMTimeZero];
        videoComp.renderSize = firstAssetTrack.naturalSize;
    }
    
//    [firstlayerInstruction setTransform:firstAssetTrack.preferredTransform atTime:kCMTimeZero];
//    videoComp.renderSize = firstAssetTrack.naturalSize;
    
    mainInstruction.layerInstructions = [NSArray arrayWithObject:firstlayerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
    assetExport.videoComposition = videoComp;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* VideoName = [NSString stringWithFormat:@"%@/mynewwatermarkedvideo.mp4",documentsDirectory];
    
    //NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:VideoName];
    NSURL *exportUrl = [NSURL fileURLWithPath:VideoName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:VideoName])
    {
        [[NSFileManager defaultManager] removeItemAtPath:VideoName error:nil];
    }
    
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = exportUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    //[strRecordedFilename setString: exportPath];
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self exportDidFinish:assetExport];
         });
     }
     ];
}

-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

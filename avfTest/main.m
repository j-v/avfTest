//
//  main.m
//  avfTest
//
//  Created by Daniel M Karlsson on 3/21/13.
//  Copyright (c) 2013 Jon Volkmar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <math.h>

@interface Myclass : NSObject
- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image size:(CGSize)size;
- (CGImageRef) blerg;
- (CGImageRef) newFrame:(int)frame size:(CGSize)size;
@end


void CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}

CGImageRef getCGImageFromData(unsigned char *$data, CGSize size) {
    // partially fixed memory running out problem with help from http://lists.apple.com/archives/quicktime-api/2009/Feb/msg00049.html
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext = CGBitmapContextCreate(
                                                           $data,
                                                           size.width,
                                                           size.height,
                                                           8, // bitsPerComponent
                                                           4*size.width, // bytesPerRow
                                                           colorSpace,
                                                           kCGImageAlphaNoneSkipLast);
        
        CFRelease(colorSpace);
        
        CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
        return cgImage;
}

@implementation Myclass
-(void) addAudioToFileAtPath:(NSString *) filePath toPath:(NSString *)outFilePath
{
    NSError * error = nil;
    
    AVMutableComposition * composition = [AVMutableComposition composition];
    
    
    AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid];
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero
                                     error:&error];
    
    CMTime audioStartTime = kCMTimeZero;
//    for (NSDictionary * audioInfo in audioInfoArray)
//    {
//        NSString * pathString = [audioInfo objectForKey:audioFilePath];
//        AVURLAsset * urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:pathString] options:nil];
//        
//        AVAssetTrack * audioAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                                    preferredTrackID: kCMPersistentTrackID_Invalid];
//        
//        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,urlAsset.duration) ofTrack:audioAssetTrack atTime:audioStartTime error:&error];
//        
//        audioStartTime = CMTimeAdd(audioStartTime, CMTimeMake((int) (([[audioInfo objectForKey:audioDuration] floatValue] * kRecordingFPS) + 0.5), kRecordingFPS));
//    }
    
    //attach audio file
    NSString * pathString = @"/Users/danielmkarlsson/dev/ffmpegTest/bin/audio.wav";
    AVURLAsset * urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:pathString] options:nil];
    
    AVAssetTrack * audioAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid];
    
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleProRes422LPCM];
    //assetExport.videoComposition = mutableVideoComposition;
    
    assetExport.outputFileType =AVFileTypeQuickTimeMovie;// @"com.apple.quicktime-movie";
    assetExport.outputURL = [NSURL fileURLWithPath:outFilePath];
    
    bool __block done = false;
    NSLog(@"Exporting audio video");
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch (assetExport.status)
         {
             case AVAssetExportSessionStatusCompleted:
                 //                export complete
                 NSLog(@"Export Complete");
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 //                export error (see exportSession.error)
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 //                export cancelled  
                 break;
         }
         done = true;
         }];

    while (!done) sleep(1);
}

- (CGImageRef) newFrame:(int)frame size:(CGSize)size
{
    int arr_size = (int)size.width*(int)size.height*4;
    unsigned char *data = (unsigned char *)malloc(arr_size*sizeof(unsigned char)); ;
//    for(int y=0;y<size.height;y++) {
//        for(int x=0;x<size.width;x++) {
//            unsigned char  val = 100;
//            int linesize = size.width * 4;
//            data[y * linesize + x*3] =   val ; //r
//            data[y * linesize + x*3+1] = val ; //g
//            data[y * linesize + x*3+2] = val ; //b
//            
//        }
//    }
    
    int base_period = 60; // frames
    int period_amp = 10;
    int period_period = 100;
    
    int base_q = 10;
    int q_amp = 600;
    //int hah = (int)abs(-35);
    
    //float frac = (float)(abs(frame % (period_period *2) - period_period))/ ((float) period_period);
    //int period = base_period - period_amp + 2 * period_amp *frac;
   // int period =  base_period - period_amp + 2*
//    period_amp * (float)(abs(frame % (period_period *2) - period_period))/ ((float) period_period);
    int period = 60;
    int q =  base_q + 2 * q_amp * (fabs(frame % (period *2) - period))/ ((float) period);
    int x_shift, y_shift, val;
    for(int y=0;y<size.height;y++) {
        for(int x=0;x<size.width;x++) {
            
            x_shift = x - size.width / 2 + frame;
            y_shift = y - size.height /2 + frame ;
            val = fabs(((x_shift * y_shift + frame) % q) * 255.0/(float)q);
            int linesize = size.width * 4;
            data[y * linesize + x*4] =   val ; //r
            data[y * linesize + x*4+1] = val ; //g
            data[y * linesize + x*4+2] = val ; //b
        }
    }
    //CGImageRef i = [self blerg:size];
    CGImageRef i = getCGImageFromData(data, size);
    free(data);
    
    return i;

}
- (CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image size: (CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    //int width = 640, height = 480;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    //CGAffineTransform frameTr
    //CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (CGImageRef) blerg: (CGSize) size
{
    //CGFloat imageScale = (CGFloat)1.0;
//    CGFloat width = (CGFloat)640.0;
//    CGFloat height = (CGFloat)480.0;
//    CGSize size = CGSizeMake(width,height);
//    
    // Create a bitmap graphics context of the given size
    //
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width , size.height , 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    
    int x = rand() % (int)size.width;
    int y = rand() % (int)size.height;
    // Draw ...
    //
    CGContextSetRGBFillColor(context, (CGFloat)0.0, (CGFloat)1.0, (CGFloat)1.0, (CGFloat)1.0 );
    CGContextFillRect(context, CGRectMake(0,0,size.width,size.height));
    CGContextSetRGBFillColor(context, (CGFloat)1.0, (CGFloat)0.0, (CGFloat)0.0, (CGFloat)1.0 );
    CGContextFillEllipseInRect(context, CGRectMake(x,y,500,500));
    // …
    
    
    // Get your image
    //
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return cgImage;
}

- (void) doit
{
//    NSError *error = nil;
    NSString *betaCompressionDirectory = @"out.mov";
    CGSize size = CGSizeMake(1920,1080);
    //NSString *betaCompressionDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    
    NSError *error = nil;
    
    unlink([betaCompressionDirectory UTF8String]);
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:betaCompressionDirectory]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   //AVVideoCodecH264, AVVideoCodecKey,
                                   AVVideoCodecAppleProRes422, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings] ;
    //CVPixelBufferRef buff = [m newPixelBufferFromCGImage: i];
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                      sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary] retain];
           NSParameterAssert(writerInput);
            NSParameterAssert([videoWriter canAddInput:writerInput]);
    if ([videoWriter canAddInput:writerInput])
        NSLog(@"I can add this input");
    else
        NSLog(@"i can't add this input");
    [videoWriter addInput:writerInput];
    if(error)
        NSLog(@"error = %@", [error localizedDescription]);

    

    
    // start a sesion
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    dispatch_queue_t    dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    int __block         frame = 0;
    bool __block        finished = false;
    
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        //unsigned char  data[(int)size.width * (int)size.height *4];
        while ([writerInput isReadyForMoreMediaData])
        {
            
            if(++frame >= 3600)
            {
                [writerInput markAsFinished];
                [videoWriter finishWriting];
                [videoWriter release];
                finished = true;
                break;
            }
            
                        //CGImageWriteToFile(i, @"test.png");
            CGImageRef i = [self newFrame:frame size:size];
            
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self newPixelBufferFromCGImage:i size:size];
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 60)])
                    NSLog(@"FAIL");
                else
                    NSLog(@"Success:%d", frame);
                CFRelease(buffer);
            }
            CGImageRelease(i);
        
//        CVPixelBufferRef buffer = (CVPixelBufferRef)[self newPixelBufferFromCGImage:i];
//        if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 20)])
//            NSLog(@"FAIL");
//        else
//            NSLog(@"Success:%d", frame);
//        finished = true;
//        CFRelease(buffer);
//        
//        // finish
//        [writerInput markAsFinished];
//        //[videoWriter endSessionAtSourceTime:…];
//        [videoWriter finishWriting];
//            break;
//            
        };
        
    }];
    while (!finished)
        sleep(1);
    
    //add audiotrack
    [self addAudioToFileAtPath:@"out.mov" toPath:@"out_audio.mov"];

}

@end


int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        NSLog(@"Hello, World!");
        
                
        
        
        // Or you can use AVAssetWriterInputPixelBufferAdaptor.
        // That lets you feed the writer input data from a CVPixelBuffer
        // that’s quite easy to create from a CGImage.
        //CGSize size = CGSizeMake(640, 480);
        //int frame = 0;
        Myclass *m = [[Myclass alloc] init];
        [m doit];
    }
    return 0;
}


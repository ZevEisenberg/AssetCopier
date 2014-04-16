//
//  ASCAppDelegate.m
//  AssetCopier
//
//  Created by Zev Eisenberg on 4/16/14.
//  Copyright (c) 2014 Zev Eisenberg. All rights reserved.
//

@import CoreServices;

#import "ASCAppDelegate.h"
#import "ASCImageView.h"
#import "NSString+ASCPathUtils.h"

NSString * const kXCAssetsImageName = @"xcassets128";

@interface ASCAppDelegate () <NSDraggingDestination>

@property (weak) IBOutlet ASCImageView *xcassetsDropZone;
@property (weak) IBOutlet ASCImageView *imageDropZone;

@property (weak) IBOutlet NSTextField *assetsTitleLabel;

@property (copy, nonatomic) NSString *xcassetsPath;

@end

@implementation ASCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.assetsTitleLabel.stringValue = @"";
    
    self.xcassetsDropZone.acceptedFileTypes = @[kASCFileTypeXCAssets];
    self.imageDropZone.acceptedFileTypes = @[kASCFileTypeImage, kASCFileTypeFolder];
    
    self.xcassetsDropZone.dragOperation = NSDragOperationMove;
    self.imageDropZone.dragOperation = NSDragOperationCopy;
    
    self.xcassetsDropZone.acceptsMultipleFiles = NO;
    self.imageDropZone.acceptsMultipleFiles = YES;
    
    self.xcassetsDropZone.completionBlock = ^(NSArray *filePaths) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.xcassetsDropZone.image = [NSImage imageNamed:kXCAssetsImageName];
            NSString *filePath = [filePaths firstObject];
            if ( filePath ) {
                self.xcassetsPath = filePath;
                NSString *fileName = [filePath lastPathComponent];
                self.assetsTitleLabel.stringValue = fileName;
            }
        });
    };
    
    self.imageDropZone.completionBlock = ^(NSArray *filePaths) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ( [fileManager fileExistsAtPath:self.xcassetsPath] ) {
            for (NSString *filePath in filePaths) {
                NSString *extension = [filePath pathExtension];
                if ( [extension isEqualToString:@""] ) {
                    [self recursivelyCopyFilesInDirectory:filePath];
                }
                else {
                    [self copyFile:filePath];
                }
            }
            
        }
    };
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#pragma mark - private method

- (void)recursivelyCopyFilesInDirectory:(NSString *)rootPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:rootPath];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:url
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
                                         {
                                             NSLog(@"[Error] %@ (%@)", error, url);
                                             return NO;
                                         }];
    
    NSMutableArray *mutableFileURLs = [NSMutableArray array];
    for (NSURL *fileURL in enumerator) {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
        
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        if ( ![isDirectory boolValue] && [filename asc_isPathToImage] ) {
            [mutableFileURLs addObject:fileURL];
        }
    }
    
    for (NSString *imagePath in mutableFileURLs) {
        [self copyFile:imagePath];
    }
}

- (void)copyFile:(NSString *)sourceFilePath
{
    NSString *fileName = [sourceFilePath lastPathComponent];
    NSString *basename = [fileName stringByDeletingPathExtension];
    
    // strip suffixes like ~iPad
    NSRange tildeRange = [basename rangeOfString:@"~" options:NSBackwardsSearch];
    if ( tildeRange.location != NSNotFound ) {
        basename = [basename substringToIndex:tildeRange.location];
    }
    
    // strip @2x suffix
    NSRange retinaRange = [basename rangeOfString:@"@2x" options:NSBackwardsSearch | NSAnchoredSearch];
    if ( retinaRange.location != NSNotFound ) {
        basename = [basename stringByReplacingCharactersInRange:retinaRange withString:@""];
    }
    
    NSString *destFolder = [self.xcassetsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.imageset", basename]];
    NSString *destFile = [destFolder stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:destFile]) {
        
        NSError *deleteError;
        if ( ![fileManager removeItemAtPath:destFile error:&deleteError] ) {
            NSLog(@"%@", deleteError);
        }
        
        NSError *copyError;
        if ( ![fileManager copyItemAtPath:sourceFilePath toPath:destFile error:&copyError] ) {
            NSLog(@"%@", copyError);
        }
    }
}

@end

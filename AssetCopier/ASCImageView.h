//
//  ASCImageView.h
//  AssetCopier
//
//  Created by Zev Eisenberg on 3/21/14.
//  Copyright (c) 2014 Zev Eisenberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

FOUNDATION_EXTERN NSString * const kASCFileTypeFolder;
FOUNDATION_EXTERN NSString * const kASCFileTypeXCAssets;
FOUNDATION_EXTERN NSString * const kASCFileTypeImage;
FOUNDATION_EXTERN NSString * const kASCFileTypeUnknown;

typedef void (^ASCDroppedFilesBlock)(NSArray *filePaths);

@interface ASCImageView : NSImageView

@property (copy, nonatomic) NSArray *acceptedFileTypes;
@property (nonatomic) NSDragOperation dragOperation;
@property (nonatomic) BOOL acceptsMultipleFiles;

@property (nonatomic, copy) ASCDroppedFilesBlock completionBlock;

@end

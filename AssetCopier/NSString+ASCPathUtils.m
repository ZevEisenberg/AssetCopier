//
//  NSString+ASCPathUtils.m
//  AssetCopier
//
//  Created by Zev Eisenberg on 3/21/14.
//  Copyright (c) 2014 Zev Eisenberg. All rights reserved.
//

#import "NSString+ASCPathUtils.h"

@implementation NSString (ASCPathUtils)

- (BOOL)asc_isPathToImage
{
    CFStringRef fileExtension = (__bridge CFStringRef)[self pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    
    BOOL isPathToImage = NO;
    if ( UTTypeConformsTo(fileUTI, kUTTypeImage) ) {
        isPathToImage = YES;
    }
    CFRelease(fileUTI);
    
    return isPathToImage;
}

@end

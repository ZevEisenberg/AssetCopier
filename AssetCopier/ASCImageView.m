//
//  ASCImageView.m
//  AssetCopier
//
//  Created by Zev Eisenberg on 3/21/14.
//  Copyright (c) 2014 Zev Eisenberg. All rights reserved.
//

#import "ASCImageView.h"
#import "NSString+ASCPathUtils.h"

NSString * const kASCFileTypeFolder = @"folder";
NSString * const kASCFileTypeXCAssets = @"xcassets";
NSString * const kASCFileTypeImage = @"image";
NSString * const kASCFileTypeUnknown = @"unknown";

NSString * const kASCFileExtensionXCAssets = @"xcassets";

static const CGFloat kHighlightBorderWidth = 5;
static const CGFloat kHighlightCornerRadius = 3;

@interface ASCImageView () <NSDraggingDestination>

@property (nonatomic) BOOL highlight;

@end

@implementation ASCImageView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if ( self ) {
        [self sharedInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit
{
    
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    NSDragOperation operation = NSDragOperationNone;

    if ( [pboard.types containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        if ( files.count == 1 || self.acceptsMultipleFiles ) {
            for (NSString *filePath in files) {
                NSString *type = [self fileTypeForPath:filePath];
                if ( [self.acceptedFileTypes containsObject:type] ) {
                    operation = self.dragOperation;
                    break;
                }
            }
        }
    }
    else {
        NSLog(@"types: %@", pboard.types);
    }
    
    if ( operation != NSDragOperationNone ) {
        self.highlight = YES;
    }
    
    return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    self.highlight = NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( self.completionBlock && [pboard.types containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *supportedFiles = [NSMutableArray array];
        for (NSString *filePath in files) {
            NSString *type = [self fileTypeForPath:filePath];
            if ( [self.acceptedFileTypes containsObject:type] ) {
                [supportedFiles addObject:filePath];
            }
        }
        self.completionBlock([supportedFiles copy]);
    }
    else {
        NSLog(@"types: %@", pboard.types);
    }
    
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    self.highlight = NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if ( self.highlight ) {
        [[[NSColor blueColor] colorWithAlphaComponent:.4] set];
        [NSBezierPath setDefaultLineWidth:kHighlightBorderWidth];
        NSRect insetBounds = NSInsetRect(self.bounds, kHighlightBorderWidth, kHighlightBorderWidth);
        [[NSBezierPath bezierPathWithRoundedRect:insetBounds xRadius:kHighlightCornerRadius yRadius:kHighlightCornerRadius] stroke];
    }
}

#pragma mark - private methods

- (NSString *)fileTypeForPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *type = kASCFileTypeUnknown;
    BOOL isDirectory;
    if ( [fileManager fileExistsAtPath:path isDirectory:&isDirectory] ) {
        if ( isDirectory ) {
            if ( [[path pathExtension] isEqualToString:kASCFileExtensionXCAssets] ) {
                type = kASCFileTypeXCAssets;
            }
            else {
                type = kASCFileTypeFolder;
            }
        }
        else if ( [path asc_isPathToImage] ) {
            type = kASCFileTypeImage;
        }
    }
    else {
        [NSException raise:NSInternalInconsistencyException format:@"That was weird. The file you just dragged in didn’t exist after all."];
    }
    
    return type;
}

#pragma mark - properties

- (void)setAcceptedFileTypes:(NSArray *)acceptedFileTypes
{
    _acceptedFileTypes = [acceptedFileTypes copy];

    NSMutableArray *registerArray = [NSMutableArray array];
    
    if ( [acceptedFileTypes containsObject:kASCFileTypeFolder] || [acceptedFileTypes containsObject:kASCFileTypeXCAssets] ) {
        [registerArray addObject:(id)kUTTypeFolder];
    }
    
    if ( [acceptedFileTypes containsObject:kASCFileTypeImage] ) {
        [registerArray addObjectsFromArray:[NSImage imagePasteboardTypes]];
    }
    
    [self registerForDraggedTypes:registerArray];
}

- (void)setHighlight:(BOOL)highlight
{
    BOOL shouldRedraw = (highlight != _highlight);
    _highlight = highlight;
    
    if ( shouldRedraw ) {
        [self setNeedsDisplay:YES];
    }
}

@end

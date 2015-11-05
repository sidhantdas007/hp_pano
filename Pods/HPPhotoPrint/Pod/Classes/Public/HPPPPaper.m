//
// Hewlett-Packard Company
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import "HPPP.h"
#import "HPPPPaper.h"
#import "HPPPPrintItem.h"
#import "NSBundle+HPPPLocalizable.h"

@implementation HPPPPaper


- (id)initWithPaperSize:(NSUInteger)paperSize paperType:(NSUInteger)paperType
{
    if (nil == _supportedPaper) {
        [HPPPPaper initializePaper];
    }
    
    self = [super init];
    
    if (self) {
        
        HPPPPaper *paper = nil;
        
        for (NSDictionary *paperInfo in _supportedPaper) {
            NSUInteger supportedSize = [[paperInfo objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue];
            NSUInteger supportedType = [[paperInfo objectForKey:kHPPPPaperTypeIdKey] unsignedIntegerValue];
            if (paperSize == supportedSize && paperType == supportedType) {
                NSDictionary *sizeInfo = [HPPPPaper sizeForId:paperSize];
                NSDictionary *typeInfo = [HPPPPaper typeForId:paperType];
                paper = self;
                _paperSize = paperSize;
                _paperType = paperType;
                _sizeTitle = [sizeInfo objectForKey:kHPPPPaperSizeTitleKey];
                _typeTitle = [typeInfo objectForKey:kHPPPPaperTypeTitleKey];
                _width = [[sizeInfo objectForKey:kHPPPPaperSizeWidthKey] floatValue];
                _height = [[sizeInfo objectForKey:kHPPPPaperSizeHeightKey] floatValue];
                _photo = NO;
                NSNumber *photo = [typeInfo objectForKey:kHPPPPaperTypePhotoKey];
                if (photo) {
                    _photo = [photo boolValue];
                }
                break;
            }
        }
        
        if (!paper) {
            NSAssert(NO, @"Unknown paper size (%lul) and type (%lul)", (unsigned long)paperSize, (unsigned long)paperType);
        }
        
        self = paper;
    }
    
    return self;
}

- (id)initWithPaperSizeTitle:(NSString *)paperSizeTitle paperTypeTitle:(NSString *)paperTypeTitle;
{
    return [self initWithPaperSize:[HPPPPaper sizeFromTitle:paperSizeTitle] paperType:[HPPPPaper typeFromTitle:paperTypeTitle]];
}

+ (NSString *)titleFromSize:(NSUInteger)sizeId
{
    NSDictionary *sizeInfo = [self sizeForId:sizeId];
    if (nil == sizeInfo) {
        NSAssert(NO, @"Unknown paper size ID: %lul", (unsigned long)sizeId);
    }
    return [sizeInfo objectForKey:kHPPPPaperSizeTitleKey];
}

+ (NSUInteger)sizeFromTitle:(NSString *)title
{
    NSDictionary *sizeInfo = [self sizeForTitle:title];
    if (nil == sizeInfo) {
        NSAssert(NO, @"Unknown paper size title: %@", title);
    }
    return [[sizeInfo objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue];
}

+ (NSString *)titleFromType:(NSUInteger)typeId
{
    NSDictionary *typeInfo = [self typeForId:typeId];
    if (nil == typeInfo) {
        NSAssert(NO, @"Unknown paper type ID: %lul", (unsigned long)typeId);
    }
    return [typeInfo objectForKey:kHPPPPaperTypeTitleKey];
}

+ (NSUInteger)typeFromTitle:(NSString *)title
{
    NSDictionary *typeInfo = [self typeForTitle:title];
    if (nil == typeInfo) {
        NSAssert(NO, @"Unknown paper type title: %@", title);
    }
    return [[typeInfo objectForKey:kHPPPPaperTypeIdKey] unsignedIntegerValue];
}

- (NSString *)paperWidthTitle
{
    return [NSNumber numberWithFloat:self.width].stringValue;
}

- (NSString *)paperHeightTitle
{
    return [NSNumber numberWithFloat:self.height].stringValue;
}

- (CGSize)printerPaperSize
{
    NSDictionary *sizeInfo = [HPPPPaper sizeForId:self.paperSize];
    NSNumber *printerWidth = [sizeInfo objectForKey:kHPPPPaperSizePrinterWidthKey];
    NSNumber *printerHeight = [sizeInfo objectForKey:kHPPPPaperSizePrinterHeightKey];
    CGFloat width = printerWidth ? [printerWidth floatValue] : self.width;
    CGFloat height = printerHeight ? [printerHeight floatValue] : self.height;
    return CGSizeMake(width * kHPPPPointsPerInch, height * kHPPPPointsPerInch);
}

#pragma mark - Supported paper initialization

NSString * const kHPPPPaperSizeIdKey = @"kHPPPPaperSizeIdKey";
NSString * const kHPPPPaperSizeTitleKey = @"kHPPPPaperSizeTitleKey";
NSString * const kHPPPPaperTypeIdKey = @"kHPPPPaperTypeIdKey";
NSString * const kHPPPPaperTypeTitleKey = @"kHPPPPaperTypeTitleKey";
NSString * const kHPPPPaperTypePhotoKey = @"kHPPPPaperTypePhotoKey";
NSString * const kHPPPPaperSizeWidthKey = @"kHPPPPaperWidthKey";
NSString * const kHPPPPaperSizeHeightKey = @"kHPPPPaperHeightKey";
NSString * const kHPPPPaperSizePrinterWidthKey = @"kHPPPPaperPrinterWidthKey";
NSString * const kHPPPPaperSizePrinterHeightKey = @"kHPPPPaperPrinterHeightKey";

static NSArray *_supportedSize = nil;
static NSArray *_supportedType = nil;
static NSArray *_supportedPaper = nil;

+ (void)initializePaper
{
    if (_supportedSize && _supportedType && _supportedPaper) {
        return;
    }
    
    _supportedSize = @[];
    _supportedType = @[];
    _supportedPaper = @[];
    
    // US Paper Sizes
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize4x5],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"4 x 5", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:4.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:5.0],
                         kHPPPPaperSizePrinterHeightKey:[NSNumber numberWithFloat:6.0]
                         }];
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize4x6],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"4 x 6", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:4.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:6.0]
                         }];
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize5x7],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"5 x 7", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:5.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:7.0]
                         }];
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSizeLetter],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"8.5 x 11", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:8.5],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:11.0]
                         }];
    
    
    // International paper sizes
    
    float const kMillimetersPerInch = 25.4;
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSizeA4],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"A4", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:210.0 / kMillimetersPerInch],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:297.0 / kMillimetersPerInch]
                         }];
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSizeA5],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"A5", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:148.0 / kMillimetersPerInch],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:210.0 / kMillimetersPerInch]
                         }];
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSizeA6],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"A6", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:105.0 / kMillimetersPerInch],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:148.0 / kMillimetersPerInch]
                         }];
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize10x13],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"10x13cm", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:4.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:5.0],
                         kHPPPPaperSizePrinterHeightKey:[NSNumber numberWithFloat:6.0]
                         }];
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize10x15],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"10x15cm", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:4.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:6.0]
                         }];
    
    [self registerSize:@{
                         kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperSize13x18],
                         kHPPPPaperSizeTitleKey:HPPPLocalizedString(@"13x18cm", @"Option for paper size"),
                         kHPPPPaperSizeWidthKey:[NSNumber numberWithFloat:5.0],
                         kHPPPPaperSizeHeightKey:[NSNumber numberWithFloat:7.0]
                         }];
    // Paper Type
    [self registerType:@{
                         kHPPPPaperTypeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperTypePlain],
                         kHPPPPaperTypeTitleKey:HPPPLocalizedString(@"Plain Paper", @"Option for paper type"),
                         kHPPPPaperTypePhotoKey:[NSNumber numberWithBool:NO]
                         }];
    [self registerType:@{
                         kHPPPPaperTypeIdKey:[NSNumber numberWithUnsignedLong:HPPPPaperTypePhoto],
                         kHPPPPaperTypeTitleKey:HPPPLocalizedString(@"Photo Paper", @"Option for paper type"),
                         kHPPPPaperTypePhotoKey:[NSNumber numberWithBool:YES]
                         }];
    
    // Associations
    [self associatePaperSize:HPPPPaperSize4x5 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSize4x6 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSize5x7 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSizeLetter withType:HPPPPaperTypePlain];
    [self associatePaperSize:HPPPPaperSizeLetter withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSizeA4 withType:HPPPPaperTypePlain];
    [self associatePaperSize:HPPPPaperSizeA4 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSizeA5 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSizeA6 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSize10x13 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSize10x15 withType:HPPPPaperTypePhoto];
    [self associatePaperSize:HPPPPaperSize13x18 withType:HPPPPaperTypePhoto];
}

+ (NSArray *)supportedSize
{
    [self initializePaper];
    return _supportedSize;
}

+ (NSArray *)supportedType
{
    [self initializePaper];
    return _supportedType;
}

+ (NSArray *)supportedPaper
{
    [self initializePaper];
    return _supportedPaper;
}

+ (BOOL)registerSize:(NSDictionary *)info
{
    [self initializePaper];
    
    NSNumber *sizeId = [info objectForKey:kHPPPPaperSizeIdKey] ;
    NSString *title = [info objectForKey:kHPPPPaperSizeTitleKey];
    NSNumber *width = [info objectForKey:kHPPPPaperSizeWidthKey];
    NSNumber *height = [info objectForKey:kHPPPPaperSizeHeightKey];
    
    if (nil == sizeId || nil == title || nil == width || nil == height) {
        HPPPLogError(@"Attempted to register size with missing info:  %@", info);
        return NO;
    }
    
    if (nil != [self sizeForId:[sizeId unsignedIntegerValue]]) {
        HPPPLogError(@"Attempted to register size ID that already exists:  %lul", [sizeId unsignedIntegerValue]);
        return NO;
    }
    
    if (nil != [self sizeForTitle:title]) {
        HPPPLogError(@"Attempted to register size title that already exists:  '%@'", title);
        return NO;
    }
    
    NSMutableArray *supportedSize = [_supportedSize mutableCopy];
    [supportedSize addObject:info];
    _supportedSize = supportedSize;
    
    return YES;
}

+ (BOOL)registerType:(NSDictionary *)info
{
    [self initializePaper];
    
    NSNumber *typeId = [info objectForKey:kHPPPPaperTypeIdKey] ;
    NSString *title = [info objectForKey:kHPPPPaperTypeTitleKey];
    
    if (nil == typeId || nil == title) {
        HPPPLogError(@"Attempted to register type with missing info:  %@", info);
        return NO;
    }
    
    if (nil != [self typeForId:[typeId unsignedIntegerValue]]) {
        HPPPLogError(@"Attempted to register type ID that already exists:  %lul", [typeId unsignedIntegerValue]);
        return NO;
    }
    
    if (nil != [self typeForTitle:title]) {
        HPPPLogError(@"Attempted to register type title that already exists:  '%@'", title);
        return NO;
    }
    
    NSMutableArray *supportedType = [_supportedType mutableCopy];
    [supportedType addObject:info];
    _supportedType = supportedType;
    
    return YES;
}

+ (BOOL)associatePaperSize:(NSUInteger)sizeId withType:(NSUInteger)typeId
{
    [self initializePaper];
    
    if (nil != [self associationForSizeId:sizeId andTypeId:typeId]) {
        HPPPLogError(@"Attempted association already exists:  size (%lul) - type (%lul)", sizeId, typeId);
        return NO;
    }
    
    if (nil == [self sizeForId:sizeId]) {
        HPPPLogError(@"Attempted to associate with nonexistant size:  %lul", sizeId);
        return NO;
    }
    
    if (nil == [self typeForId:typeId]) {
        HPPPLogError(@"Attempted to associate with nonexistant type:  %lul", typeId);
        return NO;
    }
    
    NSMutableArray *supportedPaper = [_supportedPaper mutableCopy];
    [supportedPaper addObject:@{
                                kHPPPPaperSizeIdKey:[NSNumber numberWithUnsignedLong:sizeId],
                                kHPPPPaperTypeIdKey:[NSNumber numberWithUnsignedLong:typeId]
                                }];
    _supportedPaper = supportedPaper;
    
    return YES;
}

+ (void)resetPaperList
{
    _supportedSize = nil;
    _supportedType = nil;
    _supportedPaper = nil;
    [self initializePaper];
    [HPPP sharedInstance].supportedPapers = [self availablePapers];
    [HPPP sharedInstance].defaultPaper = [[self availablePapers] firstObject];
}

#pragma mark - Supported paper helpers

+ (NSArray *)availablePapers
{
    NSMutableArray *papers = [NSMutableArray array];
    for (NSDictionary *association in self.supportedPaper) {
        NSUInteger sizeId = [[association objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue];
        NSUInteger typeId = [[association objectForKey:kHPPPPaperTypeIdKey] unsignedIntegerValue];
        HPPPPaper *paper = [[HPPPPaper alloc] initWithPaperSize:sizeId paperType:typeId];
        [papers addObject:paper];
    }
    return [self sortPapers:papers];
}

+ (HPPPPaper *)standardUSADefaultPaper
{
    return [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize4x6 paperType:HPPPPaperTypePhoto];
}

+ (NSArray *)standardUSAPapers
{
    return @[
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize4x5 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize4x6 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize5x7 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeLetter paperType:HPPPPaperTypePlain],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeLetter paperType:HPPPPaperTypePhoto]
             ];
}

+ (HPPPPaper *)standardInternationalDefaultPaper
{
    return [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize10x15 paperType:HPPPPaperTypePhoto];
}

+ (NSArray *)standardInternationalPapers
{
    return @[
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeA4 paperType:HPPPPaperTypePlain],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeA4 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeA5 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSizeA6 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize10x13 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize10x15 paperType:HPPPPaperTypePhoto],
             [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize13x18 paperType:HPPPPaperTypePhoto],
             ];
}

+ (BOOL)validPaperSize:(NSUInteger)paperSize andType:(NSUInteger)paperType
{
    BOOL valid = NO;
    for (HPPPPaper *paper in [self availablePapers]) {
        if (paper.paperSize == paperSize && paper.paperType == paperType) {
            valid = YES;
            break;
        }
    }
    return valid;
}

+ (NSDictionary *)sizeForId:(NSUInteger)sizeId
{
    NSDictionary *sizeInfo = nil;
    for (NSDictionary *info in _supportedSize) {
        NSUInteger existingId = [[info objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue];
        if (existingId == sizeId) {
            sizeInfo = info;
            break;
        }
    }
    return sizeInfo;
}

+ (NSDictionary *)sizeForTitle:(NSString *)title
{
    NSDictionary *sizeInfo = nil;
    for (NSDictionary *info in _supportedSize) {
        NSString *existingTitle = [info objectForKey:kHPPPPaperSizeTitleKey];
        if ([existingTitle isEqualToString:title]) {
            sizeInfo = info;
            break;
        }
    }
    return sizeInfo;
}

+ (NSDictionary *)typeForId:(NSUInteger)typeId
{
    NSDictionary *typeInfo = nil;
    for (NSDictionary *info in _supportedType) {
        NSUInteger existingId = [[info objectForKey:kHPPPPaperTypeIdKey] unsignedIntegerValue];
        if (existingId == typeId) {
            typeInfo = info;
            break;
        }
    }
    return typeInfo;
}

+ (NSDictionary *)typeForTitle:(NSString *)title
{
    NSDictionary *typeInfo = nil;
    for (NSDictionary *info in _supportedType) {
        NSString *existingTitle = [info objectForKey:kHPPPPaperTypeTitleKey];
        if ([existingTitle isEqualToString:title]) {
            typeInfo = info;
            break;
        }
    }
    return typeInfo;
}

+ (NSDictionary *)associationForSizeId:(NSUInteger)sizeId andTypeId:(NSUInteger)typeId
{
    NSDictionary *associationInfo = nil;
    for (NSDictionary *info in _supportedPaper) {
        NSUInteger existingSizeId = [[info objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue];
        NSUInteger existingTypeId = [[info objectForKey:kHPPPPaperTypeIdKey] unsignedIntegerValue];
        if (existingSizeId == sizeId && existingTypeId == typeId) {
            associationInfo = info;
        }
    }
    return associationInfo;
}

+ (NSArray *)sortPapers:(NSArray *)papers
{
    NSMutableArray *sortedPapers = [NSMutableArray arrayWithArray:papers];
    [sortedPapers sortUsingComparator:^NSComparisonResult(id obj1, id  obj2){
        HPPPPaper *paper1 = obj1;
        HPPPPaper *paper2 = obj2;
        if (paper1.paperSize < paper2.paperSize) {
            return NSOrderedAscending;
        } else if (paper1.paperSize > paper2.paperSize) {
            return NSOrderedDescending;
        } else {
            if (paper1.paperType < paper2.paperType) {
                return NSOrderedAscending;
            } else if (paper1.paperType > paper2.paperType) {
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
    }];
    return sortedPapers;
}

#pragma mark - Supported paper type info

+ (BOOL)supportedPaperSize:(NSUInteger)paperSize andType:(NSUInteger)paperType
{
    BOOL valid = NO;
    for (HPPPPaper *paper in [HPPP sharedInstance].supportedPapers) {
        if (paper.paperSize == paperSize && paper.paperType == paperType) {
            valid = YES;
            break;
        }
    }
    return valid;
}

- (NSArray *)supportedTypes
{
    NSMutableArray *paperTypes = [NSMutableArray array];
    for (HPPPPaper *supportedPaper in [HPPP sharedInstance].supportedPapers) {
        if (supportedPaper.paperSize == self.paperSize) {
            NSNumber *supportedType = [NSNumber numberWithUnsignedInteger:supportedPaper.paperType];
            if (![paperTypes containsObject:supportedType]) {
                [paperTypes addObject:supportedType];
            }
        }
    }
    return paperTypes;
}

- (BOOL)supportsType:(NSUInteger)paperType
{
    BOOL supported = NO;
    for (HPPPPaper *supportedPaper in [HPPP sharedInstance].supportedPapers) {
        if (supportedPaper.paperSize == self.paperSize && supportedPaper.paperType == paperType) {
            supported = YES;
            break;
        }
    }
    return supported;
}

+ (NSNumber *)defaultTypeForSize:(NSUInteger)paperSize
{
    for (HPPPPaper *paper in [HPPP sharedInstance].supportedPapers) {
        if (paperSize == paper.paperSize) {
            return [NSNumber numberWithUnsignedInteger:paper.paperType];
        }
    }
    
    for (NSDictionary *info in _supportedPaper) {
        if (paperSize == [[info objectForKey:kHPPPPaperSizeIdKey] unsignedIntegerValue]) {
            return [info objectForKey:kHPPPPaperTypeIdKey];
        }
    }
    
    return nil;
}

#pragma mark - Log description

- (NSString *)description
{
    CGSize printerSize = [self printerPaperSize];
    return [NSString stringWithFormat:@"%@, %@\nWidth %.2f Height %.2f\nPrinter Width %.2f Printer Height %.2f\nPaper Size %lul\nPaper Type %lul",
            self.sizeTitle,
            self.typeTitle,
            self.width,
            self.height,
            printerSize.width,
            printerSize.height,
            (unsigned long)self.paperSize,
            (unsigned long)self.paperType];
}

@end



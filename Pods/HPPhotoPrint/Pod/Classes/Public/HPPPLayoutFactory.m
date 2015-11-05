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
#import "HPPPLayoutFactory.h"
#import "HPPPLayoutFill.h"
#import "HPPPLayoutFit.h"
#import "HPPPLayoutStretch.h"

@implementation HPPPLayoutFactory

NSString * const kHPPPLayoutTypeKey = @"kHPPPLayoutTypeKey";
NSString * const kHPPPLayoutOrientationKey = @"kHPPPLayoutOrientationKey";
NSString * const kHPPPLayoutPositionKey = @"kHPPPLayoutPositionKey";
NSString * const kHPPPLayoutAllowRotationKey = @"kHPPPLayoutAllowRotationKey";
NSString * const kHPPPLayoutBorderInchesKey = @"kHPPPLayoutBorderInchesKey";
NSString * const kHPPPLayoutAssetPositionKey = @"kHPPPLayoutAssetPositionKey";

static NSMutableArray *factoryDelegates = nil;

+ (HPPPLayout *)layoutWithType:(NSString *)layoutType
{
    HPPPLayout *layout = [HPPPLayoutFactory layoutWithType:layoutType orientation:HPPPLayoutOrientationBestFit assetPosition:[HPPPLayout completeFillRectangle]];
    
    if( nil == layout  &&  nil != factoryDelegates) {
        for (id<HPPPLayoutFactoryDelegate> delegate in factoryDelegates) {
            if( [delegate respondsToSelector:@selector(layoutWithType:)] ) {
                layout = [delegate layoutWithType:layoutType];
                if (layout) {
                    break;
                }
            }
        }
    }
    
    return layout;
}

+ (HPPPLayout *)layoutWithType:(NSString *)layoutType
                   orientation:(HPPPLayoutOrientation)orientation
                 assetPosition:(CGRect)assetPosition
{
    HPPPLayout *layout = nil;
    
    if ([[HPPPLayoutFill layoutType] isEqualToString:layoutType] || nil == layoutType) {
        layout = [[HPPPLayoutFill alloc] initWithOrientation:orientation assetPosition:assetPosition];
    } else if ([[HPPPLayoutFit layoutType] isEqualToString:layoutType]) {
        HPPPLayoutFit *layoutFit = [[HPPPLayoutFit alloc] initWithOrientation:orientation assetPosition:assetPosition];
        layoutFit.horizontalPosition = HPPPLayoutHorizontalPositionMiddle;
        layoutFit.verticalPosition = HPPPLayoutVerticalPositionMiddle;
        layout = layoutFit;
    } else if ([[HPPPLayoutStretch layoutType] isEqualToString:layoutType]) {
        layout = [[HPPPLayoutStretch alloc] initWithOrientation:orientation assetPosition:assetPosition];
    } else {
        if( nil != factoryDelegates) {
            for (id<HPPPLayoutFactoryDelegate> delegate in factoryDelegates) {
                if( [delegate respondsToSelector:@selector(layoutWithType:orientation:assetPosition:)] ) {
                    layout = [delegate layoutWithType:layoutType
                                          orientation:orientation
                                        assetPosition:assetPosition
                                 ];
                    if (layout) {
                        break;
                    }
                }
            }
        }
    }
    
    if (nil == layout) {
        HPPPLogWarn(@"Unable to create a layout using type %@", layoutType);
    }
    
    return layout;
}

+ (HPPPLayout *)layoutWithType:(NSString *)layoutType
                   orientation:(HPPPLayoutOrientation)orientation
                 layoutOptions:(NSDictionary *)layoutOptions
{
    HPPPLayout *layout = nil;
    
    if ([[HPPPLayoutFit layoutType] isEqualToString:layoutType]) {
    
        CGRect assetPosition = [HPPPLayout completeFillRectangle];
        if (layoutOptions) {
            NSDictionary *assetPositionDictionary = [layoutOptions objectForKey:kHPPPLayoutAssetPositionKey];
            if (assetPositionDictionary) {
                CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)assetPositionDictionary, &assetPosition);
            }
        }
        
        HPPPLayoutFit *layoutFit = [[HPPPLayoutFit alloc] initWithOrientation:orientation assetPosition:assetPosition];
        
        if( nil != layoutOptions ) {
            if( [layoutOptions objectForKey:kHPPPLayoutHorizontalPositionKey] ) {
                layoutFit.horizontalPosition = [[layoutOptions objectForKey:kHPPPLayoutHorizontalPositionKey] intValue];
            }
            
            if( [layoutOptions objectForKey:kHPPPLayoutVerticalPositionKey] ) {
                layoutFit.verticalPosition = [[layoutOptions objectForKey:kHPPPLayoutVerticalPositionKey] intValue];
            }
            
            if( [layoutOptions objectForKey:kHPPPLayoutBorderInchesKey] ) {
                layoutFit.borderInches = [[layoutOptions objectForKey:kHPPPLayoutBorderInchesKey] floatValue];
            }
        }
        
        layout = layoutFit;
    } else {
        if( nil != factoryDelegates) {
            for (id<HPPPLayoutFactoryDelegate> delegate in factoryDelegates) {
                if( [delegate respondsToSelector:@selector(layoutWithType:orientation:layoutOptions:)] ) {
                    layout = [delegate layoutWithType:layoutType
                                          orientation:orientation
                                        layoutOptions:layoutOptions];
                    if (layout) {
                        break;
                    }
                }
            }
        }

        if( nil == layout ) {
            HPPPLogWarn(@"Layout options are only supported by HPPPLayoutTypeFit");
        }
    }
    
    if (nil == layout) {
        HPPPLogWarn(@"Unable to create a layout using type %@", layoutType);
    }
    
    return layout;
}

#pragma mark - NSCoding support

+ (void)encodeLayout:(HPPPLayout *)layout WithCoder:(NSCoder *)encoder
{
    NSString *type = NSStringFromClass([layout class]);

    [encoder encodeObject:type forKey:kHPPPLayoutTypeKey];
    [encoder encodeObject:[NSNumber numberWithInt:layout.orientation] forKey:kHPPPLayoutOrientationKey];
    [encoder encodeCGRect:layout.assetPosition forKey:kHPPPLayoutPositionKey];
    [encoder encodeFloat:layout.borderInches forKey:kHPPPLayoutBorderInchesKey];

    if( [HPPPLayoutFit layoutType] == type ) {
        HPPPLayoutFit *layoutFit = (HPPPLayoutFit*)layout;
        [encoder encodeObject:[NSNumber numberWithInt:layoutFit.horizontalPosition] forKey:kHPPPLayoutHorizontalPositionKey];
        [encoder encodeObject:[NSNumber numberWithInt:layoutFit.verticalPosition] forKey:kHPPPLayoutVerticalPositionKey];
    }

}

+ (id)initLayoutWithCoder:(NSCoder *)decoder
{
    HPPPLayout *layout = nil;
    NSString *layoutType;
    id rawType = [decoder containsValueForKey:kHPPPLayoutTypeKey] ? [decoder decodeObjectForKey:kHPPPLayoutTypeKey] : nil;
    
    if( nil != rawType ) {
        // backward compatibility
        if( [rawType isKindOfClass:[NSNumber class]] ) {
            int type = [rawType intValue];
            switch (type) {
                case 0:
                    layoutType = [HPPPLayoutFill layoutType];
                    break;
                
                case 1:
                case 3:
                    layoutType = [HPPPLayoutFit layoutType];
                    break;
                
                case 2:
                    layoutType = [HPPPLayoutStretch layoutType];
                    break;
                
                default:
                    HPPPLogError(@"Unrecognized layout type: %d", type);
                    layoutType = nil;
                    break;
            }
        } else if( [rawType isKindOfClass:[NSString class]] ) {
            layoutType = rawType;
        }
        
        if( layoutType ) {
            HPPPLayoutOrientation orientation = [decoder containsValueForKey:kHPPPLayoutOrientationKey] ? [[decoder decodeObjectForKey:kHPPPLayoutOrientationKey] intValue] : HPPPLayoutOrientationBestFit;
            CGRect positionRect = [decoder containsValueForKey:kHPPPLayoutPositionKey] ? [decoder decodeCGRectForKey:kHPPPLayoutPositionKey] : [HPPPLayout completeFillRectangle];
            float borderInches = [decoder containsValueForKey:kHPPPLayoutTypeKey] ? [decoder decodeFloatForKey:kHPPPLayoutBorderInchesKey] : 0.0;
            
            layout = [self layoutWithType:layoutType orientation:orientation assetPosition:positionRect];
            layout.borderInches = borderInches;
            
            if( [HPPPLayoutFit layoutType] == layoutType ) {
                HPPPLayoutFit *layoutFit = (HPPPLayoutFit *)layout;
                
                HPPPLayoutHorizontalPosition horizontalPosition = [decoder containsValueForKey:kHPPPLayoutHorizontalPositionKey] ? [[decoder decodeObjectForKey:kHPPPLayoutHorizontalPositionKey] intValue] : HPPPLayoutHorizontalPositionMiddle;
                HPPPLayoutVerticalPosition verticalPosition = [decoder containsValueForKey:kHPPPLayoutVerticalPositionKey] ? [[decoder decodeObjectForKey:kHPPPLayoutVerticalPositionKey] intValue] : HPPPLayoutVerticalPositionMiddle;
                
                layoutFit.horizontalPosition = horizontalPosition;
                layoutFit.verticalPosition = verticalPosition;
            }
        } else {
            HPPPLogError(@"Unable to decode layout for type %@", rawType);
        }
    }
    
    return layout;
}

+ (void)addDelegate:(id<HPPPLayoutFactoryDelegate>)delegate
{
    if( nil == factoryDelegates ) {
        factoryDelegates = [[NSMutableArray alloc] initWithObjects:delegate, nil];
    } else {
        [factoryDelegates addObject:delegate];
    }
}

+ (void)removeDelegate:(id<HPPPLayoutFactoryDelegate>)delegate
{
    if( nil != factoryDelegates ) {
        [factoryDelegates removeObject:delegate];
    }
}

@end

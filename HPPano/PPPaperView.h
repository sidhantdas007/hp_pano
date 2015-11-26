//
//  PPPaperView.h
//  HPPano
//
//  Created by P&I Lab on 11/26/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPPaperView : UIView

@property (strong, nonatomic) NSArray<UIImage *> *sourceImages;
@property (strong, nonatomic, readonly) UIImage *combinedImage;

- (void)drawPerforations:(NSUInteger)count stripPercent:(CGFloat)stripPercent;

extern NSUInteger const kPPNumberOfStrips;
extern CGFloat const kPPPaperWidth;
extern CGFloat const kPPPaperHeight;
extern CGFloat const kPPStripWidth;
extern CGFloat const kPPStripHeight;
extern CGFloat const kPPDotsPerInch;

@end

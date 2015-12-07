//
//  PPPaperView.m
//  HPPano
//
//  Created by P&I Lab on 11/26/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPaperView.h"

@interface PPPaperView()

@property (strong, nonatomic) CAShapeLayer *perforationsLayer;
@property (strong, nonatomic) NSArray<UIImage *> *scaledImages;
@property (assign, nonatomic) BOOL adjustLayout;

@end

@implementation PPPaperView

NSUInteger const kPPNumberOfStrips = 3;
CGFloat const kPPPaperWidth = 7.0; // inches
CGFloat const kPPPaperHeight = 5.0; // inches
CGFloat const kPPStripWidth = 7.0; // inches
CGFloat const kPPStripHeight = 1.375; // inches
CGFloat const kPPDotsPerInch = 300.0;

NSString * const kPPLayoutOffsetXKey = @"layout_offset_x";
NSString * const kPPLayoutOffsetYKey = @"layout_offset_y";
NSString * const kPPLayoutScaleFactor = @"layout_scale_factor";
CGFloat const kPPDefaultLayoutOffsetX = 0.0;
CGFloat const kPPDefaultLayoutOffsetY = 0.0;
CGFloat const kPPDefaultLayoutScaleFactor = 1.0;

- (id)initWithLayoutAdjustment:(BOOL)adjust
{
    self = [super init];
    
    if (self) {
        self.adjustLayout = adjust;
    }
        
    return self;
}

- (CGPoint)layoutOffset
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *offsetX = [defaults stringForKey:kPPLayoutOffsetXKey];
    CGFloat x = offsetX ? [offsetX floatValue] : kPPDefaultLayoutOffsetX;
    NSString *offsetY = [defaults stringForKey:kPPLayoutOffsetYKey];
    CGFloat y = offsetY ? [offsetY floatValue] : kPPDefaultLayoutOffsetY;
    return CGPointMake(x, y);
}

- (CGFloat)layoutScale
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *scale = [defaults stringForKey:kPPLayoutScaleFactor];
    return scale ? [scale floatValue] : kPPDefaultLayoutScaleFactor;
}

- (void)drawRect:(CGRect)rect {
    [self.combinedImage drawInRect:rect];
}

- (void)setSourceImages:(NSArray<UIImage *> *)images
{
    _sourceImages = images;
    [self scaleImages];
    [self combineImages];
    [self setNeedsDisplay];
}

- (void)drawPerforations:(NSUInteger)count stripPercent:(CGFloat)stripPercent
{
    if (self.perforationsLayer) {
        [self.perforationsLayer removeFromSuperlayer];
    }

    self.perforationsLayer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat gutterPercent = (1.0 - count * stripPercent) / (count + 1.0);
    
    for (int idx = 0; idx < count; idx++) {
        CGFloat yPercent = (idx + 1) * gutterPercent + (idx) * stripPercent;
        CGFloat yPosition = self.bounds.size.height * yPercent;
        [path moveToPoint:CGPointMake(0, yPosition)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width, yPosition)];
        yPosition += self.bounds.size.height * stripPercent;
        [path moveToPoint:CGPointMake(0, yPosition)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width, yPosition)];
    }
    
    self.perforationsLayer.path = [path CGPath];
    self.perforationsLayer.lineWidth = 1;
    self.perforationsLayer.strokeColor = [[UIColor colorWithWhite:0.3 alpha:0.75] CGColor];
    self.perforationsLayer.lineDashPattern = @[ [NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:2.0] ];
    [self.layer addSublayer:self.perforationsLayer];
}

#pragma mark - Image processing

- (void)scaleImages
{
    CGSize canvasSize = CGSizeMake(kPPPaperWidth * kPPDotsPerInch, kPPPaperHeight * kPPDotsPerInch);
    CGSize rowSize = CGSizeMake(canvasSize.width, canvasSize.height * (kPPStripHeight / kPPPaperHeight));
    NSMutableArray *scaledImages = [NSMutableArray arrayWithCapacity:self.sourceImages.count];
    for (UIImage *image in self.sourceImages) {
        UIImage *scaledImage = [self fitImage:image toSize:rowSize];
        [scaledImages addObject:scaledImage];
    }
    self.scaledImages = scaledImages;
}

- (void)combineImages
{
    CGPoint origin = CGPointZero;
    if (self.adjustLayout) {
        CGPoint adjust = [self layoutOffset];
        origin = CGPointMake(adjust.x * kPPDotsPerInch, adjust.y * kPPDotsPerInch);
    }
    
    CGSize canvasSize = CGSizeMake(kPPPaperWidth * kPPDotsPerInch, kPPPaperHeight * kPPDotsPerInch);
    UIGraphicsBeginImageContext(canvasSize);
    [self drawCombinedInRect:CGRectMake(origin.x, origin.y, canvasSize.width, canvasSize.height)];
    _combinedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (UIImage *)fitImage:(UIImage *)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    CGFloat xScale = size.width / image.size.width;
    CGFloat yScale = size.height / image.size.height;
    CGFloat scale = fmaxf(xScale, yScale);
    CGSize scaledSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    CGPoint scaledOrigin = CGPointMake((size.width - scaledSize.width) / 2.0, (size.height - scaledSize.height) / 2.0);
    CGRect targetRect = CGRectIntegral(CGRectMake(scaledOrigin.x, scaledOrigin.y, scaledSize.width, scaledSize.height));
    [image drawInRect:targetRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (void)drawCombinedInRect:(CGRect)rect
{
    CGFloat scale = 1.0;
    if (self.adjustLayout) {
        scale = [self layoutScale];
    }
    
    CGFloat rowPercent = kPPStripHeight / kPPPaperHeight;
    CGFloat gutterPercent = (1.0 - kPPNumberOfStrips * rowPercent) / (kPPNumberOfStrips + 1.0);
    for (int idx = 0; idx < self.scaledImages.count; idx++) {
        CGFloat yPercent = (idx + 1) * gutterPercent + (idx) * rowPercent;
        CGFloat yPosition = rect.size.height * yPercent;
        CGRect rowRect = CGRectIntegral(CGRectMake(rect.origin.x, rect.origin.y + yPosition, rect.size.width, rect.size.height * rowPercent));
        CGFloat dx = (rowRect.size.width - (rowRect.size.width * scale)) / 2.0;
        CGFloat dy = (rowRect.size.height - (rowRect.size.height * scale)) / 2.0;
        rowRect = CGRectInset(rowRect, dx, dy);
        [self.scaledImages[idx] drawInRect:rowRect];
    }
}

@end

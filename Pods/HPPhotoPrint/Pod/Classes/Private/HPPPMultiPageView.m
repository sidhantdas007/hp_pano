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

#import "HPPPMultiPageView.h"
#import "HPPPLayoutPaperView.h"
#import "UIColor+HPPPHexString.h"
#import "HPPPLayoutFactory.h"
#import "HPPPLayoutPaperCellView.h"
#import "HPPP.h"

@interface HPPPMultiPageView() <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalRightConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (assign, nonatomic) NSUInteger actualGutter;
@property (assign, nonatomic) NSUInteger currentPage;
@property (strong, nonatomic) UIScrollView *zoomScrollView;
@property (assign, nonatomic) NSUInteger minimumGutter;
@property (assign, nonatomic) NSUInteger maximumGutter;
@property (assign, nonatomic) NSUInteger bleed;
@property (assign, nonatomic) CGFloat backgroundPageScale;
@property (assign, nonatomic) BOOL doubleTapEnabled;
@property (assign, nonatomic) BOOL zoomOnSingleTap;
@property (assign, nonatomic) BOOL zoomOnDoubleTap;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapRecognizer;
@property (strong, nonatomic) NSArray *blackAndWhitePageImages;
@property (assign, nonatomic) CGPoint zoomInitialOffset;

@end

@implementation HPPPMultiPageView

NSUInteger const kHPPPMultiPageDefaultMinimumGutter = 20; // pixels
NSUInteger const kHPPPMultiPageDefaultMaximumGutter = 40; // pixels
NSUInteger const kHPPPMultiPageDefaultBleed = 20; // pixels
CGFloat const kHPPPMultiPageDefaultBackgroundPageScale = 1.0;

CGFloat const kHPPPPageFadeTime = HPPP_ANIMATION_DURATION; // seconds
CGFloat const kHPPPPageBaseTag = 1000;

CGFloat const kHPPPZoomFadeTime = HPPP_ANIMATION_DURATION; // seconds
CGFloat const kHPPPZoomInset = 20.0; // pixels
CGFloat const kHPPPZoomOverlayAlpha = 0.8;
CGFloat const kHPPPZoomMinimumScale = 1.0;
CGFloat const kHPPPZoomMaximumScale = 8.0;
CGFloat const kHPPPZoomInitialScale = 2.0;
CGFloat const kHPPPZoomAutoCloseScale = 1.1;

NSUInteger const kHPPPZoomScrollViewTag = 99;

static NSNumber *lastPinchScale = nil;

#pragma mark - Initialization

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.minimumGutter = kHPPPMultiPageDefaultMinimumGutter;
        self.maximumGutter = kHPPPMultiPageDefaultMaximumGutter;
        self.bleed = kHPPPMultiPageDefaultBleed;
        self.backgroundPageScale = kHPPPMultiPageDefaultBackgroundPageScale;
        self.backgroundColor = [self getColor:@"Background"];
        self.scrollView.backgroundColor = [self getColor:@"Scroll View"];
        _currentPage = 1;
        [self initializePageGestures];
    }
    return self;
}

- (void)initializePageGestures
{
    [self.scrollView removeGestureRecognizer:self.singleTapRecognizer];
    [self.scrollView removeGestureRecognizer:self.doubleTapRecognizer];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePageSingleTap:)];
    singleTapRecognizer.cancelsTouchesInView = YES;
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer:singleTapRecognizer];

    if (self.doubleTapEnabled) {
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePageDoubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [self.scrollView addGestureRecognizer:doubleTapGesture];
        
        [singleTapRecognizer requireGestureRecognizerToFail:doubleTapGesture];
    }
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer  alloc] initWithTarget:self action:@selector(handlePinchToZoom:)];
    [self.scrollView addGestureRecognizer:pinchRecognizer];
}

- (void)setInterfaceOptions:(HPPPInterfaceOptions *)options
{
    self.minimumGutter = options.multiPageMinimumGutter;
    self.maximumGutter = options.multiPageMaximumGutter;
    self.bleed = options.multiPageBleed;
    self.backgroundPageScale = options.multiPageBackgroundPageScale;
    self.doubleTapEnabled = options.multiPageDoubleTapEnabled;
    self.zoomOnSingleTap = options.multiPageZoomOnSingleTap;
    self.zoomOnDoubleTap = options.multiPageZoomOnDoubleTap;
    [self initializePageGestures];
    [self layoutPagesIfNeeded];
}

#pragma mark - Touches

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [self pointInside:point withEvent:event] ? self.scrollView : nil;
}

#pragma mark - Property setters

- (void)setPaper:(HPPPPaper *)paper
{
    _paper = paper;
    if (self.layout) {
        self.layout.paper = paper;
    }
    [self layoutPagesIfNeeded];
}

- (void)setLayout:(HPPPLayout *)layout
{
    _layout = layout;
    _layout.paper = self.paper;
    [self layoutPagesIfNeeded];
}

- (void)setPageImages:(NSArray *)pages
{
    _pageImages = pages;
    _blackAndWhitePageImages = nil;
    [self updatePages];
}

- (void)setBlackAndWhite:(BOOL)blackAndWhite
{
    _blackAndWhite = blackAndWhite;
    [self updatePages];
}

#pragma mark - Pages

- (void)setPages:(NSArray *)pages paper:(HPPPPaper *)paper layout:(HPPPLayout *)layout;
{
    _paper = paper;
    _layout = layout;
    _layout.paper = _paper;
    self.pageImages = pages;
}

- (void)createPageViews
{
    NSArray *pageImages = self.blackAndWhite ? self.blackAndWhitePageImages : self.pageImages;
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (int idx = 0; idx < pageImages.count; idx++) {
        HPPPLayoutPaperView *paperView = [[HPPPLayoutPaperView alloc] init];
        paperView.image = pageImages[idx];
        paperView.layout = self.layout;
        paperView.backgroundColor = [UIColor whiteColor];
        HPPPLayoutPaperCellView *paperCell = [[HPPPLayoutPaperCellView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) paperView:paperView paper:self.paper];
        paperCell.backgroundColor = [self getColor:@"Page Cell"];
        paperCell.tag = kHPPPPageBaseTag + idx;
        [self.scrollView addSubview:paperCell];
    }
}

- (void)changeToPage:(NSUInteger)pageNumber animated:(BOOL)animated
{
    if (pageNumber >= 1 && pageNumber <= self.pageImages.count) {
        CGFloat scrollWidth = self.scrollView.bounds.size.width;
        [self.scrollView setContentOffset:CGPointMake(scrollWidth * (pageNumber - 1), 0) animated:animated];
        [self changePageNumber:pageNumber];
    }
}

- (void)updatePages
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (self.blackAndWhite) {
            [self processBlackAndWhiteImages];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createPageViews];
            [self layoutPagesIfNeeded];
        });
    });
}

- (void)processBlackAndWhiteImages
{
    if (!self.blackAndWhitePageImages) {
        NSMutableArray *pageImages = [NSMutableArray array];
        for (UIImage *pageImage in self.pageImages) {
            @autoreleasepool {
                CIImage *image = [[CIImage alloc] initWithCGImage:pageImage.CGImage options:nil];
                CIFilter *filter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
                [filter setValue:image forKey:kCIInputImageKey];
                CIImage *result = [filter valueForKey:kCIOutputImageKey];
                CIContext *context = [CIContext contextWithOptions:nil];
                CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
                [pageImages addObject:[UIImage imageWithCGImage:cgImage scale:pageImage.scale orientation:pageImage.imageOrientation]];
                CGImageRelease(cgImage);
            }
        }
        self.blackAndWhitePageImages = pageImages;
    }
}

- (HPPPLayoutPaperCellView *)currentPaperCellView
{
    HPPPLayoutPaperCellView *cell = nil;
    if (self.pageImages.count > 0) {
        cell = (HPPPLayoutPaperCellView *)[self viewWithTag:kHPPPPageBaseTag + self.currentPage - 1];
    }
    return cell;
}

#pragma mark - Layout

- (void)refreshLayout
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self layoutPagesIfNeeded];
}

- (void)layoutPagesIfNeeded
{
    if (!self.paper || !self.layout || !self.pageImages) {
        return;
    }
    
    [self resetZoomLevels];
    [self updateHorizontalConstraints];
    CGFloat scrollWidth = self.scrollView.bounds.size.width;
    CGFloat scrollHeight = self.scrollView.bounds.size.height;
    CGFloat pageWidth = scrollWidth - self.actualGutter;
    CGFloat pageHeight = self.scrollView.bounds.size.height;
    self.scrollView.contentSize = CGSizeMake(scrollWidth * self.pageImages.count, scrollHeight);
    NSUInteger idx = 0;
    for (UIView *subview in self.scrollView.subviews) {
        if ([subview isKindOfClass:[HPPPLayoutPaperCellView class]]) {
            HPPPLayoutPaperCellView *paperCellView = (HPPPLayoutPaperCellView *)subview;
            CGRect cellFrame = CGRectMake(0.5 * self.actualGutter + idx * scrollWidth, 0, pageWidth , pageHeight);
            paperCellView.frame = cellFrame;
            paperCellView.paper = self.paper;
            idx++;
        }
    }
    [self.scrollView setNeedsLayout];
    if (self.currentPage > self.pageImages.count + 1) {
        [self changePageNumber:1];
    }
    [self changeToPage:self.currentPage animated:NO];
}

- (void)updateHorizontalConstraints
{
    if (!self.paper || !self.layout || !self.pageImages) {
        return;
    }
    
    CGFloat paperAspectRatio = self.paper.width / self.paper.height;
    for (UIImage *image in self.pageImages) {
        if (HPPPLayoutOrientationLandscape == [HPPPLayout paperOrientationForImage:image andLayout:self.layout]) {
            paperAspectRatio = self.paper.height / self.paper.width;
            break;
        }
    }
    
    NSUInteger bleed = self.pageImages.count == 1 ? 0 : self.bleed;
    NSUInteger minimumEdgeSpace = bleed + self.minimumGutter;
    CGSize availableSize = CGSizeMake(self.bounds.size.width - 2 * minimumEdgeSpace, self.bounds.size.height);
    CGFloat availableAspectRatio = availableSize.width / availableSize.height;
    CGFloat paperCellWidth = availableSize.width;
    if (paperAspectRatio < availableAspectRatio) {
        paperCellWidth = availableSize.height * paperAspectRatio;
    }
    
    self.actualGutter = (self.bounds.size.width - paperCellWidth - 2 * bleed) / 2.0;
    if (self.maximumGutter > 0) {
        self.actualGutter = fminf(self.actualGutter, self.maximumGutter);
    }
    
    CGFloat scrollViewWidth = paperCellWidth + self.actualGutter;
    CGFloat edgeSpace = (self.bounds.size.width - scrollViewWidth) / 2.0;
    self.horizontalLeftConstraint.constant = edgeSpace;
    self.horizontalRightConstraint.constant = edgeSpace;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)resetZoomLevels
{
    NSUInteger idx = 0;
    for (UIView *subview in self.scrollView.subviews) {
        if ([subview isKindOfClass:[HPPPLayoutPaperCellView class]]) {
            subview.transform = CGAffineTransformIdentity;
            idx++;
        }
    }
}

- (void)setZoomLevels
{
    CGFloat backgroundScale = self.backgroundPageScale;
    CGFloat scrollOffset = self.scrollView.contentOffset.x;
    CGFloat scrollWidth = self.scrollView.bounds.size.width;
    
    NSUInteger viewIndex = scrollOffset / scrollWidth;
    CGFloat viewRatio = (scrollOffset - scrollWidth * viewIndex) / scrollWidth;
    
    NSUInteger leavingViewIndex = viewIndex;
    CGFloat leavingRatio = (1.0 - viewRatio);
    CGFloat leavingViewScale = backgroundScale + (1.0 - backgroundScale) * leavingRatio;
    
    NSUInteger enteringViewIndex = viewIndex + 1;
    CGFloat enteringRatio = viewRatio;
    CGFloat enteringViewScale = backgroundScale + (1.0 - backgroundScale) * enteringRatio;
    
    NSUInteger idx = 0;
    for (UIView *subview in self.scrollView.subviews) {
        if ([subview isKindOfClass:[HPPPLayoutPaperCellView class]]) {
            CGFloat scale = backgroundScale;
            CGFloat progress = 1.0;
            CGFloat direction = (idx < enteringViewIndex) ? 1.0 : -1.0;
            if (idx == enteringViewIndex) {
                scale = enteringViewScale;
                progress = 1.0 - enteringRatio;
            } else if (idx == leavingViewIndex) {
                scale = leavingViewScale;
                progress = 1.0 - leavingRatio;
            }
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
            CGFloat correctionX = (subview.bounds.size.width * (1.0 - scale)) * progress * direction / 2.0 * (1.0 / scale);
            CGAffineTransform combinedTransform = CGAffineTransformTranslate(scaleTransform, correctionX, 0);
            subview.transform = combinedTransform;
            idx++;
        }
    }
    
    if (self.scrollView.alpha < 1.0) {
        [UIView animateWithDuration:kHPPPPageFadeTime animations:^{
            self.scrollView.alpha = 1.0;
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (kHPPPZoomScrollViewTag != scrollView.tag) {
        NSUInteger newPageNumber = (int)scrollView.contentOffset.x / (int)scrollView.bounds.size.width + 1;
        [self changePageNumber:newPageNumber];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (kHPPPZoomScrollViewTag != scrollView.tag) {
        [self setZoomLevels];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    if (kHPPPZoomScrollViewTag == scrollView.tag) {
        if (scrollView.zoomScale <= 1.0) {
            [self removeZoomView];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    UIView *zoomView = nil;
    if (kHPPPZoomScrollViewTag == scrollView.tag) {
        zoomView = [scrollView.subviews firstObject];
    }
    return zoomView;
}

#pragma mark - UIPinchGestureRecognizer

- (void)handlePinchToZoom:(UIGestureRecognizer *)gestureRecognizer
{
    UIPinchGestureRecognizer *pinchRecognizer = (UIPinchGestureRecognizer *)gestureRecognizer;
    if (lastPinchScale && pinchRecognizer.scale > [lastPinchScale floatValue]) {
        [self showZoomViewWithScale:kHPPPZoomInitialScale Animated:YES] ;
    }
    lastPinchScale = [NSNumber numberWithFloat:pinchRecognizer.scale];
}

#pragma mark - UITapGestureRecognizer

- (void)handlePageSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    CGPoint point = [tapGestureRecognizer locationInView:self.scrollView];
    CGFloat scrollWidth = self.scrollView.bounds.size.width;
    NSUInteger pageTapped = point.x / scrollWidth + 1;
    if (pageTapped >= 1 && pageTapped <= self.pageImages.count) {
        if (pageTapped == self.currentPage) {
            [self didSingleTapPage:self.currentPage];
        } else {
            [self changeToPage:pageTapped animated:YES];
        }
    }
}

- (void)handlePageDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    CGPoint point = [tapGestureRecognizer locationInView:self.scrollView];
    CGFloat scrollWidth = self.scrollView.bounds.size.width;
    NSUInteger pageTapped = point.x / scrollWidth + 1;
    if (pageTapped == self.currentPage) {
        [self didDoubleTapPage:self.currentPage];
    }
}

- (void)handleZoomSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    // do nothing
}

- (void)handleZoomDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self hideZoomViewAnimated:YES];
}

#pragma mark - HPPPMultPageViewDelegate

- (void)didSingleTapPage:(NSUInteger)pageNumber
{
    HPPPLogInfo(@"Page %lu was single tapped", (unsigned long)pageNumber);
    
    if (self.zoomOnSingleTap) {
        [self showZoomViewWithScale:kHPPPZoomInitialScale Animated:YES];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiPageView:didSingleTapPage:)]) {
        [self.delegate multiPageView:self didSingleTapPage:pageNumber];
    }
}

- (void)didDoubleTapPage:(NSUInteger)pageNumber
{
    HPPPLogInfo(@"Page %lu was double tapped", (unsigned long)pageNumber);
    
    if (self.zoomOnDoubleTap) {
        [self showZoomViewWithScale:kHPPPZoomInitialScale Animated:YES];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiPageView:didDoubleTapPage:)]) {
        [self.delegate multiPageView:self didDoubleTapPage:pageNumber];
    }
}

- (void)changePageNumber:(NSUInteger)newPageNumber
{
    NSUInteger oldPageNumber = self.currentPage;
    if (oldPageNumber != newPageNumber) {
        _currentPage = newPageNumber;
        HPPPLogInfo(@"Changed from page %lu to page %lu", (unsigned long)oldPageNumber, (unsigned long)newPageNumber);
        if (self.delegate && [self.delegate respondsToSelector:@selector(multiPageView:didChangeFromPage:ToPage:)]) {
            [self.delegate multiPageView:self didChangeFromPage:oldPageNumber ToPage:newPageNumber];
        }
    }
    [self setZoomLevels];
}

#pragma mark - Zooming

- (void)showZoomViewWithScale:(CGFloat)scale Animated:(BOOL)animated
{
    if (self.zoomScrollView) {
        return;
    }
    
    NSArray *pageImages = self.blackAndWhite ? self.blackAndWhitePageImages : self.pageImages;

    HPPPLayoutPaperCellView *zoomSourceView = [self currentPaperCellView];
    
    self.zoomScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    self.zoomScrollView.minimumZoomScale = kHPPPZoomMinimumScale;
    self.zoomScrollView.maximumZoomScale = kHPPPZoomMaximumScale;
    self.zoomScrollView.bouncesZoom = NO;
    self.zoomScrollView.clipsToBounds = YES;
    self.zoomScrollView.autoresizingMask = UIViewAutoresizingNone;
    self.zoomScrollView.delegate = self;
    self.zoomScrollView.tag = kHPPPZoomScrollViewTag;
    
    CGRect pageRect = CGRectMake(0, 0, zoomSourceView.bounds.size.width, zoomSourceView.bounds.size.height);
    HPPPLayoutPaperView *paperView = [[HPPPLayoutPaperView alloc] init];
    paperView.image = pageImages[self.currentPage - 1];
    paperView.layout = self.layout;
    paperView.backgroundColor = [UIColor whiteColor];
    HPPPLayoutPaperCellView *paperCell = [[HPPPLayoutPaperCellView alloc] initWithFrame:pageRect paperView:paperView paper:self.paper];
    paperCell.backgroundColor = [self getColor:@"Page Cell"];
    paperCell.tag = kHPPPZoomScrollViewTag + 1;
    [self.zoomScrollView addSubview:paperCell];
    
    CGFloat offsetX = (zoomSourceView.bounds.size.width - self.zoomScrollView.bounds.size.width) / 2.0;
    CGFloat offsetY = (zoomSourceView.bounds.size.height - self.zoomScrollView.bounds.size.height) / 2.0;
    self.zoomInitialOffset = CGPointMake(offsetX, offsetY);
    self.zoomScrollView.contentSize = zoomSourceView.bounds.size;
    self.zoomScrollView.contentOffset = self.zoomInitialOffset;

    [self.superview addSubview:self.zoomScrollView];
    [self currentPaperCellView].hidden = YES;
    [self initializeZoomGestures];
    [self.zoomScrollView setZoomScale:scale animated:animated];
    [self setPagesVisible:NO animated:animated];
}

- (void)removeZoomView
{
    lastPinchScale = nil;
    [self setPagesVisible:YES animated:NO];
    [self currentPaperCellView].hidden = NO;
    [self.zoomScrollView removeFromSuperview];
    self.zoomScrollView = nil;
}

- (void)setPagesVisible:(BOOL)visible animated:(BOOL)animated
{
    CGFloat alpha = visible ? 1.0 : 0.0;
    if (animated) {
        [UIView animateWithDuration:kHPPPZoomFadeTime animations:^{
            [self setSidePageAlpha:alpha];
        }];
    } else {
        [self setSidePageAlpha:alpha];
    }
}

- (void)setSidePageAlpha:(CGFloat)alpha
{
    for (int idx = 0; idx < self.pageImages.count; idx++) {
        UIView *view = [self viewWithTag:kHPPPPageBaseTag + idx];
        if (view != [self currentPaperCellView]) {
            view.alpha = alpha;
        }
    }
}

- (void)hideZoomViewAnimated:(BOOL)animated
{
    [self.zoomScrollView setZoomScale:1.0 animated:animated];
    [self.zoomScrollView setContentOffset:self.zoomInitialOffset animated:animated];
    [self setPagesVisible:YES animated:animated];
}

- (CGAffineTransform)computeTranformFromRect:(CGRect)sourceRect toRect:(CGRect)resultRect scale:(CGFloat)scale
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(resultRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(resultRect)));
    transform = CGAffineTransformScale(transform, resultRect.size.width/sourceRect.size.width * scale, resultRect.size.height/sourceRect.size.height * scale);
    return transform;
}

- (void)initializeZoomGestures
{
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomSingleTap:)];
    singleTapRecognizer.cancelsTouchesInView = YES;
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [self.zoomScrollView addGestureRecognizer:singleTapRecognizer];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.zoomScrollView addGestureRecognizer:doubleTapGesture];
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapGesture];
}

#pragma mark - Debug

- (UIColor *)getColor:(NSString *)identifier
{
    UIColor *color = [UIColor clearColor];
    if (NO) {
        if ([identifier isEqualToString:@"Background"]) {
            color = [UIColor HPPPColorWithHexString:@"93A3B1"];
        } else if ([identifier isEqualToString:@"Scroll View"]) {
            color = [UIColor HPPPColorWithHexString:@"AEB2B0"];
        } else if ([identifier isEqualToString:@"Page Cell"]) {
            color = [UIColor HPPPColorWithHexString:@"000000"];
        }
    }
    return color;
}

@end

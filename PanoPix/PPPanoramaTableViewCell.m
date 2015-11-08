//
//  PanoramaTableViewCell.m
//  PanoPix
//
//  Created by James Trask on 11/5/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPanoramaTableViewCell.h"

@implementation PPPanoramaTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setIncluded:(BOOL)included
{
    _included = included;
    NSString *imageName = _included ? @"ActiveCircle" : @"InactiveCircle";
    self.checkmarkImageView.image = [UIImage imageNamed:imageName];
}

- (void)setAsset:(PHAsset *)asset
{
    if (nil != asset && _asset != asset) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.synchronous = NO;
        
        CGRect scrollFrame = CGRectMake(0, 0, 50.0 / (1.375/7.0), 50.0);
        CGSize contentSize = [self sizeForAsset:asset inContainer:scrollFrame];
        CGPoint offset = CGPointMake(
                                     (scrollFrame.size.width - contentSize.width) / 2.0,
                                     (scrollFrame.size.height - contentSize.height) / 2.0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:contentSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                
                self.panoScrollView.contentSize = contentSize;
                self.panoScrollView.contentOffset = offset;
                self.panoScrollView.contentInset = UIEdgeInsetsZero;
                
                self.panoImageView.frame= CGRectMake(
                                                     offset.x,
                                                     offset.y,
                                                     contentSize.width,
                                                     contentSize.height);

                self.panoImageView.image = result;
            }];
        });
    }
    _asset = asset;
}

- (CGSize)sizeForAsset:(PHAsset *)asset inContainer:(CGRect)rect
{
    CGFloat xScale = (float)asset.pixelWidth / rect.size.width;
    CGFloat yScale = (float)asset.pixelHeight / rect.size.height;
    CGFloat scale = fminf(xScale, yScale);
    return CGSizeMake((float)asset.pixelWidth/ scale, (float)asset.pixelHeight / scale);
}

@end

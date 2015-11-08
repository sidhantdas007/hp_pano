//
//  PanoramaTableViewCell.h
//  PanoPix
//
//  Created by James Trask on 11/5/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface PPPanoramaTableViewCell : UITableViewCell

@property (assign, nonatomic) BOOL included;
@property (strong, nonatomic) PHAsset *asset;
@property (weak, nonatomic) IBOutlet UIImageView *panoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;

@end

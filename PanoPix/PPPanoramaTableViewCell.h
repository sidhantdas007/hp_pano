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

@property (weak, nonatomic) IBOutlet UIImageView *panoramaImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;
@property (assign, nonatomic) BOOL included;
@property (strong, nonatomic) PHAsset *asset;

@end

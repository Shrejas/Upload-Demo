//
//  ImagesCollectionCell.m
//  Upload-Demo
//
//  Created by Shrejas Chandel on 25/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import "ImagesCollectionCell.h"

@implementation ImagesCollectionCell

- (void)prepareForReuse
{
    self.imageView.image = nil;
    [super prepareForReuse];
}

@end

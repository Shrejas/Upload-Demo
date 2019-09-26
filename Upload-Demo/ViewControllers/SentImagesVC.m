//
//  SentImagesVC.m
//  Upload-Demo
//
//  Created by Shrejas Chandel on 25/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import "SentImagesVC.h"
#import "ImagesCollectionCell.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SentImagesVC ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *imagesArray;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation SentImagesVC

#pragma mark - ViewController life cycle method

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Make collection view delegates self
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.activityIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self fetchImages];
    });
}

#pragma mark - Fetch all images from document directory

- (void)fetchImages
{
    // Get paths
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *firstPath = [paths objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // All files in the path
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:firstPath error:nil];
    
    // Filter only image files
    NSMutableArray *subpredicates = [NSMutableArray array];
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.png'"]];
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.jpg'"]];
    NSPredicate *filter = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
    
    NSArray *onlyImages = [directoryContents filteredArrayUsingPredicate:filter];
    
    self.imagesArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < onlyImages.count; i++)
    {
        // Append images one by one to array
        NSString *imagePath = [firstPath stringByAppendingPathComponent:[onlyImages objectAtIndex:i]];
        [self.imagesArray addObject:imagePath];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.activityIndicator stopAnimating];
        
        // Reload collection view to show fetched images.
        [self.collectionView reloadData];
    });
}

#pragma mark - UICollectionView delegate methods to show images on UI

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ImagesCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImagesCollectionCell" forIndexPath:indexPath];
    
    // Get image from array and render on UI
    NSURL *url = [NSURL fileURLWithPath:[self.imagesArray objectAtIndex:indexPath.row]];
    [cell.imageView setImageWithURL:url];
        
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    float leading = 2.0;
//    float spacing = 5.0;
//    CGRect screen = [[UIScreen mainScreen] bounds];
//    float widthScreen = CGRectGetWidth(screen);
//    float width = (widthScreen - (leading * 2) - spacing) / 2;
//    float height = width * 0.847;
//
//    return CGSizeMake(width, height);
//}

@end

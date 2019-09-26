//
//  ViewController.m
//  Upload-Demo
//
//  Created by Shrejas Chandel on 24/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import "ViewController.h"
#import <IQMediaPickerController/IQMediaPickerController.h>
#import <Photos/Photos.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "Constants.h"
#import "NSFileManager+Temp.h"

@interface ViewController ()<IQMediaPickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSMutableArray *selectedImages;
@property (strong, nonatomic) NSMutableArray *selectedImagesName;
@property (nonatomic) NSInteger mediaCount;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

@end

@implementation ViewController

#pragma mark - ViewController life cycle method

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.progressView setHidden:YES];
    [self.statusLabel setHidden:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"";
        self.progressView.progress = 0;
    });
    
    //listen to the orientation change notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showImagePicker:) name:iSUserLoggedIn object:nil];
    
    [NSFileManager clearTempDirectory];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:iSUserLoggedIn object:nil];
}

#pragma mark - Get top most view controller to present dropbox controller above all

+ (UIViewController*)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController)
    {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark - Private Helper

- (NSDateFormatter*) dateformatter
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = NSTimeZone.localTimeZone;
        [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    });
    return formatter;
}

#pragma mark - Get image name

- (NSString*)getImageName
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSInteger imageCount = [userDefault integerForKey:ImageCount];
    if(imageCount == 0)
    {
        imageCount = 1;
    }
    NSString *anImageName = [NSString stringWithFormat:@"/%ld.png", (long)imageCount];
    imageCount = imageCount+1;
    [userDefault setInteger:imageCount forKey:ImageCount];
    [userDefault synchronize];
    return anImageName;
}

#pragma mark - Receive notification to launch media picker

- (void)showImagePicker:(NSNotification *)notification
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

    switch (status) {
        case PHAuthorizationStatusNotDetermined:
        {
            __weak typeof(self) weakSelf = self;
            // Access has not been determined.
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized)
                {
                    [weakSelf showMediaPickerSourceType];
                }
                else
                {
                    [self photoLibraryPermissionDeniedMessage];
                }
            }];
        }
            break;
        case PHAuthorizationStatusAuthorized:
            [self showMediaPickerSourceType];
            break;
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
            [self photoLibraryPermissionDeniedMessage];
            break;
        default:
            break;
    }
}

#pragma mark - Show media picker as per source type selection

- (void)showMediaPickerSourceType
{
    UIAlertController *actionSheet = [UIAlertController
                                      alertControllerWithTitle:@"Select Photo"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction
                            actionWithTitle:@"Cancel"
                            style:UIAlertActionStyleCancel
                            handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction
                            actionWithTitle:@"Camera"
                            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self selectMediaFrom:@"Camera"];
    }]];
    
    [actionSheet addAction:[UIAlertAction
                            actionWithTitle:@"Gallery"
                            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self selectMediaFrom:@"Library"];
    }]];
    
    runOnMainThreadWithoutDeadlocking(^{        
        // Present action sheet.
        [self presentViewController:actionSheet
                           animated:YES
                         completion:nil];
    });
}

#pragma mark - Launch media picker controller

- (void)selectMediaFrom:(NSString *)sourceType
{
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    
    if ([sourceType isEqualToString:@"Camera"])
    {
        [controller setSourceType:IQMediaPickerControllerSourceTypeCameraMicrophone];
    }
    else
    {
        [controller setSourceType:IQMediaPickerControllerSourceTypeLibrary];
    }
    
    controller.delegate = self;
    [controller setMediaTypes:@[@(PHAssetMediaTypeImage)]];
    controller.allowsPickingMultipleItems = YES;
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Button to upload media to server

- (IBAction)buttonUploadTap:(id)sender
{
    self.mediaCount = 0;
    self.statusLabel.text = @"";
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:iSUserLoggedIn])
    {
        [self showImagePicker:nil];
    }
    else
    {
        // Launch dropbox controller
        [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                       controller:[[self class] topMostController]
                                          openURL:^(NSURL *url) {
            [[UIApplication sharedApplication] openURL:url
                                               options:@{}
                                     completionHandler:^(BOOL success) {
                if (success)
                {
                    NSLog(@"Opened url");
                }
            }];
        }];
    }
}

- (void)photoLibraryPermissionDeniedMessage
{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Access Denied"
                                message:@"Please allow photo library permission to access your photos."
                                preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction
                      actionWithTitle:@"Ok"
                      style:UIAlertActionStyleCancel
                      handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }]];
        
    runOnMainThreadWithoutDeadlocking(^{
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
    });

}

#pragma mark - Method to upload selected media to server

- (void)uploadImagesToServer
{
    self.uploadButton.enabled = false;
    if (self.selectedImages.count != 0)
    {
        NSString *imageName = self.selectedImagesName[0];
        UIImage *image = self.selectedImages[0];
        self.mediaCount++;
        
        [self.statusLabel setHidden:NO];
        [self.progressView setHidden:NO];
        
        self.statusLabel.text = @"Uploading images";
        self.progressView.progress = 0;
        
        DBUserClient *client = [[DBUserClient alloc] initWithAccessToken:dropBoxAccessToken];
        
        NSData *data = UIImageJPEGRepresentation(image, 0.9);
        NSString *file = [NSTemporaryDirectory() stringByAppendingPathComponent:imageName];
        [data writeToFile:file atomically:YES];
        
        __weak typeof(self) weakSelf = self;
        [[[client.filesRoutes uploadUrl:imageName inputUrl:file] setResponseBlock:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *networkError) {
            if (result)
            {
                [weakSelf saveImageLocally:image withName:imageName];
                
                [weakSelf.selectedImages removeObjectAtIndex:0];
                [weakSelf.selectedImagesName removeObjectAtIndex:0];
                                
                [weakSelf uploadImagesToServer];
            }
            else
            {
                [weakSelf resetProgress];
            }
        }] setProgressBlock:^(int64_t bytesUploaded, int64_t totalBytesUploaded, int64_t totalBytesExpectedToUploaded) {
            
            NSString *totalCount = [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToUploaded countStyle:NSByteCountFormatterCountStyleFile];
            NSString *currentCount = [NSByteCountFormatter stringFromByteCount:totalBytesUploaded countStyle:NSByteCountFormatterCountStyleFile];
            
            float totalSize = (float)totalBytesExpectedToUploaded/1024.0f/1024.0f;
            float currentSize = (float)totalBytesUploaded/1024.0f/1024.0f;
            float progressCount = currentSize / totalSize;
            
            weakSelf.statusLabel.text = [NSString stringWithFormat:@"Uploading image %ld - %@ of %@", (long)weakSelf.mediaCount, currentCount, totalCount];
            weakSelf.progressView.progress = progressCount;
        }];
    }
    else
    {
        [self resetProgress];
    }
}

- (void)resetProgress
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.uploadButton.enabled = true;
        weakSelf.statusLabel.text = [NSString stringWithFormat:@"Successfully uploaded %ld images.", (long)weakSelf.mediaCount];
        [weakSelf.progressView setHidden:YES];
        
        [weakSelf.selectedImages removeAllObjects];
        [weakSelf.selectedImagesName removeAllObjects];
        weakSelf.mediaCount = 0;
    });
}

#pragma mark - Method to save selected media locally

- (void)saveImageLocally:(UIImage *)image withName:(NSString *)name
{
    NSString *aDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *anImagePath = [NSString stringWithFormat:@"%@/%@", aDocumentsDirectory, name];
    
    NSData *anImageData = UIImageJPEGRepresentation(image, 0.8);
    [anImageData writeToFile:anImagePath atomically:YES];
}

#pragma mark - IQMediaPickerController delegate methods

- (void)mediaPickerController:(IQMediaPickerController *)controller didFinishMedias:(IQMediaPickerSelection *)selection
{
    //Here you'll get the information about captured or picked assets
    PHImageManager *manager = [PHImageManager defaultManager];
    
    // assets contains PHAsset objects.
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.synchronous = YES;
    
    if (selection.selectedAssets.count == 0)
    {
        self.selectedImages = [NSMutableArray arrayWithCapacity:[selection.selectedImages count]];
        self.selectedImagesName = [NSMutableArray arrayWithCapacity:[selection.selectedImages count]];
        
        for (UIImage *image in selection.selectedImages)
        {
            [self.selectedImages addObject:image];
            [self.selectedImagesName addObject:[self getImageName]];
        }
    }
    else
    {
        self.selectedImages = [NSMutableArray arrayWithCapacity:[selection.selectedAssets count]];
        self.selectedImagesName = [NSMutableArray arrayWithCapacity:[selection.selectedAssets count]];
        
        for (PHAsset *asset in selection.selectedAssets)
        {
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                [self.selectedImages addObject:image];
                [self.selectedImagesName addObject:[self getImageName]];
            }];
        }
    }
        
    [self uploadImagesToServer];
}

- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

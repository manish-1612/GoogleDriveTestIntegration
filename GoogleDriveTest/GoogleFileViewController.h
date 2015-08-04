//
//  GoogleFileViewController.h
//  GoogleDriveTest
//
//  Created by Manish Kumar on 17/12/14.
//  Copyright (c) 2014 Innofied Solutions Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

typedef enum _directoryStatus
{
    kDirectoryCreationFailed,
    kDirectoryCreationSuccess,
    kDirectoryExists,
}DirectoryCreationStatus;


@interface GoogleFileViewController : UIViewController

@property (nonatomic, retain) GTLServiceDrive *driveService;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *buttonForBack;
@property (weak, nonatomic) IBOutlet UITableView *tableViewForFiles;

-(void)setDataSourceWithGoogleObject:(NSMutableDictionary *)googleDictionary;


@end

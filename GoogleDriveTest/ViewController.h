//
//  ViewController.h
//  GoogleDriveTest
//
//  Created by Manish Kumar on 15/12/14.
//  Copyright (c) 2014 Innofied Solutions Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"


@interface ViewController : UIViewController

@property (nonatomic, retain) GTLServiceDrive *driveService;

@end


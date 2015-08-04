//
//  ViewController.m
//  GoogleDriveTest
//
//  Created by Manish Kumar on 15/12/14.
//  Copyright (c) 2014 Innofied Solutions Pvt. Ltd. All rights reserved.
//

#import "ViewController.h"
#import "NetworkRequestHandler.h"
#import "GoogleFileViewController.h"


static NSString *const kKeychainItemName = @"GoogleDriveTest";
static NSString *const kClientID = @"917965086511-onmn5tefm9n68nueaf5rc6u4564cnc3t.apps.googleusercontent.com";
static NSString *const kClientSecret = @"2lyC-dI_NQCfBlb-PT8CL57t";



//#define BASE_URL_OF_SERVER     @"http://intra.iam.hva.nl/content/1011/propedeuse/hci/intro-en-materiaal/MobileHIG.pdf"


@interface ViewController ()
{
    BOOL isAuthorized;
}
@property (nonatomic) BOOL fileFetchStatusFailure;
@property (strong , nonatomic) NSMutableArray *parentIdList;

@end

@implementation ViewController
@synthesize fileFetchStatusFailure, parentIdList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)signInToGoogleAccount:(id)sender
{
    [self showGoogleDriveForChoosingFile];
}



#pragma mark-
#pragma mark- google implementation methods

//===================dropbox implementation methods=================//
-(void)showGoogleDriveForChoosingFile
{
    [self setValuesForGoogleDriveAccess];
    
    NSLog(@"((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize : %i", [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize]);
    
    if (![self isAuthorized])
    {
        isAuthorized=NO;
        
        NSLog(@"authorizing again");
        GTMOAuth2ViewControllerTouch *authController=  [self createAuthController];
        NSLog(@"authorizing again : %@",authController  );
    }
    else
    {
        isAuthorized=YES;
        [self openViewToShowFiles];
    }
    
}

-(void)setValuesForGoogleDriveAccess
{
    // Initialize the drive service & load existing credentials from the keychain if available
    self.driveService = [[GTLServiceDrive alloc] init];
    
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                         clientID:kClientID
                                                                                     clientSecret:kClientSecret];
    
    NSLog(@"authorizer : %@", self.driveService.authorizer);
    //driveFiles = [[NSMutableArray alloc]initWithCapacity:0];
    
    parentIdList = [[NSMutableArray alloc]initWithCapacity:0];
}

-(BOOL)isAuthorized
{
    return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
}

-(GTMOAuth2ViewControllerTouch *)createAuthController
{
    
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDrive
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    
    [self presentViewController:authController animated:YES completion:Nil];
    return authController;
}


-(void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
     finishedWithAuth:(GTMOAuth2Authentication *)authResult
                error:(NSError *)error
{
    NSLog(@"finishedWithAuth");
    
    if (error != nil)
    {
        NSLog(@"error : %@", error.localizedDescription);
        
        [self dismissViewControllerAnimated:YES completion:Nil];
        
        isAuthorized=NO;
        
        //[self showAlert:@"Authentication Error" message:error.localizedDescription];
        UIAlertView *alertForNoAuthentication=[[UIAlertView alloc]initWithTitle:@"Authentication Error" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
        [alertForNoAuthentication show];
        self.driveService.authorizer = nil;
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:Nil];
        
        UIAlertView *alertForNoAuthentication=[[UIAlertView alloc]initWithTitle:@"Authentication successful" message:@"authortiozation done" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
        [alertForNoAuthentication show];
        
        isAuthorized=YES;
        
        self.driveService.authorizer = authResult;
        [self openViewToShowFiles];
    }
}


-(void)openViewToShowFiles
{
    if(isAuthorized)
    {
        UIStoryboard *settingsStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *initialViewController  = [settingsStoryBoard instantiateViewControllerWithIdentifier:@"googleDrive"];
        
        NSMutableDictionary *dictionaryToSend=[[NSMutableDictionary alloc]init];
        [dictionaryToSend setObject: self.driveService forKey:@"authResult"];
        
        
        if([initialViewController respondsToSelector:@selector(setDataSourceWithGoogleObject:)])
        {
            [initialViewController performSelector:@selector(setDataSourceWithGoogleObject:) withObject:dictionaryToSend];
        }
        
        
        initialViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:initialViewController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"ERROR" message:@"You are not authorized to view files" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        
        [alert show];
    }
}







/*
#pragma mark- Avoiding iCloud Storage Data Sik for Downloaded More Apps Images
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
    
    //assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    else{
        NSLog(@"Skip Attribute added successfully for %@", [URL lastPathComponent]);
    }
    return success;
}


-(void)saveScoreJSONData:(NSData*)jsonData forFileName:(NSString*)fileName
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        

        BOOL fileSavingStatus = [jsonData writeToFile:fileName atomically:YES];
        NSLog(@"ScoreAPIManager: Disk JSON data saving status = %d for fileName :%s",fileSavingStatus,[[fileName lastPathComponent] UTF8String]);

        // Adding skip attribute to avoid data sinking in iCloud
        [self addSkipBackupAttributeToItemAtURL:[NSURL URLWithString:fileName]];
        
    });
}



-(NSString*)directoryPathForGameScore
{
    NSString *directoryName = @"pdfFile";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory,   NSUserDomainMask, YES);
    NSString *applicationDirectory = [paths objectAtIndex:0];
    return [applicationDirectory stringByAppendingPathComponent:directoryName];
}
*/



/*
 
 NetworkRequestHandler *addTagJSONDownLoader=[[NetworkRequestHandler alloc]initWithBaseURLString:BASE_URL_OF_SERVER
 objectPathInURL:nil
 dataDictionaryToPost:nil];
 
 
 addTagJSONDownLoader.timeOutInterval=1000000.0;
 NetworkRequestHandler * __weak newWeakAddTagJSONDownLoader = addTagJSONDownLoader;
 [newWeakAddTagJSONDownLoader setCompletionHandler:^{
 
 NSLog(@"inside completion Handler");
 
 
 
 NSDictionary *receivedJSONDictionary =[NSJSONSerialization JSONObjectWithData:newWeakAddTagJSONDownLoader.responseData
 options:NSJSONReadingMutableContainers
 error:nil];
 
 
 NSLog(@"receivedJSONDictionary : %@", receivedJSONDictionary);
 
 NSLog(@"success");
 NSString *dirPath = [self directoryPathForGameScore];
 NSString *fileName = [dirPath stringByAppendingPathComponent:@"Test.pdf"];
 [self saveScoreJSONData:newWeakAddTagJSONDownLoader.responseData forFileName:fileName];
 }];
 
 [newWeakAddTagJSONDownLoader startDownload];
 
 
 [newWeakAddTagJSONDownLoader setErrorHandler:^(NSError *deleteTagJSONDownLoaderError)
 {
 NSLog(@"in error : %@", deleteTagJSONDownLoaderError.localizedDescription);
 }];
 
 [newWeakAddTagJSONDownLoader setProgressReporter:^{
 NSLog(@"file downloaded successfully with progress : %f", newWeakAddTagJSONDownLoader.downloadProgressionFraction);
 }];
 
 */


@end

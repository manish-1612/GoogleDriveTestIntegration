//
//  GoogleFileViewController.m
//  GoogleDriveTest
//
//  Created by Manish Kumar on 17/12/14.
//  Copyright (c) 2014 Innofied Solutions Pvt. Ltd. All rights reserved.
//

#import "GoogleFileViewController.h"
#import "NetworkRequestHandler.h"
#import "AppDelegate.h"
#import "ReaderDocument.h"
#import "ReaderViewController.h"
typedef void(^FileSavingCompletionHandler) (BOOL successStatus);

@interface GoogleFileViewController ()<ReaderViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    AppDelegate *appDelegate;
    BOOL fileFetchStatusFailure;
    NSInteger fileNameLength;
    NSInteger level;
    
}
@property (strong , nonatomic) NSMutableArray *driveFiles;
@property (strong , nonatomic) NSMutableArray *parentIdArray;
@property (strong , nonatomic) NSMutableArray *titleArray;
@property (strong , nonatomic) UIView *viewForActivityIndicator;
@property (strong , nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong , nonatomic) NSMutableArray *arrayForStoringViewOrigin;
@property (strong , nonatomic) NSMutableArray *fileNames;


@end

@implementation GoogleFileViewController
@synthesize driveService, driveFiles,parentIdArray, titleArray, viewForActivityIndicator, activityIndicator,  arrayForStoringViewOrigin;
@synthesize buttonForBack;
@synthesize titleLabel;
@synthesize tableViewForFiles, fileNames;

-(void)setDataSourceWithGoogleObject:(NSMutableDictionary *)googleDictionary
{
    driveService=[googleDictionary objectForKey:@"authResult"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    tableViewForFiles.delegate=self;
    tableViewForFiles.dataSource=self;
    //tableViewForFiles.separatorStyle=UITableViewCellSeparatorStyleNone;
    // Do any additional setup after loading the view.
    
    
    viewForActivityIndicator=[[UIView alloc]initWithFrame:CGRectMake(80, (self.view.frame.size.height - 140)/2, 160, 100)];
    viewForActivityIndicator.backgroundColor=[UIColor colorWithWhite:0.0 alpha:0.6];
    viewForActivityIndicator.layer.cornerRadius = 5;
    viewForActivityIndicator.layer.masksToBounds = YES;
    [self.view addSubview:viewForActivityIndicator];
    
    
    UILabel *loadingLabel=[[UILabel alloc]initWithFrame:CGRectMake(30, 20, 100, 30)];
    loadingLabel.textColor=[UIColor whiteColor];
    loadingLabel.backgroundColor=[UIColor clearColor];
    loadingLabel.text=@"Loading...";
    loadingLabel.textAlignment=NSTextAlignmentCenter;
    [loadingLabel setFont:[UIFont fontWithName:@"ProximaNova-Regular" size:16]];
    [viewForActivityIndicator addSubview:loadingLabel];
    
    
    parentIdArray=[[NSMutableArray alloc]initWithCapacity:0];
    titleArray=[[NSMutableArray alloc]initWithCapacity:0];
    
    
    activityIndicator=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.frame=CGRectMake(70, 60, 20, 20);
    activityIndicator.hidesWhenStopped=YES;
    [viewForActivityIndicator addSubview:activityIndicator];
    viewForActivityIndicator.hidden=YES;
    
    [self loadDriveFilesForForMyDrive];
    
    tableViewForFiles.backgroundColor=[UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:239.0/255.0 alpha:1.0];
    
    fileNames = [[NSMutableArray alloc]initWithCapacity:0];
    
    
    [buttonForBack addTarget:self  action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
}

-(void)cancelClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)loadDriveFilesForForMyDrive
{
    viewForActivityIndicator.hidden=NO;
    [activityIndicator startAnimating];
    
    
    fileFetchStatusFailure = NO;
    
    //for more info about fetching the files check this link
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    
    query.q = [NSString stringWithFormat:@"'%@' IN parents", @"root"];
    //query.q = @"sharedWithMe";
    
    
    NSLog(@"query : %@", query.description);
    
    // queryTicket can be used to track the status of the request.
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFileList *files, NSError *error)
     {
         
         
         
         //NSLog(@"error: %@", error.localizedDescription);
         GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
         
         //incase there is no files under this folder then we can avoid the fetching process
         
         if(error)
         {
             UIAlertView *alertForError=[[UIAlertView alloc]initWithTitle:@"ERROR" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
             
             [alertForError show];
             
             viewForActivityIndicator.hidden=YES;
             [activityIndicator stopAnimating];
         }
         else
         {
             driveFiles = [[NSMutableArray alloc] init];
             [driveFiles addObjectsFromArray:files.items];
             viewForActivityIndicator.hidden=YES;
             [activityIndicator stopAnimating];

             
             if (driveFiles.count == 0)
             {
                 UIAlertView *noDataAlert=[[UIAlertView alloc]initWithTitle:@"NO FILE" message:@"No Files in google drive" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
                 
                 [noDataAlert show];
                 
                 viewForActivityIndicator.hidden=YES;
                 [activityIndicator stopAnimating];
             }
             else
             {
                 [tableViewForFiles reloadData];
             }
         }
         
         //finally execute the batch query. Since the file reterive process is much faster because it will get all file metadata info at once
         [self.driveService executeQuery:batchQuery
                       completionHandler:^(GTLServiceTicket *ticket,
                                           GTLDriveFile *file,
                                           NSError *error) {
                       }];
         
     }];
}



-(void)loadDriveFilesForSharedFiles
{
    viewForActivityIndicator.hidden=NO;
    [activityIndicator startAnimating];
    
    fileFetchStatusFailure = NO;
    
    //for more info about fetching the files check this link
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    
    query.q = @"sharedWithMe";
    
    
    // queryTicket can be used to track the status of the request.
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFileList *files, NSError *error)
     {
         
         
         
         //NSLog(@"error: %@", error.localizedDescription);
         GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
         
         //incase there is no files under this folder then we can avoid the fetching process
         
         if(error)
         {
             UIAlertView *alertForError=[[UIAlertView alloc]initWithTitle:@"ERROR" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
             
             [alertForError show];
             
             viewForActivityIndicator.hidden=YES;
             [activityIndicator stopAnimating];
         }
         else
         {
             [driveFiles addObjectsFromArray:files.items];
             
             if (driveFiles.count == 0)
             {
                 UIAlertView *noDataAlert=[[UIAlertView alloc]initWithTitle:@"NO FILE" message:@"No Files in google drive" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:Nil, nil];
                 
                 [noDataAlert show];
                 
                 viewForActivityIndicator.hidden=YES;
                 [activityIndicator stopAnimating];
             }
             else
             {
                 viewForActivityIndicator.hidden=YES;
                 [activityIndicator stopAnimating];
                 
                 //[self createViewForShowingGoogleDriveFiles];
                 
             }
         }
         
         //finally execute the batch query. Since the file reterive process is much faster because it will get all file metadata info at once
         [self.driveService executeQuery:batchQuery
                       completionHandler:^(GTLServiceTicket *ticket,
                                           GTLDriveFile *file,
                                           NSError *error) {
                           
                       }];
     }];
}




#pragma tableview delegates
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return driveFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    GTLDriveFile *file=[driveFiles objectAtIndex:indexPath.row];
    
    //[cell.textLabel setText:[NSString stringWithFormat:@"%@",item.name]];
    UIImageView *imageViewForIcon  = [[UIImageView alloc]initWithFrame:CGRectMake(7, 7, 30, 30)];
    [cell.contentView addSubview:imageViewForIcon];
    
    
    UILabel *labelForTitle = [[UILabel alloc]initWithFrame:CGRectMake(imageViewForIcon.frame.origin.x * 2 + imageViewForIcon.frame.size.width, (cell.frame.size.height-imageViewForIcon.frame.size.height/2)/2, tableView.frame.size.width - (imageViewForIcon.frame.size.width+ 3 * imageViewForIcon.frame.origin.x)-30, imageViewForIcon.frame.size.height/2)];
    labelForTitle.text=file.title;
    [cell.contentView addSubview:labelForTitle];
    
    
    if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"])
    {
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        imageViewForIcon.image=[UIImage imageNamed:@"folder.png"];
    }
    else
    {
        NSString *fileExtension=file.fileExtension;
        
        if (fileExtension)
        {
            if ([fileExtension isEqualToString:@"xls"]||[fileExtension isEqualToString:@"xlsx"]||[fileExtension isEqualToString:@"xlsm"]||[fileExtension isEqualToString:@"xlsm"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"newxl.png"];
            }
            else if ([fileExtension isEqualToString:@"doc"]||[fileExtension isEqualToString:@"docx"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"doc.png"];
            }
            else if([fileExtension isEqualToString:@"pps"]||[fileExtension isEqualToString:@"ppt"]||[fileExtension isEqualToString:@"pptx"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"ppt.png"];
            }
            else if([fileExtension isEqualToString:@"jpg"]||[fileExtension isEqualToString:@"jpeg"]||[fileExtension isEqualToString:@"png"]||[fileExtension isEqualToString:@"gif"]||[fileExtension isEqualToString:@"tiff"]||[fileExtension isEqualToString:@"bmp"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"image.png"];
            }
            else if([fileExtension isEqualToString:@"pdf"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"pdf.png"];
            }
            else if ([fileExtension isEqualToString:@"txt"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"text.png"];
            }
            else if ([fileExtension isEqualToString:@"zip"]||[fileExtension isEqualToString:@"zipx"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"zip.png"];
            }
            else
            {
                imageViewForIcon.image=[UIImage imageNamed:@"un.png"];
            }
        }
        else
        {
            if ([file.mimeType isEqualToString:@"application/vnd.google-apps.document"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"doc.png"];
            }
            else if([file.mimeType isEqualToString:@"application/vnd.google-apps.presentation"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"ppt.png"];
            }
            else if([file.mimeType isEqualToString:@"application/vnd.google-apps.form"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"form.png"];
            }
            else if([file.mimeType isEqualToString:@"application/vnd.google-apps.drawing"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"drawing.png"];
            }
            else if ([file.mimeType isEqualToString:@"application/vnd.google-apps.spreadsheet"])
            {
                imageViewForIcon.image=[UIImage imageNamed:@"newxl.png"];
            }
        }
    }
    
    cell.backgroundView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"gray_bar_no_upper.png"]];
    
    return cell;
}

-(void)printFilesInFolderWithService:(GTLServiceDrive *)service
                            folderId:(NSString *)folderId andName:(NSString *)name{
    
    
    //NSLog(@"folder id: %@", folderId);
    
    viewForActivityIndicator.hidden=NO;
    [activityIndicator startAnimating];
    
    // The service can be set to automatically fetch all pages of the result. More
    // information can be found on https://code.google.com/p/google-api-objectivec-client/wiki/Introduction#Result_Pages.
    service.shouldFetchNextPages = YES;
    
    [driveFiles removeAllObjects];
    
    GTLQueryDrive *query =
    [GTLQueryDrive queryForChildrenListWithFolderId:folderId];
    // queryTicket can be used to track the status of the request.
    GTLServiceTicket *queryTicket =
    [service executeQuery:query
        completionHandler:^(GTLServiceTicket *ticket,
                            GTLDriveChildList *children, NSError *error) {
            if (error == nil) {
                for (GTLDriveChildReference *child in children) {
                    NSLog(@"File Id: %@", child.identifier);
                    
                    GTLQuery *query = [GTLQueryDrive queryForFilesGetWithFileId:child.identifier];
                    
                    // queryTicket can be used to track the status of the request.
                    [self.driveService executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      GTLDriveFile *file,
                                                      NSError *error) {
                                      
                                      NSLog(@"\nfile name = %@", file.originalFilename);
                                      [driveFiles addObject:file];
                                      
                                      if (children.items.count==driveFiles.count)
                                      {
                                          [UIView beginAnimations:nil context:NULL];
                                          [UIView setAnimationDuration:0.4];
                                          tableViewForFiles.alpha=0.0;
                                          [UIView commitAnimations];
                                          
                                          [tableViewForFiles reloadData];
                                          
                                          [UIView beginAnimations:nil context:NULL];
                                          [UIView setAnimationDuration:0.4];
                                          tableViewForFiles.alpha=1.0;
                                          [UIView commitAnimations];
                                          
                                          viewForActivityIndicator.hidden=YES;
                                          [activityIndicator stopAnimating];
                                      }
                                  }];
                }
            } else {
                NSLog(@"An error occurred: %@", error);
            }
        }];
}

-(void)changeTitleWithId:(NSString *)parentId
{
    NSString *title=[titleArray lastObject];
    titleLabel.text=title;
    
    [titleArray removeLastObject];
}

-(void)performBackNavigation
{
    level-=1;
    
    if (level==0)
    {
        titleLabel.text=@"Google Files";
        
        [parentIdArray removeAllObjects];
        [titleArray removeAllObjects];
        
        [buttonForBack removeTarget:self action:@selector(performBackNavigation) forControlEvents:UIControlEventTouchUpInside];
        [buttonForBack addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
        [buttonForBack setTitle:@"Cancel" forState:UIControlStateNormal];
        
        [self printFilesInFolderWithService:driveService folderId:@"root" andName:nil];
    }
    else
    {
        [parentIdArray removeLastObject];
        
        NSString *folderId=[parentIdArray lastObject];
        
        [self changeTitleWithId:folderId];
        [self printFilesInFolderWithService:driveService folderId:folderId andName:nil];
    }
    
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GTLDriveFile *file=[driveFiles objectAtIndex:indexPath.row];
    
    
    if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"])
    {
        level+=1;
        [parentIdArray addObject:file.identifier];
        [titleArray addObject:titleLabel.text];
        titleLabel.text=file.title;
        
        if ([buttonForBack.titleLabel.text isEqualToString:@"Cancel"])
        {
            [buttonForBack setTitle:@"Back" forState:UIControlStateNormal];
            [buttonForBack removeTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
            [buttonForBack addTarget:self action:@selector(performBackNavigation) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self printFilesInFolderWithService:driveService folderId:file.identifier andName:file.title];
    }
    else
    {
        if ([file.fileExtension isEqualToString:@"pdf"]) {
            
            NSString *link;
            
            if (file.webContentLink){
                link=file.webContentLink;
            }
            else if(file.embedLink){
                link=file.embedLink;
            }
            else
            {
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"ERROR" message:@"File has no downloadable link" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
            }
            
            if (link) {
                //download and show the pdf
                if(link)
                {
                    NSLog(@"link : %@", link);
                    
                    
                    DirectoryCreationStatus  status= [self createFileDirectory:appDelegate.fileDirectory];
                    
                    NetworkRequestHandler *fileDownLoader=[[NetworkRequestHandler alloc]initWithBaseURLString:link
                                                                                              objectPathInURL:nil
                                                                                         dataDictionaryToPost:nil];
                    
                    fileDownLoader.timeOutInterval=100000.0;
                    NetworkRequestHandler * __weak newWeakFileDownLoader = fileDownLoader;
                    [newWeakFileDownLoader setCompletionHandler:^{
                        
                        if (status == kDirectoryCreationSuccess || status == kDirectoryExists)
                        {
                            NSString *dirPath = [self directoryPathForSavingFile:appDelegate.fileDirectory];
                            NSString *filePath = [dirPath stringByAppendingPathComponent:file.title];
                            
                            [self saveFileJSONData:newWeakFileDownLoader.responseData forFileName:filePath withCompletionHandler:^(BOOL successStatus) {
                                // Adding skip attribute to avoid data sinking in iCloud
                                [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:filePath]];
                                
                                [self showFileAtPath:filePath];
                            }];
                        }
                        else
                        {
                            NSLog(@"something went wrong. Please try again");
                        }
                    }];
                    
                    [newWeakFileDownLoader startDownload];
                    
                    [newWeakFileDownLoader setErrorHandler:^(NSError *fileJSONDownLoaderError)
                     {
                         NSLog(@"in error : %@", fileJSONDownLoaderError.localizedDescription);
                     }];
                    
                    [newWeakFileDownLoader setProgressReporter:^{
                        NSLog(@"file downloaded successfully with progress : %f", newWeakFileDownLoader.downloadProgressionFraction);
                    }];
                }
            }
        }
        else if([file.fileExtension isEqualToString:@"jpg"]||[file.fileExtension isEqualToString:@"jpeg"]||[file.fileExtension isEqualToString:@"png"]||[file.fileExtension isEqualToString:@"gif"]||[file.fileExtension isEqualToString:@"tiff"]||[file.fileExtension isEqualToString:@"bmp"]){
            
            //download the image and show it on view
            NSString *downloadUrl = file.downloadUrl;
            NSLog(@"\n\ngoogle drive file download url link = %@", downloadUrl);
            GTMHTTPFetcher *fetcher =
            [self.driveService.fetcherService fetcherWithURLString:downloadUrl];
            //async call to download the file data
            [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
                if (error == nil) {
                    //TODO: Do whatever you wnat to do with image
                } else {
                    NSLog(@"An error occurred: %@", error);
                }
            }];
        }
    }
}




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

-(void)saveFileJSONData:(NSData*)jsonData forFileName:(NSString*)fileName withCompletionHandler:(FileSavingCompletionHandler)completionHandler
{
    
    NSLog(@"file name : %@", fileName);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        
        NSError *error;
        BOOL fileSavingStatus = [jsonData writeToFile:fileName options:NSDataWritingAtomic error:&error];
        
        if (!error)
        {
            completionHandler(fileSavingStatus);
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"ERROR" message:@"File writing error" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            
        }
    });
    
    
    
}

-(NSString*)directoryPathForSavingFile:(NSString *)directoryName
{
    //NSString *directoryName = @"pdfFile";
    // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    // NSString *applicationDirectory = [paths objectAtIndex:0];
    
    NSString *applicationDirectory= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    applicationDirectory = [applicationDirectory stringByAppendingPathComponent:directoryName];
    return applicationDirectory;//[applicationDirectory stringByAppendingPathComponent:directoryName];
}

#pragma mark Method creating MoreApps/Images dirictory
-(DirectoryCreationStatus)createFileDirectory:(NSString *)directoryName
{
    
    NSString *applicationDirectory= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePathAndDirectory = [applicationDirectory stringByAppendingPathComponent:directoryName];
    
    BOOL directoryExist = [[NSFileManager defaultManager] fileExistsAtPath:filePathAndDirectory];
    
    if (!directoryExist)//directory is not found ,going to create a new one
    {
        
        NSError *error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error])
        {
#ifdef DEBUG_MODE
            NSLog(@"Directory creation failed at %@",filePathAndDirectory);
#endif
            return kDirectoryCreationFailed;
        }
        else
        {
#ifdef DEBUG_MODE
            NSLog(@"Directory creation successful at %@",filePathAndDirectory);
#endif
            
            return kDirectoryCreationSuccess;
        }
    }
    else
    {
#ifdef DEBUG_MODE
        NSLog(@"MoreAppsManager:Directory already exist at %@",filePathAndDirectory);
#endif
        return kDirectoryExists;
    }
    
    //default return type
    return kDirectoryCreationFailed;
}


-(void)showFileAtPath:(NSString *)path
{
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:path password:nil];
    
    BOOL fileExistsAtPath =  [[NSFileManager defaultManager] fileExistsAtPath:path];
    
    if (document!=nil)
    {
        ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
        readerViewController.delegate = self;
        
        readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:readerViewController animated:YES completion:nil];
    }
    else
    {
        NSLog(@"document is nil");
    }
}

- (void)dismissReaderViewController:(ReaderViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


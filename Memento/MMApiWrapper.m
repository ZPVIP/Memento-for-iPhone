//
//  MMApiWrapper.m
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMApiWrapper.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "MMApiLoader.h"

@implementation MMApiWrapper
- (void)handleImage: (NSDictionary *)item inTable: (UITableView *)table forImage: (UIImageView *)imageview {
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *docDirectory = [sysPaths objectAtIndex:0];
    
    //File path is slug
    NSString *slug = [item valueForKey:@"link"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", docDirectory, slug];    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];                
    if( fileExists ) {
        //Set image
        [imageview setImage:[UIImage imageWithContentsOfFile:filePath]];
    }
    else {
        //download file                
        dispatch_async( dispatch_get_main_queue(), ^{
            ASIHTTPRequest *request;
            request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://mementosapp.com/public/image/png/%@.png", slug]]];

            //Parallels ASIHTTPRequest#(void)requestStarted
            request.delegate = nil;
            [request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", slug]]];        
            
            // running synchronously on the main thread now -- call the handler
            NSLog(@"Downloading %@", slug);
            [request setCompletionBlock:^{
                NSLog(@"File Downloaded");
                //Reload data
                [table reloadData];
            }];
            [request setStartedBlock:^{
                NSLog(@"XFer started");
            }];
            [request startAsynchronous];
        });        
    }
}
- (void)uploadImageWithData:(NSData *)data to:(NSString *)slug {
    NSURL *url = [NSURL URLWithString:@"http://mneary.info:3008/api/upload/"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setData:data withFileName:[slug stringByAppendingString:@".png"] andContentType:@"image/png" forKey:@"photo"];    
    [request setDelegate:self];
    [request startAsynchronous];
}
- (NSURLConnection *)performPostWithParams: (NSString *)params to: (NSString *)path forDelegate: (MMMasterViewController *)delegate andReadData: (BOOL)read {
    NSURL *mneary = [[NSURL alloc] initWithString:path];
    NSMutableURLRequest *putJSON = [[NSMutableURLRequest alloc] initWithURL:mneary];
    
    
    [putJSON setHTTPMethod:@"POST"];
    [putJSON setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    MMApiLoader *mmal = [[MMApiLoader alloc] initWithMode:read?@"GET":@"PUT"];
    if( delegate ) {
        mmal.delegate = delegate;
        
        NSURLConnection *api_load = [[NSURLConnection alloc] initWithRequest:putJSON delegate:mmal];
        return api_load;
    }
    NSURLConnection *api_load = [[NSURLConnection alloc] initWithRequest:putJSON delegate:nil];
    return api_load;
}
- (void)writeUsername: (NSString *)username andPassword: (NSString *)password {
    //Save to plist
    NSDictionary *credits = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", nil];
    
    //Save locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"user_credits.plist"];
    [credits writeToFile:plistPath atomically:YES];
}
@end

//
//  MCFsTool.m
//
//  Created by Jesus Garcia on 3/5/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCFsTool.h"


@implementation MCFsTool

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(getDirectoriesAsJson:(NSString *)path
                                errorCallback:(RCTResponseSenderBlock)errorCallback
                                     callback:(RCTResponseSenderBlock)callback) {
    
    NSMutableArray *directories = [self getContentsOfDirectory:path];
    
    callback(@[directories]);
}
    



- (NSMutableArray *) getContentsOfDirectory:(NSString*)path {
   
       
    if (path == nil) {
        NSString *appUrl  = [[NSBundle mainBundle] bundlePath];
        path = [appUrl stringByAppendingString: @"/KEYGENMUSiC MusicPack"];
    }
    
   
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:path];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    
    NSArray *enumerator = [fileManager
                         contentsOfDirectoryAtURL: directoryUrl
                         includingPropertiesForKeys : keys
                         options : 0
                         error:nil
                        ];
    
    
    NSArray *pathSplit = [path componentsSeparatedByString:@"/"];
    NSString *x = [pathSplit objectAtIndex:[pathSplit count] -1],
             *strToRemove = [NSString stringWithFormat:@"%@ - ", x],
             *emptyStr = @"";
    
    
    
    NSMutableArray *pathDictionaries = [[NSMutableArray alloc] init];

    NSString *fileType = @"file",
             *dirType  = @"dir";

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        NSDictionary *jsonObj;
        
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error];
        BOOL isDirectoryBool = [isDirectory boolValue];
   
        if (isDirectoryBool) {
            jsonObj = @{
                @"name" : [url lastPathComponent],
                @"path" : [url path],
                @"type" : dirType
            };
        }
        else if (! isDirectoryBool) {
            NSString *niceName = [[url lastPathComponent] stringByReplacingOccurrencesOfString:strToRemove withString:emptyStr];
            
            jsonObj = @{
                @"name"     : [url lastPathComponent],
                @"niceName" : niceName,
                @"path"     : [url path],
                @"type"     : fileType
            };
            
        }
        
        [pathDictionaries addObject:jsonObj];

    }
    
//    NSError *jsonError;
//    NSData *jsonData = [NSJSONSerialization
//                        dataWithJSONObject:pathDictionaries
//                        options:NSJSONWritingPrettyPrinted
//                        error:&jsonError
//                    ];
//    
//    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//
//    return jsonDataString;
    return pathDictionaries;
}



@end

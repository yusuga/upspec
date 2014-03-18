//
//  main.m
//  upspec
//
//  Created by Yu Sugawara on 2014/03/18.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kGitPath = @"/usr/local/git/bin/git";

/* http://blog.objc.jp/?p=912 */
NSArray* commandResultsWithCmdPath(NSString* cmdPath ,NSArray* args, NSString *dirPath)
{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [[NSPipe alloc] init];
    
    task.launchPath = cmdPath;
    if (args) task.arguments = args;
    if (dirPath) task.currentDirectoryPath = dirPath;
    task.standardOutput = pipe;
    [task launch];
    
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSData *data = [handle  readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [string componentsSeparatedByString:@"\n"];
}

BOOL isGitError(NSArray* result)
{
    return [result.firstObject hasPrefix:@"fatal"];
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        BOOL deleteOldDir = NO;
        for (int i = 0; i < argc; i++) {
            const char *str = argv[i];
            if (strcmp(str, "-d") == 0) {
                deleteOldDir = YES;
            }
        }
        
        NSString *currentDirectoryPath;
        currentDirectoryPath = [[NSFileManager alloc] currentDirectoryPath];
        NSLog(@"current directory path = %@", currentDirectoryPath);
        NSString *repoName = [currentDirectoryPath lastPathComponent];
        
        /* [Current directory] git tag <incrementTag> */
        
        NSArray *tags = commandResultsWithCmdPath(kGitPath, @[@"tag"], currentDirectoryPath);
        
        NSMutableCharacterSet *versionSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [versionSet addCharactersInString:@"."];
        tags = [tags sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            if (![versionSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:obj1]]) {
                return NSOrderedDescending;
            }
            if (![versionSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:obj2]]) {
                return NSOrderedAscending;
            }
            return [obj2 compare:obj1 options:NSNumericSearch];
        }];
        
        NSString *recentTag = [tags firstObject];
        NSLog(@"recent tag = %@", recentTag);
        
        NSError *error = nil;
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+.[0-9]+.([0-9]+)"
                                                                             options:0
                                                                               error:&error];
        NSTextCheckingResult *regResult = [reg firstMatchInString:recentTag options:0 range:NSMakeRange(0, recentTag.length)];
        if ([regResult numberOfRanges] <= 1 || [regResult rangeAtIndex:1].length == 0) {
            NSLog(@"Error: Invalid tag. recentTag = %@", recentTag);
            return 0;
        }
        NSRange range = [regResult rangeAtIndex:1];
        NSString *verEnd = [recentTag substringWithRange:range];
        NSString *incrementTag = [recentTag stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@", @(verEnd.integerValue + 1)]];
        NSLog(@"Increment tag = %@", incrementTag);
        
        NSArray *addTagResult = commandResultsWithCmdPath(kGitPath, @[@"tag", incrementTag], currentDirectoryPath);
        if (isGitError(addTagResult)) {
            NSLog(@"Error: %@", addTagResult);
            return 0;
        }
        
        /* [Current directory] git push origin --tags */
        
        commandResultsWithCmdPath(kGitPath, @[@"push", @"origin", @"--tags"], currentDirectoryPath);
        
        /* [podspec] cp -r <recetTag-dir> <incrementTag-dir> */
        
        NSString *podspecRootPath = [currentDirectoryPath stringByDeletingLastPathComponent];
        podspecRootPath = [podspecRootPath stringByAppendingPathComponent:@"podspec"];
        NSString *podspecPath = [podspecRootPath stringByAppendingPathComponent:repoName];
        NSLog(@"podspec path = %@", podspecPath);
        NSString *recentPodspecDir = [NSString stringWithFormat:@"%@/%@", podspecPath, recentTag];
        NSLog(@"recent podspec directory = %@", recentPodspecDir);
        NSString *newPodspecDir = [NSString stringWithFormat:@"%@/%@", podspecPath, incrementTag];
        NSLog(@"new podspec directory = %@", newPodspecDir);
        commandResultsWithCmdPath(@"/bin/cp",
                                  @[@"-r",
                                    recentTag,
                                    incrementTag
                                    ],
                                  podspecPath);
        
        NSString *podspecFilePath = [NSString stringWithFormat:@"%@/%@.podspec", newPodspecDir, repoName];
        podspecFilePath = [podspecFilePath stringByExpandingTildeInPath];
        NSLog(@"podspec file path = %@", podspecFilePath);
        
        NSString *podspec = [NSString stringWithContentsOfFile:podspecFilePath
                                                      encoding:NSASCIIStringEncoding
                                                         error:&error];
        
        if (error) {
            NSLog(@"Error: %@", error);
            return 0;
        }
        
        error = nil;
        reg = [NSRegularExpression regularExpressionWithPattern:@"s.version[ ]*=[ ]*[']+([0-9.]+)[']+"
                                                        options:0
                                                          error:&error];
        
        if (error) {
            NSLog(@"Error: %@", error);
            return 0;
        }
        regResult = [reg firstMatchInString:podspec options:0 range:NSMakeRange(0, podspec.length)];
        if ([regResult numberOfRanges] <= 1 || [regResult rangeAtIndex:1].length == 0) {
            NSLog(@"Error: Invalid tag. recentTag = %@, podspec = %@", recentTag, podspec);
            return 0;
        }
        NSLog(@"podspec old verstion = %@", [podspec substringWithRange:[regResult rangeAtIndex:1]]);
        podspec = [podspec stringByReplacingCharactersInRange:[regResult rangeAtIndex:1] withString:incrementTag];
        error = nil;
        if (![podspec writeToFile:podspecFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"Error: failure write of podspec");
            return 0;
        }
        NSLog(@"Success: write %@.podspec", repoName);
        
        /* [podspec] delete old directory */
        
        if (deleteOldDir) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if ([fileManager removeItemAtPath:recentPodspecDir error:NULL]) {
                NSLog(@"Success: remove %@", recentPodspecDir);
            } else {
                NSLog(@"Failure: remove %@", recentPodspecDir);
                return 0;
            }
        }
        
        /* [podspec] git add <new directory and file> */
        
        commandResultsWithCmdPath(kGitPath,
                                  @[@"add",
                                    [NSString stringWithFormat:@"%@/%@", repoName, incrementTag]],
                                  podspecRootPath);
        
        /* [podspec] git commit */
        
        commandResultsWithCmdPath(kGitPath,
                                  @[@"commit",
                                    @"-m",
                                    [NSString stringWithFormat:@"Update %@ %@", repoName, incrementTag],
                                    @"-a"],
                                  podspecRootPath);
        
        /* [podspec] git push */
        
        commandResultsWithCmdPath(kGitPath, @[@"push", @"origin", @"master"], podspecRootPath);
        
        NSLog(@"finish update podspec");        
    }
    return 0;
}


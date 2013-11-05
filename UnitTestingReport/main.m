//
//  main.m
//  UnitTestingReport
//
//  Created by sagles on 13-10-26.
//  Copyright (c) 2013年 sagles. All rights reserved.
//

/*
 1.文本存放路径，不包含文件名
 
 */

#import <Foundation/Foundation.h>

#define TestFileName "testSuite.txt"
#define ResultFileName "executed.txt"

static char command[1024];
static BOOL isHTMLOutput = YES;
static int kTotalUnitTest = 0;

/**
 *  根据传入地址获取完整地址
 *
 *  @param c_path 传入的地址
 *
 *  @return 完整的地址
 */
const char *fullPathWithPath(const char *c_path);

/**
 *  <#Description#>
 *
 *  @param str <#str description#>
 *
 *  @return <#return value description#>
 */
const char *getHTMLChar(const char *str);

void unitTestingLog(NSString *testName, NSString *className, NSString * function, NSString *status);

int main(int argc, const char * argv[])
{

    @autoreleasepool
    {
        if (argc < 2){
            NSLog(@"\r\n/************************************************/\r\n"
                  "\t\tUsage: %@ check_dir_directorys"
                  "\r\n/************************************************/"
                  , [[NSString stringWithUTF8String:argv[0]] lastPathComponent]);
            
            return EXIT_FAILURE;
        }
        
        NSString *mainPath = [[NSBundle mainBundle] bundlePath];
        NSLog(@"%@",mainPath);
        
        NSString *sourceDir = [NSString stringWithUTF8String:fullPathWithPath(argv[1])];
        
        NSMutableArray *testsArray = [NSMutableArray array];

        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:sourceDir ];
        NSString *filePath = nil;
        while ((filePath = [enumerator nextObject])) {
            
            if ([filePath rangeOfString:@"Tests"].location == NSNotFound ||
                [filePath rangeOfString:@"xcscheme"].location == NSNotFound) continue;
            
            NSString *schemeName = [[filePath lastPathComponent] stringByDeletingPathExtension];
            if ([schemeName hasSuffix:@"Tests"]) 
            {
                [testsArray addObject:schemeName];
            }
            
        }
        
        NSLog(@"%@",testsArray);
        
        if (isHTMLOutput)
        {
            printf("<style type=\"text/css\">#tbl{border-left:solid 1px #333; border-top:solid 1px #333;}\n\
                   #tbl td, #tbl th{border-right:solid 1px #333; border-bottom:solid 1px #333; padding:0 5px;}\
                   </style>\n");
            printf("<table id=\"tbl\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" align=\"center\" \
                   width=\"98%%\">\n");
            printf("<tr><th bgcolor='#424AFB'><font size=\"4\" color='#ffffff'>%s</font></th> "
                   "<th bgcolor='#424AFB'><font size=\"4\" color='#ffffff'>%s</font></th> "
                   "<th bgcolor='#424AFB'><font size=\"4\" color='#ffffff'>%s</font></th> "
                   "<th bgcolor='#424AFB'><font size=\"4\" color='#ffffff'>%s</font></th></tr>\n",
                   getHTMLChar("Test"), getHTMLChar("Class"), getHTMLChar("Function"), getHTMLChar("Status"));
        }
        
        BOOL isOutputExist = argc == 3;
        
        
        for (NSString *scheme in testsArray)
        {
            const char *output = isOutputExist ? [[NSString stringWithFormat:@"%s/test.txt",fullPathWithPath(argv[2])] UTF8String]
            : [[NSString stringWithFormat:@"%s/test.txt",fullPathWithPath(argv[1])] UTF8String];
            sprintf(command, "cd %s "
                    "\n"
                    "xcodebuild -scheme %s "
                    "-configuration Debug "
                    "-destination OS=7.0,name=\"iPhone Retina (4-inch)\" "
                    "clean test 1> %s",
                    fullPathWithPath(argv[1]),
                    [scheme UTF8String],
                    output);
            
            int rs = system(command);
            
            NSLog(@"run command : %s,result : %i",command,rs);
            
            rs = 0;
            sprintf(command,
                    "grep -n '^Test' %s 1> \"%s/%s\" \n"
                    "grep -n '^Executed' %s 1> \"%s/%s\" \n",
                    output,
                    fullPathWithPath(argv[1]),
                    TestFileName,
                    output,
                    fullPathWithPath(argv[1]),
                    ResultFileName);
            
            rs = system(command);
            
            NSLog(@"run command : %s,result : %i",command,rs);
            
            if (rs != 0)
            {
                if (isHTMLOutput)
                    printf("</table><br /><br />\n");
                
                //移除中间产物
                sprintf(command, "rm %s/*.txt",argv[1]);
                system(command);
                
                return EXIT_FAILURE;
            }
            
            
            //打印单元测试过程
            NSError *error = nil;
            NSString *filePath = [NSString stringWithFormat:@"%s/%s",fullPathWithPath(argv[1]),TestFileName];
            
            NSString *fileContent = [[NSString alloc] initWithContentsOfFile:filePath
                                                                    encoding:NSUTF8StringEncoding
                                                                       error:&error];
            if (error != nil){
                NSLog(@"open file occurred, error:\r%@", error);
                return EXIT_FAILURE;
            }
            
            NSArray *contentArray = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                                                       newlineCharacterSet]];
            NSString *testName = nil;
            NSString *className = nil;
            NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ."];
            for (NSString *content in contentArray)
            {
                //带路径就是开头或者结尾
                if ([content rangeOfString:@"/"].location != NSNotFound)
                {
                    if ([content rangeOfString:@"started"].location != NSNotFound)
                    {
                        testName = [[[content componentsSeparatedByString:@"'"] objectAtIndex:1] lastPathComponent];
                    }
                    else if ([content rangeOfString:@"finished"].location != NSNotFound)
                    {
                        testName = nil;
                    }
                    continue;
                }
                
                if (!testName) continue;
                
                if ([content rangeOfString:@"Suite"].location != NSNotFound)
                {
                    className = [[content componentsSeparatedByString:@"'"] objectAtIndex:1];
                    continue;
                }
                
                if ([content rangeOfString:@"Case"].location != NSNotFound &&
                    [content rangeOfString:@"("].location != NSNotFound)
                {
                    NSString *function = [[[content componentsSeparatedByString:@"'"] objectAtIndex:1] substringFromIndex:1];
                    NSString *status = [[content componentsSeparatedByString:@"'"] objectAtIndex:2];
                    status = [status stringByTrimmingCharactersInSet:characterSet];
                    
                    unitTestingLog(testName, className, function, status);
                }
            }
            
            //打印单元测试结果
            filePath = [NSString stringWithFormat:@"%s/%s",fullPathWithPath(argv[1]),ResultFileName];
            fileContent = [[NSString alloc] initWithContentsOfFile:filePath
                                                          encoding:NSUTF8StringEncoding
                                                             error:&error];
            if (error != nil){
                NSLog(@"open file occurred, error:\r%@", error);
                return EXIT_FAILURE;
            }
            contentArray = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                                              newlineCharacterSet]];
            
            int totalFail = 0;
            const char *time;
            for (NSString *content in contentArray)
            {
                if ([contentArray indexOfObject:content] == contentArray.count-2)
                {
                    NSArray *tempArray = [content componentsSeparatedByString:@" "];
                    kTotalUnitTest = [tempArray[1] intValue];
                    totalFail = [tempArray[4] intValue];
                    NSString *temp = [tempArray[10] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"()"]];
                    time = [temp UTF8String];
                }
            }
            int totalSuccess = kTotalUnitTest - totalFail;
            
            const char *color =  totalFail > 0 ? "#ff8814" : "#7ADB5B";
            
            const char *totalOutput = isHTMLOutput ?
            "<tr><td colspan=4 bgcolor='%s'>"
            "<font size=\"4\" color='#ffffff'>%s已执行%i个单元测试，测试成功%i个，失败%i个，共使用%s秒</font></td></tr>"
            : "%s已执行%i个单元测试，测试成功%i个，失败%i个，共使用%s秒";
            
            if (isHTMLOutput) {
                totalOutput = getHTMLChar(totalOutput);
            }
            
            printf(totalOutput,
                   color,
                   [scheme UTF8String],
                   kTotalUnitTest,
                   totalSuccess,
                   totalFail,
                   time);
            
            //移除中间产物
            sprintf(command, "rm %s/*.txt",argv[1]);
            system(command);
        }
        if (isHTMLOutput)
            printf("</table><br /><br />\n");
        
    }
    return 0;
}

const char *fullPathWithPath(const char *c_path)
{
    NSString *path = [NSString stringWithUTF8String:c_path];
    
    path = [path stringByStandardizingPath];
    
    return [path UTF8String];
}

const char *getHTMLChar(const char *str)
{
    NSString *htmlString = [NSString stringWithUTF8String:str];
    NSMutableString *resultString = [NSMutableString string];
    for (NSUInteger i=0; i<htmlString.length; i++) {
        unichar c = [htmlString characterAtIndex:i];
        if (c>255)
            [resultString appendFormat:@"&#%u;", c];
        else
            [resultString appendString:[htmlString substringWithRange:NSMakeRange(i, 1)]];
    }
    return [resultString UTF8String];
}

void unitTestingLog(NSString *testName, NSString *className, NSString * function, NSString *status)
{
    
    BOOL isFail = [status rangeOfString:@"failed"].location != NSNotFound;
    
    const char *outputString = NULL;
    if (outputString == NULL)
        outputString = isHTMLOutput ? isFail ?
        "<tr><td bgcolor='#ff0000'><font color='#ffffff'>%s</font></td> "
        "<td bgcolor='#ff0000'><font color='#ffffff'>%s</font></td> "
        "<td bgcolor='#ff0000'><font color='#ffffff'>%s</font></td> "
        "<td bgcolor='#ff0000'><font color='#ffffff'>%s</font></td></tr>\n"
        : "<tr><td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td></tr>\n"
        : "【%s】[%s]%s<%s>\n";
    
    printf(outputString,[testName UTF8String],[className UTF8String],[function UTF8String],[status UTF8String]);
}
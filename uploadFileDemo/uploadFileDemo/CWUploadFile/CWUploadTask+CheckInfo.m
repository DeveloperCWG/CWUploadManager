//
//  CWUploadTask+CheckInfo.m
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/9.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "CWUploadTask+CheckInfo.h"
#import "CWFileStreamSeparation.h"

@implementation CWUploadTask (CheckInfo)

- (void)checkParamFromServer:(CWFileStreamSeparation *_Nonnull)fileStream
              paramCallback:(void(^ _Nullable)(NSString *_Nonnull chunkNumName,NSDictionary *_Nullable param))paramBlock
{
    NSString *uploadFileInfoUrl=[NSString stringWithFormat:@"%@/upload/checkFileChunk",CURRENT_API];
    NSURL *url = [NSURL URLWithString:uploadFileInfoUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *args = [NSString stringWithFormat:@"bizId=%@&fileName=%@&saveName=%@&chunks=%@",fileStream.bizId,fileStream.fileName,fileStream.md5String,[NSString stringWithFormat:@"%zd",fileStream.streamFragments.count]];
    NSLog(@"%@",args);
    request.HTTPMethod = @"POST";//设置请求类型
    [request setValue:@"v1" forHTTPHeaderField:@"api_version"];
    request.HTTPBody = [args dataUsingEncoding:NSUTF8StringEncoding];//设置参数
    NSURLSession *session = [NSURLSession sharedSession];
    //发送请求
    NSURLSessionDataTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            //解析得到的数据
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if ([dict[@"code"] isEqualToString:@"500"]) {
                NSLog(@"%@",dict[@"desc"]);
                return;
            }
            NSMutableDictionary *tmpParam = [NSMutableDictionary dictionary];
            [tmpParam setDictionary:dict[@"data"]];
            NSLog(@"%@",tmpParam);
            paramBlock(@"chunk",tmpParam);
        }
    }];
    [postTask resume];
}

@end

//
//  CWUploadTask+CheckInfo.h
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/9.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "CWUploadTask.h"

@interface CWUploadTask (CheckInfo)

- (void)checkParamFromServer:(CWFileStreamSeparation *_Nonnull)fileStream
              paramCallback:(void(^ _Nullable)(NSString *_Nonnull chunkNumName,NSDictionary *_Nullable param))paramBlock;
@end

//
//  CWFileStreamSeparation.m
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/9.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "CWFileStreamSeparation.h"
#import "CWFileManager.h"
#import <CommonCrypto/CommonDigest.h>

#pragma mark - CWFileStreamSeparation
#define FileHashDefaultChunkSizeForReadingData 1024*8

@interface CWFileStreamSeparation ()
@property (nonatomic, copy) NSString                          *fileName;
@property (nonatomic, assign) NSUInteger                      fileSize;
//@property (nonatomic, strong) NSArray<CWStreamFragment*>          *streamFragments;
@property (nonatomic, strong) NSFileHandle                    *readFileHandle;
@property (nonatomic, strong) NSFileHandle                    *writeFileHandle;
@property (nonatomic, assign) BOOL                            isReadOperation;
@property (nonatomic,assign)double progressRate;
@property (nonatomic,assign)NSInteger uploadDateSize;
@end

@implementation CWFileStreamSeparation

+ (NSString *)fileKey {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), result );
    CFRelease(uuid);
    CFRelease(cfstring);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08lx",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15],
            (unsigned long)(arc4random() % NSUIntegerMax)];
}

+(NSString*)fileKeyMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:[self fileName] forKey:@"fileName"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fileSize]] forKey:@"fileSize"];
    [aCoder encodeObject:[NSNumber numberWithInteger:[self fileStatus]] forKey:@"fileStatus"];
    [aCoder encodeObject:[self filePath] forKey:@"filePath"];
    [aCoder encodeObject:[self md5String] forKey:@"md5String"];
    [aCoder encodeObject:[self streamFragments] forKey:@"streamFragments"];
    [aCoder encodeObject:[self bizId] forKey:@"bizId"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self uploadDateSize]] forKey:@"uploadDateSize"];
    [aCoder encodeObject:[NSNumber numberWithDouble:[self progressRate]] forKey:@"progressRate"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFileName:[aDecoder decodeObjectForKey:@"fileName"]];
        [self setFileStatus:[[aDecoder decodeObjectForKey:@"fileStatus"] intValue]];
        [self setFileSize:[[aDecoder decodeObjectForKey:@"fileSize"] unsignedIntegerValue]];
        [self setFilePath:[aDecoder decodeObjectForKey:@"filePath"]];
        [self setMd5String:[aDecoder decodeObjectForKey:@"md5String"]];
        [self setStreamFragments:[aDecoder decodeObjectForKey:@"streamFragments"]];
        [self setBizId:[aDecoder decodeObjectForKey:@"bizId"]];
        [self setProgressRate:[[aDecoder decodeObjectForKey:@"progressRate"] doubleValue]];
        [self setUploadDateSize:[[aDecoder decodeObjectForKey:@"uploadDateSize"] unsignedIntegerValue]];
    }
    
    return self;
}

-(void)setFileStatus:(CWUploadStatus)fileStatus
{
    _fileStatus = fileStatus;
    for (NSInteger num = 0; num<_streamFragments.count; num++) {
        CWStreamFragment *ft = _streamFragments[num];
        if (num ==_streamFragments.count-1) {
            _progressRate = (num+1.0)/_streamFragments.count;
            _uploadDateSize = self.fileSize;
            break;
        }
        if (!ft.fragmentStatus) {
            _progressRate = (num+1.0)/_streamFragments.count;
            _uploadDateSize = CWStreamFragmentMaxSize * (num+1);
            break;
        }
    }
}

- (BOOL)getFileInfoAtPath:(NSString*)path {
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) {
        NSLog(@"文件不存在：%@",path);
        return NO;
    }
    
    self.filePath = path;
    
    NSDictionary *attr =[fileMgr attributesOfItemAtPath:path error:nil];
    self.fileSize = attr.fileSize;
    
    self.md5String = [CWFileStreamSeparation fileKeyMD5WithPath:path];
    
    self.bizId=[[NSUUID UUID] UUIDString];
    
    self.uploadDateSize = 0;
    self.progressRate = 0.00;

    NSString *fileName = [path lastPathComponent];
    self.fileName = fileName;
    
    self.fileStatus = CWUploadStatusWaiting;
    
    return YES;
}


// 若为读取文件数据，打开一个已存在的文件。
// 若为写入文件数据，如果文件不存在，会创建的新的空文件。
- (instancetype)initFileOperationAtPath:(NSString*)path forReadOperation:(BOOL)isReadOperation {
    
    if (self = [super init]) {
        self.isReadOperation = isReadOperation;
        if (_isReadOperation) {
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
            [self cutFileForFragments];
        } else {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if (![fileMgr fileExistsAtPath:path]) {
                [fileMgr createFileAtPath:path contents:nil attributes:nil];
            }
            
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            
            self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        }
    }
    
    return self;
}

//- (instancetype)

#pragma mark - 读操作
//切分文件片段
- (void)cutFileForFragments {
    
    NSUInteger offset = CWStreamFragmentMaxSize;
    // 块数
    NSUInteger chunks = (_fileSize%offset==0)?(_fileSize/offset):(_fileSize/(offset) + 1);
    
    NSMutableArray<CWStreamFragment *> *fragments = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSUInteger i = 0; i < chunks; i ++) {
        
        CWStreamFragment *fFragment = [[CWStreamFragment alloc] init];
        fFragment.fragmentStatus = NO;
        fFragment.fragmentId = [[self class] fileKey];
        fFragment.fragementOffset = i * offset;
        
        if (i != chunks - 1) {
            fFragment.fragmentSize = offset;
        } else {
            fFragment.fragmentSize = _fileSize - fFragment.fragementOffset;
        }
        
        [fragments addObject:fFragment];
    }
    
    self.streamFragments = fragments;
}

//通过分片信息读取对应的片数据
- (NSData*)readDateOfFragment:(CWStreamFragment*)fragment {
    if (self.readFileHandle==nil) {
        self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:_filePath];
    }

    if (fragment) {
        [self seekToFileOffset:fragment.fragementOffset];
        return [_readFileHandle readDataOfLength:fragment.fragmentSize];
    }
    [self closeFile];
    return nil;
}

- (NSData*)readDataOfLength:(NSUInteger)bytes {
    return [_readFileHandle readDataOfLength:bytes];
}


- (NSData*)readDataToEndOfFile {
    return [_readFileHandle readDataToEndOfFile];
}

#pragma mark - 写操作

// 写入文件数据
- (void)writeData:(NSData *)data {
    [_writeFileHandle writeData:data];
}

#pragma mark - common
// 获取当前偏移量
- (NSUInteger)offsetInFile{
    if (_isReadOperation) {
        return [_readFileHandle offsetInFile];
    }
    
    return [_writeFileHandle offsetInFile];
}

// 设置偏移量,仅对读取设置
- (void)seekToFileOffset:(NSUInteger)offset {
    [_readFileHandle seekToFileOffset:offset];
}

// 将偏移量定位到文件的末尾
- (NSUInteger)seekToEndOfFile{
    if (_isReadOperation) {
        return (NSUInteger)[_readFileHandle seekToEndOfFile];
    }
    
    return [_writeFileHandle seekToEndOfFile];
}

// 关闭文件
- (void)closeFile {
    if (_isReadOperation) {
        [_readFileHandle closeFile];
    } else {
        [_writeFileHandle closeFile];
    }
}

//归档
+ (void)archerTheDictionary:(NSDictionary *)dict file:(NSString *)path{
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    BOOL finish = [data writeToFile:path atomically:YES];
    if (finish) NSLog(@"归档成功");
    
}

//解档
+ (NSMutableDictionary *)unArcherThePlist:(NSString *)path{
    NSMutableDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    return dic;
}

@end




@implementation CWStreamFragment

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:[self fragmentId] forKey:@"fragmentId"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentSize]] forKey:@"fragmentSize"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragementOffset]] forKey:@"fragementOffset"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentStatus]] forKey:@"fragmentStatus"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFragmentId:[aDecoder decodeObjectForKey:@"fragmentId"]];
        [self setFragmentSize:[[aDecoder decodeObjectForKey:@"fragmentSize"] unsignedIntegerValue]];
        [self setFragementOffset:[[aDecoder decodeObjectForKey:@"fragementOffset"] unsignedIntegerValue]];
        [self setFragmentStatus:[[aDecoder decodeObjectForKey:@"fragmentStatus"] boolValue]];
    }
    
    return self;
}

@end

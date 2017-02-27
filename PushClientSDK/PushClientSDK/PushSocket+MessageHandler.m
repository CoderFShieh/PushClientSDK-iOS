//
//  PushSocket+MessageHandler.m
//  PushClientSDK
//
//  Created by jeasonyoung on 2017/2/26.
//  Copyright © 2017年 Murphy. All rights reserved.
//

#import "PushSocket+MessageHandler.h"
#import "PushSocket+Timer.h"

//实现
@implementation PushSocket (MessageHandler)

#pragma mark -- 接收反馈数据处理。
-(void)receiveAckHandler:(AckModel *)ack{
    if(ack.result == AckModelResultSuccess){
        NSLog(@"socket发送(%ld)请求反馈成功!", ack.type);
        if(ack.type == PushSocketMessageTypeConnack){//判断是否为连接成功应答
            NSLog(@"socket客户端准备开启心跳处理...");
            [self startPingHandler];
        }
        return;
    }
    NSLog(@"socket发送(%ld)请求失败(%ld)=>%@", ack.type, ack.result, ack.msg);
    [self stop];//停止服务
    [self throwsErrorWithMessageType:ack.type andMessage:ack.msg];
}

#pragma mark -- 接收心跳应答处理
-(void)receivePingAckHandler:(PingResponseModel *)pingAck{
    NSLog(@"socket-心跳反馈处理=>%@", pingAck);
    if(!pingAck) return;
    if(pingAck.heartRate > 0 && self.getConfig && self.getConfig.socket){
        self.getConfig.socket.rate = pingAck.heartRate;
    }
    if(pingAck.afterConnect > 0 && self.getConfig && self.getConfig.socket){
        self.getConfig.socket.reconnect = pingAck.afterConnect;
    }
}

#pragma mark -- 接收推送消息数据处理
-(void)receivePublishHandler:(PublishModel *)data{
    if(!data){
        [self throwsErrorWithMessageType:PushSocketMessageTypePublish andMessage:@"推送消息解析失败!"];
        return;
    }
    if(!self.getEncoder){
        [self throwsErrorWithMessageType:PushSocketMessageTypePublish andMessage:@"获取消息编码器失败!"];
        return;
    }
    //发送推送消息到达请求消息
    __weak typeof(self) wSelf = self;
    [self.getEncoder encoderPublishAckRequestWithConfig:self.getConfig andPushId:data.pushId handler:^(NSData *buf) {
        [wSelf sendRequestWithData:buf];
    }];
    //推送消息抛出处理
    if(self.delegate && [self.delegate respondsToSelector:@selector(pushSocket:withPublish:)]){
        [self.delegate pushSocket:self withPublish:data];
    }
}

@end

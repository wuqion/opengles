//
//  ViewController.m
//  openGL
//
//  Created by 联创—王增辉 on 2019/4/16.
//  Copyright © 2019年 lcWorld. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>

//把x转换成NSString
#define zhuangma(x) @#x
//顶点着色器(就是一段字符串)
NSString * vartex = zhuangma(
    attribute vec4 vPosition;
    void main() {
     //设置最终坐标
    gl_Position = vPosition;
   }
);
//元着色器
NSString * fragment = zhuangma(
    void main() {
    //该片元最终颜色值
        gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
    }
);
//三个点的数组(x,y,z)
const GLfloat vertices[] = {
    -1, -1, 0,   //左下
    1,  -1, 0,   //右下
    -1, 1,  0   //左上
};

@interface ViewController ()


@end

@implementation ViewController
{
    EAGLContext * _eaglContext;//使用指定版本的OpenGL ES呈现API初始化并返回新分配的呈现上下文。
    CAEAGLLayer * _eaglLayer;//支持在iOS和tvOS应用程序中绘制OpenGL内容的层。
    GLuint _renderBuffer;//渲染缓存
    GLuint _frameBuffer; //位置大小缓存
}
- (void)viewDidLoad {
    [super viewDidLoad];

    //使用指定版本的OpenGL ES呈现API初始化并返回新分配的呈现上下文。
    _eaglContext = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES2)];
    //设置_eaglContext为当前上下文
    [EAGLContext setCurrentContext:_eaglContext];
    
    
    //支持在iOS和tvOS应用程序中绘制OpenGL内容的层。
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = self.view.bounds;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;//接收机的不透明度。可以做成动画。
    //kEAGLDrawablePropertyRetainedBacking:绘制后是否保留
    //kEAGLDrawablePropertyColorFormat    :指定可绘制表面的内部颜色缓冲区格式的键
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:_eaglLayer];
    
//  清除缓存
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
    }
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
// 生成framebuffer对象名称
    glGenFramebuffers(1, &_frameBuffer);
// 绑定一个命名的framebuffer对象
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
// 将renderbuffer对象附加到framebuffer对象
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
//附加EAGLDrawable作为绑定到<target>的OpenGL ES renderbuffer对象的存储
//应该是_eaglLayer根据GL_RENDERBUFFER的数据显示
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];

//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    
    //创建顶点着色器
    GLuint vartexShader = [self createShader:vartex type:GL_VERTEX_SHADER];
    //创建片元着色器
    GLuint fragmentShader = [self createShader:fragment type:GL_FRAGMENT_SHADER];
    
    //创建一个空的程序对象，并返回一个非零值，通过该值可以引用该对象
    GLuint program = glCreateProgram();
    
    //将着色器对象附加到程序对象中
    glAttachShader(program, vartexShader);
    glAttachShader(program, fragmentShader);
    
    //成功地链接程序对象
    glLinkProgram(program);
    
    GLint lineSuccess;
    //返回特定程序对象的参数值
    //GL_LINK_STATUS:如果程序上的最后一个链接操作成功，则返回GL_TRUE，否则返回GL_FALSE。
    glGetProgramiv(program, GL_LINK_STATUS, &lineSuccess);
    if(lineSuccess == GL_FALSE){
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    //将程序指定的程序对象作为当前呈现状态的一部分安装
    glUseProgram(program);
    //查找获取顶点着色器中的位置句柄
    GLuint mPosition = glGetAttribLocation(program, "vPosition");
    //查找获取片元着色器中的颜色句柄
//    GLuint mColor = glGetUniformLocation(program, "vColor");
     //启用指向三角形顶点数据的句柄
    glEnableVertexAttribArray(mPosition);
    //绑定三角形的坐标数据
    glVertexAttribPointer(mPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    //绘制三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    //请求本机窗口系统显示绑定到<target>的OpenGL ES呈现缓冲区
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    NSLog(@"--");
}
        
#pragma mark - 创建着色器
- (GLuint)createShader:(NSString *)shaderString type:(GLenum) type
{
    const char * shaderUTF8 = [shaderString UTF8String];
    GLint shaderlength      = (GLint)[shaderString length];
    //创建着色器
    //GL_VERTEX_SHADER :顶点着色器
    //GL_FRAGMENT_SHADER :片元着色器
    GLuint shaderHandle     = glCreateShader(type);
    //把这个着色器源码附加到着色器对象
    //第二参数指定了源码中有多少个字符串,这里只有一个
    glShaderSource(shaderHandle, 1, &shaderUTF8, &shaderlength);
    //编译着色器
    glCompileShader(shaderHandle);
    //接收参数(编译状态)
    GLint compileSuccess;
    //glGetShaderiv这个函数是从着色器对象返回一个参数
    //GL_COMPILE_STATUS:表示返回编译状态
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    //GL_FALSE:编译失败的标记
    if(compileSuccess == GL_FALSE){
        GLchar infolog[256];
        //返回着色器对象的信息日志
        glGetShaderInfoLog(shaderHandle, sizeof(infolog), 0, &infolog[0]);
        NSString *messageString = [NSString stringWithUTF8String:infolog];
        NSLog(@"%@", messageString);
        exit(1);
    }
    //shaderHandle
    //到此顶点着色器建立好了
    return shaderHandle;
}

@end

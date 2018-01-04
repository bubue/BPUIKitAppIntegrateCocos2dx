# UIKitAppWithCocos2dx

[中文介绍](#)
An example of a traditional UIKit App integration cocos2dx. cocos2dx is the latest version of 3.15.1.

Most of the tutorials that can be found online are mostly integrating UIKit with the cocos2dx project template and lacking the integration of cocos2dx with a traditional UIKit App project that has been maintained for a long time. And the searchable tutorial is also based on the 2.x version, and now cocos2dx has been upgraded to 3.15.1.

## integration

1. In the official website to download the latest cocos2dx Source: [http://www.cocos2d-x.org/download]

2. Extract after downloading, `/ Users / [username] / Downloads / cocos2d-x-3.15.1 / tools / cocos2d-console / bin / cocos`. An official template provided at the console can be generated. The command is `cocos new -l cpp`

3. But here we need to integrate cocos2dx into our legacy project. In the UIKit project to create a directory for storing cocos2dx related source files. Here we only need `build`,` coocs`, `extensions`,` external`, `plugin` These are the source code for directories that are copied into this directory.

4. Next, open our project. Drag `build` under` cocos2d_libs.xcodeproj` into our project.

5. Add `libcocos2d iOS.a`,` GameController.framework`, `OpenAL.framework` in` Linked Frameworks and Libraries`.

6. Note that, if the name of the AppDelegate UIKit project if the default needs to be modified, otherwise it will conflict with the cocos2dx need to modify the name.

7. In the need to use cocos2dx file need to modify `.m` file` .mm` file, `# import" cocos2d.h "`.

Next, edit the project, if there is error, the header file is not found. You need to add a path to `Header search paths`, such as` $ (SRCROOT) / [project name] / [coos2dx depository] / cocos2d-x-3.15.1`. Note: Do not add * path, otherwise it will have a lot of problems.

9. If the error file is in android or other platform directory, you can directly delete this directory, will not be affected.

10. Finally compiled successfully.

## Run Mobile Tour

```

CGFloat width = self.view.bounds.size.width> self.view.bounds.size.height? Self.view.bounds.size.width: self.view.bounds.size.height;

CGFloat height = self.view.bounds.size.width <self.view.bounds.size.height? Self.view.bounds.size.width: self.view.bounds.size.height;

eaglView = [CCEAGLView viewWithFrame: CGRectMake (0, 0, width, height)
pixelFormat: kEAGLColorFormatRGBA8
depthFormat: GL_DEPTH_COMPONENT16
preserveBackbuffer: NO
sharegroup: nil
multiSampling: NO
numberOfSamples: 0];

glClearColor (255, 255, 255, 1);
eaglView.opaque = NO;
[self.view addSubview: eaglView];
eaglView.backgroundColor = [UIColor whiteColor];

cocos2d :: Application * app = cocos2d :: Application :: getInstance ();
app-> initGLContextAttrs ();
cocos2d :: GLViewImpl :: convertAttrs ();
cocos2d :: GLView * glview = cocos2d :: GLViewImpl :: createWithEAGLView ((__bridge void *) eaglView);
cocos2d :: Director * pDirector = cocos2d :: Director :: getInstance ();
pDirector-> setOpenGLView (glview);
pDirector-> setClearColor (cocos2d :: Color4F :: WHITE);
app-> run ();

```

# UIKitAppWithCocos2dx

一个传统UIKit App集成cocos2dx的例子。cocos2dx为最新版3.15.1。

网上大部分能搜索到的大部分的教程都是在cocos2dx项目模板的基础上集成UIKit，缺少在一个维护很久的传统UIKit App项目的基础上去集成cocos2dx。并且能搜索到的教程也是基于2.x的版本，而现在cocos2dx已经升级到了3.15.1。

## 集成

1. 在官网下载最新的cocos2dx源码：[http://www.cocos2d-x.org/download]

2. 下载后解压，`/Users/[用户名]/Downloads/cocos2d-x-3.15.1/tools/cocos2d-console/bin/cocos`。可在控制台生成官方提供的模板。命令为`cocos new -l cpp`

3. 但是我们这里是需要把cocos2dx集成进我们的传统项目。在UIKit项目中创建一个目录，用于存放cocos2dx相关源码文件。这里我们只需要`build`、`coocs`、`extensions`、`external`、`plugin`这几个目录的源码拷贝至该目录中。

4. 接下来，打开我们的项目。把`build`下`cocos2d_libs.xcodeproj`拖入我们的项目中。

5. 在`Linked Frameworks and Libraries`中增加`libcocos2d iOS.a`、`GameController.framework`、`OpenAL.framework`。

6. 需要注意的是，如果UIKit项目中`AppDelegate`命名如果是默认的需要修改，否则会和cocos2dx中的产生冲突，需要修改名字。

7. 在需要用到cocos2dx的文件中需要修改`.m`文件为`.mm`文件，`#import "cocos2d.h"`。

8. 接下来开始编辑项目，如果有error，头文件没有找到。需要在`Header search paths`中添加路径，比如`$(SRCROOT)/[项目名称]/[coos2dx存放目录]/cocos2d-x-3.15.1`。注意：千万不要添加*路径，否则会产生很多问题。

9. 如果有error的文件是在android或者其他平台目录下，可以直接删除这个目录，不会有影响。

10. 最后编译成功。

## 运行手游

```

CGFloat width = self.view.bounds.size.width > self.view.bounds.size.height ? self.view.bounds.size.width : self.view.bounds.size.height;

CGFloat height = self.view.bounds.size.width < self.view.bounds.size.height ? self.view.bounds.size.width : self.view.bounds.size.height;

eaglView = [CCEAGLView viewWithFrame:CGRectMake(0, 0, width, height)
pixelFormat: kEAGLColorFormatRGBA8
depthFormat: GL_DEPTH_COMPONENT16
preserveBackbuffer: NO
sharegroup: nil
multiSampling: NO
numberOfSamples:0 ];

glClearColor(255, 255, 255, 1);
eaglView.opaque = NO;
[self.view addSubview:eaglView];
eaglView.backgroundColor = [UIColor whiteColor];

cocos2d::Application *app = cocos2d::Application::getInstance();
app->initGLContextAttrs();
cocos2d::GLViewImpl::convertAttrs();
cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)eaglView);
cocos2d::Director *pDirector = cocos2d::Director::getInstance();
pDirector->setOpenGLView(glview);
pDirector->setClearColor(cocos2d::Color4F::WHITE);
app->run();

```

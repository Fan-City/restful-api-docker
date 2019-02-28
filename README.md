# 目录结构
```
├── data                       // raml 管理相关
│   ├── data-types             // 在API中使用的 (数据) 类型的声明
│   ├── docs                   // 文档相关
│   ├── raml                   // 所有 RESTful API
│   ├── traits                 // 为方法(GET/POST/PATCH/DELETE)定义通用属性，例如是否可过滤、可搜索或是可分页
│   └── api.raml               // RESTful API 入口文件     
├── .dockerignore              // docker 忽略项，加快镜像构建时间，同时减少Docker镜像大小
├── .gitignore                 // git 忽略项，可参考 https://github.com/github/gitignore
├── api.html                   // 生成的 api 静态文档文件
├── docker-compose.yaml        // docker 默认的模板文件
├── Dockerfile                 // 封装了构建行为的脚本文件
├── package-lock.json          // 包管理器（锁定版本）
├── package.json               // 包管理器
├── README.md                  // 项目自述文件 
├── supervisord.conf           // supervisord 配置文件，用于管理进程
├── watcher-tasks.js           // 自定义的一个JS文件，用于执行npm任务 
```

# API 构建步骤
### 1.通读：阮一峰的 [RESTful API 设计指南](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)
### 2.知晓：约定 API 一般包含以下数据
> 原则：**消费者驱动**，Service 所提供的 API 是给不同的消费者去使用的，所以消费端需要消费什么数据，API 就应该返回什么数据。

1. 当前 API 的路径是什么？ 如 /auth/register  
2. 当前 API 提交数据的类型是什么? 比如：
    * GET 获取数据
    * POST 提交或者创建
    * PATCH 修改数据，部分修改
    * DELETE 删除数据
    * PUT 修改数据，整体替换原有数据
3. 参数类型/格式，比如是 json 格式，还是 application/x-www-form-urlencoded 的数据；
4. 参数字段，及限制条件；
5. 返回成功的数据格式；
6. 返回失败的数据格式。

### 3.规范化：设计API（契约）（参考：[Github Api](https://api.github.com/),[JSONPlaceholder](https://jsonplaceholder.typicode.com/)）
> 通俗的讲是设计一个 API 契约，Service 和 Consumer（ Consumer 可以是前端或另一个 Service ）的 API 结构需要一个契约来统一管理，这样一来，负责 Service 和 Consumer 的开发人员都能参照同一套 API 契约独立并行开发，双方完成后进行集成联调。 

> 原则：
> * 通过路径 ```/auth/register``` 和类型 ```POST``` 可知该 API 作用；
> * 网址中不能有动词，只能有名词，而且所用的名词往往与数据库的表格名对应；
> * 使用Put,Post和Delete方法替代Get方法来改变资源状态，不要使用Get来使状态改变；
> * 不要混合使用单数和复数形式，而应该为所有资源一直保持使用复数形式；
> * 在客户端和服务端都需要知道使用什么格式来进行通信，这个格式应该在HTTP头中指定：Content-Type：定义请求的格式，Accept ：定义允许的响应格式的列表；
> * 为所有字段或者查询语句提供独立的查询参数：GET /cars?seats<=2 (Returns a list of cars with a maximum of 2 seats)
> * 允许跨越多字段的正序或者倒序排列：GET /cars?sort=-manufactorer,+model
> * 一些情况下，我们只需要在列表中查询几个有标识意义的字段，我们不需要从服务端把所有字段的值都请求出来，所以需要支持API选择查询字段的能力，这也可以提高网络传输性能和速度：GET /cars?fields=manufacturer,model,id,color
> * 使用offset和limit来获取固定数量的资源结果，当其中一个参数没有出现时，应该提供各自的默认值，比如默认取第一页，或者默认取20条数据：GET /cars?offset=10&limit=5
> * 使用自定义的头X-Total-Count发回给调用段实际的资源数量；
> * 前一页后一页的链接也应该在HTTP头链接中得到支持，遵从下文中的链接原则而不要构建你自己的头：<https://blog.mwaysolutions.com/sample/api/v1/cars?offset=50&limit=3>; rel="last"
> * 确保强制实行API版本，并且不要发布一个没有版本的API，使用简单的序列数字，避免使用2.5.0这样的形式：/blog/api/v1
> * 使用HTTP状态码统一处理错误；
> * 一些代理只支持GET和POST方法，为了在这种限制下支持RESTful API，API需要重写HTTP方法。使用自定义的X-HTTP-Method-Override  HTTP头来重写POST方法。

**认证相关**  

```POST /auth/register```  

功能: 用户注册

提交参数

* 参数类型:```Content-Type: application/x-www-form-urlencoded;charset=utf-8```
* 参数字段
    * username : 用户名, 长度1到15个字符，只能是字母数字下划线中文
    * password : 密码, 长度6到16个任意字符

返回数据

* 失败
    * 状态码 400
    * 返回格式 ```{msg: '错误原因'}```

* 成功
    * 状态码 200
    * 返回格式
    ```
    {
        "msg": "注册成功",
        "data": {
            "id": 1,
            "username": "michael",
            "updatedAt": "2017-12-27T07:40:09.697Z",
            "createdAt": "2017-12-27T07:40:09.697Z"       
        }
    }
    ```

```GET /auth```  

功能: 判断用户是否登录

提交参数: 无

返回数据

* 已经登录的情况  
```
{
  "isLogin": true,
  "data": {
    "id": 1,
    "username": "michael",
    "updatedAt": "2017-12-27T07:40:09.697Z",
    "createdAt": "2017-12-27T07:40:09.697Z"
  }
}
```
* 没有登录的情况
```
{
  "isLogin": false
}
```  

```GET /auth/logout```  

功能: 注销登录

提交参数: 无

返回数据:

* 失败
    * 状态码 400
    * 返回格式 ```{msg: '当前用户尚未登录'}```
* 成功
    * 状态码 200
    * 返回格式 ```{msg: '注销成功'}```

```POST /auth/login```  

功能: 用户登录

提交参数

* 参数类型:```Content-Type: application/x-www-form-urlencoded;charset=utf-8```
* 参数字段
    * username : 用户名, 长度1到15个字符，只能是字母数字下划线中文
    * password : 密码, 长度6到16个任意字符

返回数据

* 失败
    * 状态码 400
    * 返回格式 ```{msg: '用户不存在'}``` 或者 ```{msg: '密码不正确'}```
* 成功
    * 状态码 200
    * 返回格式
    ```
    {
        "msg": "登录成功",
        "data": {
            "id": 1,
            "username": "michael",
            "createdAt": "2017-12-27T07:40:09.697Z",
            "updatedAt": "2017-12-27T07:40:09.697Z"
        }
    }
    ```  
    
**业务相关**
以下所有需要登录的操作，如果未登录，则返回
* 状态码 400
* 返回数据 ```{msg: '登录后才能操作'})```  

```GET /courses```  

功能: 获取课程列表

提交参数: 无

返回数据:

* 失败
    * 状态码 400
    * 返回格式 ```{msg: '登录后才能操作'}```
* 成功
    * 状态码 200
    * 返回格式
    ```
    {
	"total": 2,
	"data": [{
		"courseId": 6,
		"courseName": "系统架构",
		"courseThumb": "https://10.url.cn/qqcourse_logo_ng/510",
		"applictionDate": "2018-05-01",
		"classDate": "2018-05-01",
		"courseDesc": "系统构架是对已确定的需求的技术实现构架",
		"expiredFlag": "1",
		"signupNum": "45",
		"voteNum": "84"
	}, {
		"courseId": 7,
		"courseName": "项目管理",
		"courseThumb": "https://10.url.cn/qqcourse_logo_ng/510",
		"applictionDate": "2018-05-01",
		"classDate": "2018-05-01",
		"courseDesc": "项目管理是管理学的一个分支学科",
		"expiredFlag": "1",
		"signupNum": "61",
		"voteNum": "101"
        }]
    }
    ```

```POST /courses```  

功能: 创建课程

提交参数

* 参数类型:```Content-Type: application/x-www-form-urlencoded; charset=utf-8```  

* 参数字段  
    * title : 课程标题, 不能为空，且不超过30个字符

返回数据

* 失败
    * 状态码 400
    * 返回格式 ```{msg: '登录后才能操作'}```
* 成功
    * 状态码 200
    * 返回格式
    ```
    {
    "msg": "创建成功",
    "data": {
        "courseId": 7,
        "courseName": "项目管理",
        "courseThumb": "https://10.url.cn/qqcourse_logo_ng/510",
        "applictionDate": "2018-05-01",
        "classDate": "2018-05-01",
        "courseDesc": "项目管理是管理学的一个分支学科",
        "expiredFlag": "1",
        "signupNum": "61",
        "voteNum": "101"	
        }
    }
    ```

```PATCH /courses/:courseId```  

功能: 修改课程

范例: /courses:/1

提交参数

* 参数类型:```Content-Type: application/x-www-form-urlencoded; charset=utf-8```
* 参数字段
    * title : 课程标题, 课程标题不能为空，且不超过30个字符  

返回数据

* 失败
    * 状态码 400
    * 返回格式 ```{"msg": "登录后才能操作"}``` 或者 ```{"msg": "课程不存在"}```
* 成功
    * 状态码 200
    * 返回格式 { "msg": "修改成功" }

```DELETE /courses/:courseId```  

功能: 删除课程

提交参数：无

返回数据

* 失败
    * 状态码 400
    * 返回格式范例
        * ```{"msg": "登录后才能操作"}```
        * ```{"msg": "课程不存在"}```
* 成功
    * 状态码 200
    * 返回格式 { "msg": "删除成功" }

### 4.使用 Raml 构建 API： 关于 Raml 更多详细指南，可参阅： [Raml-spec](https://github.com/raml-org/raml-spec/blob/master/versions/raml-10/raml-10.md/) 和 [json-schema](https://jackwootton.github.io/json-schema/) 和 [Raml-projects](https://raml.org/projects)

```
├── data                       // raml 管理相关
│   ├── data-types             // 在API中使用的 (数据) 类型的声明
│   ├── docs                   // 文档相关
│   ├── raml                   // 所有 RESTful API
│   ├── traits                 // 为方法(GET/POST/PATCH/DELETE)定义通用属性，例如是否可过滤、可搜索或是可分页
│   └── api.raml               // RESTful API 入口文件           
```

### 5.文档化 API： 使用 [RAML to HTML](https://github.com/raml2html/raml2html) 去做 Raml 到 html 的转换，再利用 [Live Server](https://github.com/tapio/live-server) 起一个静态文件服务

```powershell
$ vi package.json
    {
      ...
      "dependencies": {
        "raml2html": "^6.1.0",
      }
      "scripts": {
        "docs-generator": "raml2html data/api.raml > api.html"
        "docs-server": "live-server --port=8091 --watch=api.html --entry-file=api.html"
      }
      ...
    }

$ npm run docs-generator
$ npm run docs-server
```

### 6.服务化 API：使用 [osprey-mock-service](https://github.com/mulesoft-labs/osprey-mock-service) 生成 mock 服务，供前端开发人员在代码中调用
```powershell
$ vi package.json
    {
      ...
      "dependencies": {
        "osprey-mock-service": "^0.2.0"
      }
      
      "scripts": {
        "mock-server": "osprey-mock-service -f data/api.raml -p 8090 --cors"
      }
      ...
    }

$ npm run mock-server 
> vue-webpack-start@1.0.0 mock-server /Users/michael/Desktop/sites/web-dev
eloper/vue-webpack-start> osprey-mock-service -f data/api.raml -p 8090 --cors
Mock service running at http://localhost:8090/

# 访问 API http://localhost:8090/v1/users

# 测试 API
$ curl -H "Content-Type: application/json" -X POST -d '{"name":"michael","password":"1qasdsw", "phoneNumber":"139712254745", "account":"michael"}' http://localhost:8090/users

{"id":"2nldksfr4f2ifoa4g43rvfsdfdsfdaf2","account":"michael","phoneNumber":"13971332745","gender":"MALE","name":"徐天乐"}
```

### 7.容器化 API：使用 [Docker Compose](https://docs.docker.com/compose/) 将依赖和构建封装起来

> 可以将构建的镜像上传到一个私有的镜像仓库或者 Dockerhub 中，在使用的地方将镜像源指向你的镜像所在的仓库即可

```powershell
#有效加快镜像构建时间，同时减少Docker镜像的大小
$ vi .dockerignore

# 封装了构建行为的 Dockerfile（ Dockerfile 编写注意事项：参考 https://www.cnblogs.com/bigberg/p/9001584.html）
$ vi Dockerfile
    #第一行必须指令基于的基础镜像
    FROM node:7-alpine
    #维护者信息
    MAINTAINER "michael" <michael.xu1983@qq.com>
    #镜像的操作指令
    RUN apk --update add git supervisor && rm -rf /var/cached/apk/*
    
    # Prepare work directory and copy all files
    RUN mkdir /app
    WORKDIR /app
    
    # install dependencies
    COPY package.json /app
    RUN cd /app && npm i --silent
    
    COPY supervisord.conf /app
    COPY watcher-tasks.js /app
    COPY supervisord.conf supervisord.conf
    
    EXPOSE 8080 8081
    #容器启动时执行指令
    CMD ["/usr/bin/supervisord"]

# supervisord.conf 是 supervisord 的配置文件，用于管理进程。
$ vi supervisord.conf

# watcher-tasks.js 是自定义的一个JS文件，用于执行npm任务
$ vi watcher-tasks.js
$ vi package.json
    {
      ...
      "dependencies": {
        "nodemon": "^1.11.0",
      }
      
      "scripts": {
        "api-watcher": "nodemon --watch data --ext raml,json,markdown watcher-tasks.js",
      }
      ...
    }

# docker-compose.ymal 文件定义了从当前目录中的 Dockerfile 去构建镜像，通过映射将我们业务 api 目录挂载到容器内部，具体配置可参考 https://www.jianshu.com/p/2217cfed29d7
    version: '3'
    services:
    raml:
        # 指定 Dockerfile 所在文件夹的路径。Compose 将会利用它自动构建这个镜像，然后使用这个镜像启动服务容器
        build: .
        # 映射端口的标签:使用HOST:CONTAINER格式或者只是指定容器的端口，宿主机会随机映射端口（8098、8092分别为 api-docs 和 mock-server 的端口，可以按需更改）
        ports:
        - "8090:8080"
        - "8091:8081"
        # 使用绝对路径挂载数据卷挂载一个目录或者一个已存在的数据卷容器
        volumes:
        - ./data:/app/data

# 启动容器
$ docker-compose up 

# api-docs: http://localhost:8090/api.html
# mock-server: http://localhost:8091/users
```
启动后，如果访问 http://localhost:8092 没有正常出现API文档，可以进入容器，运行下面手动生成API 文档命令查看错误日志：
```powershell
$ docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                            NAMES
f3e558dfab63        restful-api-docker_raml   "/usr/bin/supervisord"   6 minutes ago       Up 6 minutes        0.0.0.0:8090->8080/tcp, 0.0.0.0:8091->8081/tcp   restful-api-docker_raml_1

$ docker exec -it 3d13adb457f3 sh
$ npm run docs-generator
```
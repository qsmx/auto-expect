# expect 自动登录工具

## 安装

```
install.sh -n <rd> -p </usr/local/bin/> -c <~/.rd.d/>
        -n rd       命令名，默认为 rd

        -i /usr/local/bin/
                    安装路径

        -y          直接安装，不出现交互提示
```

## 远程主机配置(/etc/<rd>.d/server, $HOME/.<rd>.d/server)

```
# 第一列可以为域名或者IP地址，如果设置了第二列，可以是别名
# 连接主机时，只会连接第一列
# 同一IP可配置多个别名（多行），灵活应用
;[ip] <domain|alias|ip>
127.0.0.1 self
127.0.0.1 hi
```

## 配置(/etc/<rd>.d/setting, $HOME/.<rd>.d/setting)


### 通用配置

```
[server]
    # 登录名
    username  =
    # 密码
    password  =

    # 登录后自动执行
    ; command =

    # 自动执行命令后是否停留在交互环境
    # 设置为true时停留，默认退出
    #
    # 同一分类下的 interact 有效
    # 分类完全等于 域名、别名、IP 时设置优先级最高，其次为 [server]，最后为正则匹配的分类
    # 优先级：[域名]、[别名]、[IP]、[server]、[正则匹配]
    # 如果以上有一个设置为true，则为true
    ; interact = false

    # 跳板机, 优先级最低
    gateway   =
```

### 跳板机（可配置多个
```
[gateway]
    # 唯一名称， 用于 server::gateway 查找
    # 同名 name 将被覆盖
    name      =

    # 地址
    remote    =

    # 状态，默认开
    # 设置为 close 时停止工作
    ; status  = open

    # 登录名
    # 如果为空，默认使用 server::username
    username  =

    # 密码
    # 如果为空，默认使用 server::password
    password  =

    # 匹配模式（正则）
    # 用于自动匹配 server文件 中 domain 或 ip
    pattern   =

```

### 自定义远程主机配置

```
# 可以是 server 文件中的域名、别名、或IP地址
# server 中第一列的优先级高于第二列的IP（如果有2列的话）
# 参与 能用配置 中的所有字段
[facebook]
    # 指定用户
    username = test001

注：自动执行命令支持正则配置，便于 server 中别名设置为相似，分组执行
所有 server 文件中匹配 ^face 的域名或别名
[face.*]
    command = echo face

    # 停留在交互环境
    # 同一分类下的 interact 有效
    interact = true
```

## 执行

### 参数

```
-t              仅打印执行的命令

$ rd -t ssh svr
TryRun: ssh -tt svr
```

### ssh

> rd ssh svr [cmd]

```
# 如果第一个参数不是子命令，则自动执行 ssh，然后通过第一参数查询 server 列表
$ rd facebook
$ rd ssh facebook
```

#### 自动执行命令

```
# 在 setting 中配置相应的 command，将自动执行该 command
# [face.*]
[facebook]
    # 这将自动执行 ifconfig
    command = ifconfig

    # 如果执行完命令后如果需要停留在交互环境，将 interact 设置为 true
    interact = true
```

#### 手动执行命令

```
# ssh 子命令也可添加执行动作
# face 也将匹配 facebook
# 这将在 face 上执行 ifconfig
$ rd face ifconfig

# 如果执行动作包含管道 '|'，必须添加 '' 包含子命令

# 管道在远程主机执行
$ rd face 'ifconfig | grep inet'
# 管道在本地执行
$ rd face ifconfig | grep inet
```

### scp

> rd scp src dest

#### 从远程拷贝到本地

```
# 远程路径：<svr:[/.../path]>
#           svr: 主机域名、别名、IP
#           ":": 必须存在
#     /.../path: 远程路径或文件，可选
#                不存在时则表示登录用户目录
# 本地路径：[dest] 可选，默认为当前目录
$ rd scp <svr:[/.../path]> [dest]

# 拷贝 face 远程主机用户的x文件
$ rd scp face:/x
# 拷贝 face 远程主机用户目录至本地
$ rd scp face:
```

#### 从本地拷贝到远程

```
# 本地路径：src 本地文件或目录
# 远程路径：<svr:[/.../path]>
#           svr: 主机域名、别名、IP
#           ":": 可省略
#     /.../path: 远程路径或文件，可选
#                不存在时则拷贝到用户登录
$ rd scp src <svr[:[/.../path]]>
```

### 查询匹配的远程主机

> rd list svr

```
$ rd list face
 @@ MATCHED
  * [1] - face|172.17.0.100
  * [2] - facebook|172.17.0.101
```

### 映射远程目录至本地（未验证）

> rd sshfs src [dest]

```
# 远程路径：<svr:[/.../path]>
#           svr: 主机域名、别名、IP
#           ":": 必须存在
#     /.../path: 远程路径或文件，可选
# 本地路径：[dest] 可选，默认为将生成 sshfs.???
$ rd sshfs <svr:[/.../path]> [dest]

# 映射远程用户目录至本地
# 缺省 [dest] 参数，本地目录为 sshfs.???
$ rd sshfs face:

# 映射 face 登录用户下 auto-expect/ 至本地 rd/
$ rd sshfs face:auto-expect/ rd
```

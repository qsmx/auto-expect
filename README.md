# expect 自动登录工具

## 安装

```
  install.sh -n <rd> -p </usr/local/bin/> -c <~/.rd.d/>
          -n rd       命令名，默认为 rd

          -i /usr/local/bin/
                      安装路径

          -c ~/.rd.d/
                      配置文件路径，默认为 ~/.<rd>.d/
```

## 远程主机配置(.../server)

```
# 第一列可以为域名，别名，或者IP地址，如果设置了第二列，则必须为IP
# 连接主机时，以第二列IP为优先
# 同一IP可配置多个别名（多行），灵活应用
;<domain|alias|ip> [ip]
```

## 配置(.../setting)


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
    interact = true
```


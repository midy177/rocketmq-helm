# RocketMQ Helm Chart

https://github.com/midy177/rocketmq-helm

## 版本兼容性

- Kubernetes 1.18+
- Helm 3.3+
- RocketMQ `>= 4.5`

## 添加 helm 仓库

``` shell
## 添加 helm 仓库
helm repo add rocketmq-repo https://helm-charts.itboon.top/rocketmq
helm repo update rocketmq-repo
```

## 部署案例

``` shell
## 部署一个最小化的 rocketmq 集群
## 这里关闭持久化存储，仅演示部署效果
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set broker.persistence.enabled="false" \
  rocketmq-repo/rocketmq
```

``` shell
## 部署测试集群, 启用 Dashboard (默认已开启持久化存储)
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set dashboard.enabled="true" \
  rocketmq-repo/rocketmq
```

### 部署高可用集群版

``` shell
## rocketmq-cluster 默认部署 2个 master 节点
## 每个 master 具有1个副节点，共4个 broker 节点
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  rocketmq-repo/rocketmq-cluster

```

``` shell
## 部署 3个 master 节点，每个 master 具有1个副节点，共6个 broker 节点
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set broker.size.master="3" \
  rocketmq-repo/rocketmq-cluster

```

``` shell
## 调整内存配额
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set broker.master.jvm.maxHeapSize="4G" \
  --set broker.master.resources.requests.memory="6Gi" \
  rocketmq-repo/rocketmq-cluster

```

> 具体资源配额请根据实际环境调整，参考 [examples](https://github.com/itboon/rocketmq-helm/tree/main/examples)

## 部署详情

### 集群外访问

#### 通过 proxy 实现集群外访问

可以将 proxy 暴露到集群外，支持 `LoadBalancer` 和 `NodePort`

> proxy 是 RocketMQ 5.x 版本新增的模块，这种模式能够更好的适应复杂的网络环境，尤其是 k8s 集群内外互通，详情请参考[官方文档](https://rocketmq.apache.org/version/#whats-new-in-rocketmq-50)

``` yaml
proxy:
  service:
    annotations: {}
    type: NodePort  ## LoadBalancer or NodePort
```

#### hostNetwork

broker 支持 `hostNetwork`，即 pod 使用主机网络命名空间，这种方式的缺点是每个 node 节点最多只能调度一个 broker

``` yaml
broker:
  hostNetwork: true

nameserver:
  service:
    type: NodePort  ## LoadBalancer or NodePort
```

建议优先使用 proxy 实现集群外访问，`hostNetwork` 作为向下兼容的备选方案。

> 仅 broker 支持 `hostNetwork`，其他组件可以使用 `NodePort`

### 可选组件

``` yaml
## 关闭 proxy
proxy:
  enabled: false  ## 默认 true

## 关闭 dashboard
dashboard:
  enabled: false  ## 默认 true
```

### Dashboard 登录认证

Dashboard admin 帐号密码:

``` yaml
dashboard:
  enabled: true
  auth:
    enabled: true
    users:
      - name: admin
        password: admin
        isAdmin: true
      - name: user01
        password: userPass
```

### 镜像仓库

``` yaml
image:
  repository: apache/rocketmq
  # tag: 5.2.0
  tag: 4.9.7
```

### 部署特定版本

``` shell
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set image.tag="5.2.0" \
  rocketmq-repo/rocketmq
```

### 内存管理

集群每个模块提供堆内存管理，例如 `--set broker.master.jvm.maxHeapSize="1024M"` 将堆内存设置为 `1024M`，默认 `Xms` `Xmx` 相等。堆内存配额应该与 Pod `resources` 相匹配。

> 可使用 `jvm.javaOptsOverride` 对 jvm 参数进行修改，设置了此参数则 `maxHeapSize` 失效。

```yaml
broker:
  master:
    jvm:
      maxHeapSize: 1024M
      # javaOptsOverride: "-Xms1024M -Xmx1024M -XX:+UseG1GC"
    resources:
      requests:
        cpu: 100m
        memory: 2Gi

nameserver:
  jvm:
    maxHeapSize: 1024M
    # javaOptsOverride: "-Xms1024M -Xmx1024M -XX:+UseG1GC"
  resources:
    requests:
      cpu: 100m
      memory: 2Gi
```

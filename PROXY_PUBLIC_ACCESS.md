# RocketMQ Proxy 公网访问配置指南

## 概述

本文档介绍如何通过配置 `remotingAccessAddr` 参数，使 RocketMQ Proxy 支持公网访问能力。这对于需要从集群外部（如公网环境）访问 RocketMQ 集群的场景非常有用。

## 功能说明

`remotingAccessAddr` 是 RocketMQ Proxy 配置中新增的参数，用于指定 Proxy 的 Remoting 协议公网访问地址（IP 或域名）。当客户端通过公网连接 Proxy 时，Proxy 会返回此地址供客户端后续通信使用。

### 相关配置参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `remotingAccessAddr` | Remoting 协议的公网访问地址（仅 IP 或域名，不含端口） | 空字符串 |
| `remotingListenPort` | Remoting 协议监听端口 | 8080 |

## 使用场景

- **跨网络访问**：客户端位于集群外部网络，需要通过公网 IP 或域名访问 RocketMQ
- **云环境部署**：在云平台部署 RocketMQ，需要通过 LoadBalancer 或公网 IP 对外提供服务
- **混合云架构**：部分客户端在内网，部分客户端在外网，需要同时支持内外网访问
- **开发测试环境**：开发人员需要从本地访问远程 Kubernetes 集群中的 RocketMQ

## 配置方法

### 1. 通过 Helm Chart 配置

在部署 RocketMQ 时，通过 values.yaml 文件配置 proxy 的公网访问地址：

```yaml
proxy:
  enabled: true
  service:
    type: LoadBalancer  # 或 NodePort
    annotations: {}
  config:
    remotingAccessAddr: "your-public-ip"  # 配置公网访问地址（仅 IP 或域名）
    remotingListenPort: 8080
```

### 2. 使用 LoadBalancer 方式

如果您的 Kubernetes 集群支持 LoadBalancer 类型的 Service，推荐使用此方式：

```yaml
proxy:
  enabled: true
  service:
    type: LoadBalancer
    annotations:
      # 云厂商特定注解，例如阿里云
      # service.beta.kubernetes.io/alibaba-cloud-loadbalancer-spec: "slb.s1.small"
  config:
    remotingAccessAddr: "<LoadBalancer-External-IP>"
    remotingListenPort: 8080
```

部署命令：

```bash
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set proxy.service.type="LoadBalancer" \
  --set proxy.config.remotingAccessAddr="<YOUR-PUBLIC-IP>" \
  rocketmq-repo/rocketmq
```

### 3. 使用 NodePort 方式

如果没有 LoadBalancer，可以使用 NodePort 方式暴露服务：

```yaml
proxy:
  enabled: true
  service:
    type: NodePort
    nodePort: 30080  # 指定 NodePort 端口（可选）
  config:
    remotingAccessAddr: "<Node-IP>"  # 使用节点 IP 或负载均衡地址
    remotingListenPort: 8080
```

部署命令：

```bash
helm upgrade --install rocketmq \
  --namespace rocketmq-demo \
  --create-namespace \
  --set proxy.service.type="NodePort" \
  --set proxy.config.remotingAccessAddr="<NODE-IP>" \
  rocketmq-repo/rocketmq
```

### 4. 使用域名配置

推荐使用域名而不是 IP 地址，便于后续维护和迁移：

```yaml
proxy:
  enabled: true
  service:
    type: LoadBalancer
  config:
    remotingAccessAddr: "rocketmq-proxy.example.com"
    remotingListenPort: 8080
```

## 配置示例

### 完整配置示例

```yaml
# values.yaml
proxy:
  enabled: true
  replicaCount: 2

  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    ports:
      - name: remoting
        port: 8080
        targetPort: 8080
      - name: grpc
        port: 8081
        targetPort: 8081

  config:
    # 公网访问地址配置（仅域名或 IP，不含端口）
    remotingAccessAddr: "rocketmq.example.com"
    remotingListenPort: 8080

    # gRPC 配置
    grpcServerPort: 8081

    # NameServer 地址
    namesrvAddr: "rocketmq-nameserver:9876"

    # 其他配置
    proxyMode: "CLUSTER"

  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
```

### 配置文件方式（proxy.json）

如果直接修改 proxy.json 配置文件：

```json
{
  "remotingAccessAddr": "rocketmq-proxy.example.com",
  "remotingListenPort": 8080,
  "grpcServerPort": 8081,
  "namesrvAddr": "rocketmq-nameserver:9876",
  "proxyMode": "CLUSTER"
}
```

## 客户端配置

配置完成后，客户端可以直接使用公网地址连接：

### Java 客户端示例

```java
// 使用 Remoting 协议
DefaultMQProducer producer = new DefaultMQProducer("ProducerGroup");
producer.setNamesrvAddr("rocketmq-proxy.example.com:8080");
producer.start();

// 发送消息
Message msg = new Message("TopicTest", "TagA", "Hello RocketMQ".getBytes());
SendResult sendResult = producer.send(msg);
```

### 客户端配置说明

当使用公网访问时，客户端配置需要注意：
- **NameServer 地址**：配置为 Proxy 的公网地址（remotingAccessAddr）
- **超时设置**：公网访问延迟较高，建议增大超时时间
- **重试策略**：建议配置合适的重试次数和间隔

## 注意事项

### 1. 安全性考虑

暴露到公网需要注意安全问题：

- **启用 ACL 认证**：强烈建议开启 RocketMQ 的 ACL 功能
  ```yaml
  proxy:
    config:
      enableAclRpcHookForClusterMode: true
  ```

- **配置 TLS/SSL**：启用加密传输
  ```yaml
  proxy:
    config:
      tlsTestModeEnable: false
      tlsKeyPath: "/path/to/tls/key"
      tlsCertPath: "/path/to/tls/cert"
  ```

- **防火墙规则**：限制访问来源 IP 范围
- **网络隔离**：使用 VPC 或安全组限制访问

### 2. 网络配置

- 确保公网 IP/域名可以正常解析并访问
- 检查防火墙规则，开放必要端口（默认 8080 和 8081）
- 如果使用 LoadBalancer，注意云厂商的相关限制和费用

### 3. 性能优化

- **负载均衡**：部署多个 Proxy 实例提供高可用
- **资源配置**：根据实际负载调整 CPU 和内存配额
- **网络带宽**：确保公网带宽满足业务需求

### 4. 监控告警

建议配置监控指标：
- Proxy 连接数
- 请求成功率
- 响应时间
- 网络流量

### 5. 常见问题

**Q: 配置后客户端无法连接？**

A: 检查以下几点：
1. 确认 Service 的 External-IP 已分配（LoadBalancer 模式）
2. 验证防火墙规则是否开放对应端口
3. 检查 remotingAccessAddr 配置是否正确
4. 查看 Proxy 日志排查错误

**Q: 如何查看 LoadBalancer 分配的 IP？**

A: 执行命令查看：
```bash
kubectl get svc -n rocketmq-demo
```

**Q: NodePort 方式如何选择节点 IP？**

A: 可以使用任意一个 Node 的 IP，建议使用：
- 公网 IP（如果节点有）
- 配置 Ingress 或负载均衡器转发到 NodePort

## 验证配置

### 1. 验证 Service 状态

```bash
# 查看 proxy service
kubectl get svc -n rocketmq-demo | grep proxy

# 查看详细信息
kubectl describe svc rocketmq-proxy -n rocketmq-demo
```

### 2. 验证 Proxy 配置

```bash
# 查看 proxy pod
kubectl get pods -n rocketmq-demo | grep proxy

# 查看配置
kubectl exec -it <proxy-pod-name> -n rocketmq-demo -- cat /home/rocketmq/rocketmq/proxy/conf/proxy.json | grep remotingAccessAddr
```

### 3. 测试连接

```bash
# 使用 telnet 测试端口连通性
telnet <remotingAccessAddr> 8080

# 或使用 nc
nc -zv <remotingAccessAddr> 8080
```

## 参考文档

- [RocketMQ 官方文档](https://rocketmq.apache.org/)
- [RocketMQ 5.x Proxy 架构](https://rocketmq.apache.org/version/#whats-new-in-rocketmq-50)
- [Kubernetes Service 文档](https://kubernetes.io/docs/concepts/services-networking/service/)

## 更新日志

- 2024-01: 新增 `remotingAccessAddr` 配置支持公网访问能力

## 贡献

如有问题或建议，欢迎提交 Issue 或 Pull Request。
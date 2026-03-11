# Helm Multi-Site Application Chart

## Overview

This Helm chart demonstrates how a reusable Kubernetes deployment template can be evolved to support progressively more complex routing requirements.

The chart deploys a simple containerized application with:

- A **Deployment** with 3 replicas
- A **ClusterIP Service**
- An **Ingress resource**

The chart supports deploying different **sites**, **regions**, and **environments**, while dynamically generating the correct hostnames for routing traffic.

The implementation was built incrementally across three stages to demonstrate chart evolution.

---

# Chart Structure

```
Helm
├── README.md
├── part1
│   └── multi-site-app
├── part2
│   └── multi-site-app
└── part3
    └── multi-site-app
```

Each directory represents an evolution of the same chart with additional requirements implemented.

---

# Application Architecture

Each deployment consists of:

```
Ingress
  ↓
Service (ClusterIP)
  ↓
Deployment (3 replicas)
  ↓
Pods
```

External traffic enters through the **Ingress controller**, which routes requests to the appropriate Service based on hostname rules.

---

# Design Decisions

## Use of Helm Helpers

Reusable logic such as:

- naming
- labeling
- hostname generation

is centralized in `_helpers.tpl`.

This reduces duplication across templates and allows hostname rules to evolve without modifying the ingress template.

---

## Deployment Instead of ReplicaSet

Although the requirement references a replica set of 3 pods, the chart uses a **Deployment**.

This is the recommended Kubernetes abstraction because:

- Deployments manage ReplicaSets
- support rolling updates
- support rollbacks
- represent production best practices

---

## ClusterIP Service Type

The Service is defined as `ClusterIP`.

This is sufficient because the application is exposed externally through the **Ingress controller**, which routes traffic internally to the Service.


---

## Input Validation

Helm template helpers validate supported values for:

- site
- region
- environment

This prevents invalid deployments and makes chart behavior predictable.

---

# Part 1 – Basic Site Deployment

Part 1 supports deploying a single site.

Supported sites:

- web
- api
- app

Hostnames follow the pattern:

```
<site>.example.com
```

Examples:

```
web.example.com
api.example.com
app.example.com
```

Ingress rules route both:

```
/
```

and

```
/healthcheck/<guid>
```

to the application.

---

# Part 2 – Regional Hostnames

Part 2 introduces regional routing.

Supported regions:

- region1
- region2
- region3

Regional hostnames follow the pattern:

```
<region>-<site>.example.com
```

Examples:

```
region1-web.example.com
region2-api.example.com
region3-app.example.com
```

### Special Rule for Region 1

Region 1 must preserve the original production hostname.

For example:

```
web.example.com
region1-web.example.com
```

Both routes are configured in the ingress.

---

# Part 3 – Environment Support

Part 3 introduces environment awareness.

Supported environments:

- dev
- stg
- prd

## Non-Production Environments

For `dev` and `stg`, hostnames follow:

```
<region>-<site>-<environment>.example.com
```

Examples:

```
region1-web-dev.example.com
region2-api-stg.example.com
```

## Production Environment

Production preserves the Part 2 behavior.

Examples:

```
web.example.com
region1-web.example.com
region2-api.example.com
```

This ensures backward compatibility with existing production routing.

---

# Configuration Values

| Value | Description | Example |
|------|-------------|--------|
| site | Application site | web |
| region | Deployment region | region1 |
| environment | Deployment environment | prd |
| replicaCount | Number of pods | 3 |
| baseDomain | Base domain used in hostnames | example.com |

---

# Example Deployments

### Production – Region 1 Web

```bash
helm install demo-web-r1-prd Helm/part3/multi-site-app \
  --set site=web \
  --set region=region1 \
  --set environment=prd
```

Expected hosts:

```
web.example.com
region1-web.example.com
```

### Staging – Region 2 API

```bash
helm install demo-api-r2-stg Helm/part3/multi-site-app \
  --set site=api \
  --set region=region2 \
  --set environment=stg
```

Expected host:

```
region2-api-stg.example.com
```

### Development – Region 3 App

```bash
helm install demo-app-r3-dev Helm/part3/multi-site-app \
  --set site=app \
  --set region=region3 \
  --set environment=dev
```

Expected host:

```
region3-app-dev.example.com
```

---

# Local Testing

The chart can be tested locally using a Kubernetes cluster such as:

- Rancher Desktop
- Minikube

Steps:

1. Start Kubernetes and install an ingress controller.

   Example using nginx ingress:

   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --create-namespace
   ```

2. Deploy the chart using Helm.

3. Inspect the ingress rules:

   ```bash
   kubectl describe ingress
   ```

4. Verify routing by sending the appropriate host header:

   ```bash
   curl -H "Host: region2-api-stg.example.com" http://localhost
   ```

---

# Summary

This Helm chart demonstrates:

- reusable chart design
- progressive chart evolution
- hostname generation through templating
- input validation using helpers
- ingress-based routing

The chart remains flexible while keeping the ingress template simple by centralizing hostname logic in helper templates.

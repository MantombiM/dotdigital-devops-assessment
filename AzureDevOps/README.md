# Dotdigital Azure DevOps YAML Pipeline Solution

## Objective

This solution implements an Azure DevOps YAML pipeline for the Azure Voting App that:

- builds the application container image
- pushes the image to Azure Container Registry (ACR)
- prepares a renamed Kubernetes manifest as a pipeline artifact
- deploys the application into Azure Kubernetes Service (AKS)
- promotes the deployment through three environments:
  - Dev
  - UAT
  - Prod

The design assumes the pipeline lives in the `azure-voting-app-redis` repository, and that Azure resources such as Azure Container Registry, Azure Kubernetes Service, Azure DevOps environments, service connections, and namespaces already exist and are wired correctly.

---

## Repository Structure

```text
.
├── azure-pipelines.yml
├── stages
│   ├── ci.yml
│   └── cd.yml
└── variables
    ├── vars-common.yml
    ├── vars-dev.yml
    ├── vars-uat.yml
    └── vars-prd.yml
```

## File Descriptions

| File | Description |
|------|-------------|
| `azure-pipelines.yml` | Root pipeline definition containing triggers, stage orchestration, deployment jobs, and Azure DevOps environments |
| `stages/ci.yml` | Reusable CI step template that scans the source, builds and pushes the container image, and publishes the Kubernetes manifest artifact |
| `stages/cd.yml` | Reusable CD step template that downloads the manifest artifact, creates an image pull secret, and deploys the application to AKS |
| `variables/vars-common.yml` | Shared variables used across all stages and environments |
| `variables/vars-dev.yml` | Variables specific to the Dev deployment stage |
| `variables/vars-uat.yml` | Variables specific to the UAT deployment stage |
| `variables/vars-prd.yml` | Variables specific to the Prod deployment stage |

---

## Pipeline Structure

The pipeline is split into one build stage and three deployment stages.

```
Build
  ↓
DeployDev
  ↓
DeployUAT
  ↓
DeployProd
```

This structure demonstrates a clear separation between CI and CD while also showing progressive promotion through multiple environments.

---

## Solution Summary

### 1. Build Stage

The Build stage performs the CI activities.

It:

- runs on pushes to main
- runs on pull requests targeting main
- scans the repository using Trivy
- builds the front-end container image from `azure-vote/Dockerfile`
- tags the image with `$(Build.BuildId)`
- pushes the image to Azure Container Registry
- generates a unique manifest name in the format `voteapp_<buildid>_<datetime>`
- copies and renames `azure-vote-all-in-one-redis.yaml`
- publishes the renamed manifest as a pipeline artifact

### 2. DeployDev Stage

The DeployDev stage performs the first deployment.

It:

- depends on the Build stage
- only runs for successful non-PR builds from main
- imports variables from `variables/vars-dev.yml`
- targets the Azure DevOps environment `Dev`
- downloads the manifest artifact
- creates an imagePullSecret in the Dev namespace
- deploys the manifest to AKS
- overrides the image reference to the image built in CI

### 3. DeployUAT Stage

The DeployUAT stage promotes the same artifact to UAT.

It:

- depends on DeployDev
- imports variables from `variables/vars-uat.yml`
- targets the Azure DevOps environment `UAT`
- downloads the same manifest artifact
- creates an imagePullSecret in the UAT namespace
- deploys the manifest to AKS
- overrides the image reference to the image built in CI

### 4. DeployProd Stage

The DeployProd stage promotes the same artifact to Prod.

It:

- depends on DeployUAT
- imports variables from `variables/vars-prd.yml`
- targets the Azure DevOps environment `Prod`
- downloads the same manifest artifact
- creates an imagePullSecret in the Prod namespace
- deploys the manifest to AKS
- overrides the image reference to the image built in CI

---

## Pipeline Trigger

The pipeline is configured to:

- trigger on pushes to main
- validate pull requests targeting main

This allows CI to run on both branch merges and pull request validation, while deployment only occurs from the main branch.

---

## Source Code Security Scan

The first task in the build stage uses Trivy to scan the repository filesystem.

The scan checks for:

- vulnerabilities
- infrastructure misconfigurations
- exposed secrets

The scan is configured to fail the pipeline when high or critical issues are found.

This ensures obvious security issues are identified before the image is built and pushed.

---

## Build and Push Process

The image is built using the Azure DevOps `Docker@2` task.

The pipeline:

- builds the image from the application Dockerfile
- tags the image with `$(Build.BuildId)`
- pushes the image to ACR using a Docker registry service connection

Example image format:

```
<acr-login-server>/<image-repository>:<buildid>
```

Example:

```
cr-lbg-voteapp-test-uks.azurecr.io/voteapp:104
```

This gives each build a unique and traceable image version.

---

## Manifest Handling

The deployment manifest used in this pipeline is:

```
azure-vote-all-in-one-redis.yaml
```

This Kubernetes manifest defines the application resources that should be created or updated in AKS.

During the build stage, the pipeline:

- generates a unique manifest base name
- copies the source manifest into the artifact staging directory
- renames it using the generated name
- publishes it as a pipeline artifact

Example output manifest name:

```
voteapp_104_20240304121530.yaml
```

This ensures the deployment stage consumes the exact manifest prepared during CI.

---

## Artifact Promotion

The renamed manifest is published as a pipeline artifact and then reused in every deployment stage.

This means:

- Dev receives the manifest produced by the Build stage
- UAT receives the same promoted manifest
- Prod receives the same promoted manifest

This preserves a clean promotion path from build output to deployment input.

---

## Deployment Process

Each deployment stage uses a deployment job targeting an Azure DevOps environment.

Within each deployment stage, the reusable `cd.yml` template performs the following steps:

- downloads the manifest artifact
- creates a Kubernetes imagePullSecret
- deploys the manifest to AKS
- overrides the image in the manifest with the current build image
- uses the imagePullSecret for registry authentication

The deployment uses the Azure DevOps `KubernetesManifest@1` task.

---

## Environment-Specific Variables

The solution uses separate variable files for each deployment environment.

### Shared variables

`variables/vars-common.yml` contains values shared across the entire pipeline, such as:

- build agent image
- ACR details
- AKS connection details
- image repository
- Dockerfile path
- manifest path
- artifact name
- image pull secret name

### Environment-specific variables

Each deployment stage imports its own variable file:

- `variables/vars-dev.yml`
- `variables/vars-uat.yml`
- `variables/vars-prd.yml`

These files contain values such as:

- AKS namespace
- Azure DevOps environment name

This keeps shared configuration centralized while allowing each environment to have its own deployment settings.

---

## Environments and Approvals

The deployment jobs target Azure DevOps environments:

- Dev
- UAT
- Prod

This design assumes that approval gates and checks are configured on those environments in Azure DevOps.

That means the YAML defines the deployment flow, while the actual approval behavior is managed in Azure DevOps environment settings.

---

## Assumptions

- The source repository structure matches the public Azure sample repository.
- Only the front-end application image is built. Redis is consumed from the existing multi-container Kubernetes manifest.
- The required ACR and AKS service connections already exist in Azure DevOps.
- Azure DevOps environments named Dev, UAT, and Prod already exist.
- Approval gates are configured on those Azure DevOps environments.
- AKS namespaces already exist:
  - `voteapp-dev`
  - `voteapp-uat`
  - `voteapp-prd`
- The ACR login server is provided explicitly because Azure DevOps needs the full registry hostname for image override during deployment.

---

## Why the Solution is Structured This Way

### 1. Main pipeline owns orchestration

The root pipeline defines:

- the trigger strategy
- the stage sequence
- deployment jobs
- environment targeting
- environment-specific variable templates

This makes the overall promotion flow immediately visible in a single file.

### 2. CI and CD logic are reusable

The `ci.yml` and `cd.yml` files are kept as reusable step templates.

This avoids duplication while allowing the high-level stage and job structure to remain in the main pipeline.

### 3. Variables are separated by scope

Shared values live in `vars-common.yml`, while environment-specific values live in separate environment files.

This reduces hardcoding and keeps environment-specific deployment concerns isolated.

### 4. Build and deployment are clearly separated

The Build stage produces artifacts and deployment inputs.

The deployment stages consume those outputs and promote them through Dev, UAT, and Prod.

### 5. Artifact promotion is explicit

The same manifest artifact is reused across environments rather than being rebuilt or reconstructed for each deployment.

### 6. Deployment environments are explicit

Using Azure DevOps environments makes the deployment flow clearer and supports approval gates and deployment tracking.

---

## Security and DevOps Considerations

- No secrets are hardcoded in YAML.
- ACR and AKS access are handled through Azure DevOps service connections.
- The repository is scanned with Trivy before the image build.
- The built image is versioned using `Build.BuildId` for traceability.
- Deployment uses a dedicated imagePullSecret rather than anonymous registry pulls.
- Environment-specific configuration is separated into dedicated variable files.
- The same artifact is promoted across Dev, UAT, and Prod.

---

## Potential Enhancements

If there were more time, possible enhancements could include:

- Add a dedicated image scan step after the Docker build and before the Docker push.
- Add YAML or Kubernetes manifest validation before artifact publication.
- If the AKS cluster is already integrated with Azure Container Registry using managed identity or kubelet identity, the pipeline could be simplified by removing the imagePullSecret creation step and relying on cluster-level ACR pull permissions instead.
- Add smoke tests or health checks after each deployment stage.
- Add branch-specific behavior for feature or release branches.
- Separate service connections by environment if Dev, UAT, and Prod use different Azure subscriptions or clusters.

---

## Summary

This solution implements an Azure DevOps YAML pipeline that:

- separates build and deployment concerns
- uses reusable CI and CD templates
- centralizes shared and environment-specific variables
- builds and pushes container images to ACR
- prepares a uniquely named Kubernetes manifest artifact
- promotes the same deployment artifact through Dev, UAT, and Prod
- uses Azure DevOps environments to support controlled deployments and approval gates

The structure is designed to remain simple, readable, and reusable while demonstrating a clear CI/CD flow for Azure Kubernetes Service.

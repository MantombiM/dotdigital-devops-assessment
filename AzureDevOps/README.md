# Dotdigital Azure DevOps YAML Pipeline Solution

## Objective
This solution delivers the four requested files for an Azure DevOps YAML pipeline that builds the Azure Voting App container image, publishes a renamed Kubernetes manifest as a pipeline artifact, and deploys that manifest into Azure Kubernetes Service.

The design assumes the pipeline lives in the `azure-voting-app-redis` repository, and that Azure resources such as Azure Container Registry and Azure Kubernetes Service already exist, which the assessment explicitly allows.

### File Descriptions

| File | Description |
|-----|-------------|
| `azure-pipelines.yml` | Root pipeline definition containing triggers and stage templates |
| `stages/ci.yml` | Continuous Integration stage that scans the source, builds and pushes the container image, and publishes the Kubernetes manifest |
| `stages/cd.yml` | Continuous Deployment stage that deploys the manifest to AKS |
| `variables/vars.yml` | Centralized configuration variables used throughout the pipeline |

---

## Solution Summary
The pipeline is split into two stages:

1. `CI`
   - Triggers from `main`
   - Builds the front end image from `azure-vote/Dockerfile`
   - Tags the image with `$(Build.BuildId)`
   - Pushes the image to Azure Container Registry
   - Generates a manifest base name in the format `voteapp_<buildid>_<datetime>`
   - Copies `azure-vote-all-in-one-redis.yaml` into the artifact staging directory
   - Renames the file to `voteapp_<buildid>_<datetime>.yaml`
   - Publishes the manifest as a pipeline artifact

2. `CD`
   - Downloads the manifest artifact
   - Creates an `imagePullSecret` in the target namespace
   - Deploys the manifest to AKS
   - Overrides the image reference to the image built in CI
   - Uses the `imagePullSecret` when deploying
   - Skips deployment for pull request runs

This separation ensures that the build and deployment responsibilities are clearly defined and independently managed.

---

## Pipeline Trigger

The pipeline is configured to run when changes are pushed to the `main` branch.

---

## Source Code Security Scan

The first step in the CI stage performs a security scan of the repository using **Trivy**.

The scan runs against the source filesystem and checks for:

- Vulnerabilities
- Infrastructure misconfigurations
- Exposed secrets

Running the scan before building the container image ensures issues are identified early in the pipeline.

## Assumptions
- The source repository structure matches the public Azure sample repository.
- Only the front end application image is built. Redis is consumed from the existing multi-container Kubernetes manifest.
- The ACR and AKS service connections already exist in Azure DevOps.
- The AKS namespace is `voteapp`. If it does not exist, it should be created beforehand or added as an enhancement.
- The ACR login server is provided explicitly because Azure DevOps needs the full registry hostname for image override during deployment.

## Why the solution is structured this way
### 1. Main pipeline is thin
The root pipeline only defines the trigger, imports shared variables, and references stage templates. This keeps orchestration separate from implementation details.

### 2. CI and CD are separated
The assessment asks for a sensible split of CI and CD activities. Splitting them makes the build and deployment responsibilities clear and easier to explain.

### 3. Variables are centralized
Values such as resource names, service connections, namespace, manifest path, and image repository are defined in one variables file instead of being repeated across files.

### 4. Service connection names are variables too
This is important in Azure DevOps because the Docker and Kubernetes tasks authenticate using service connections, not raw resource names.

### 5. The manifest is published as an artifact
The deployment stage consumes the exact manifest produced by the build stage. That preserves a clear promotion path from build output to deployment input.

### 6. Deployment is blocked on pull requests
The assessment pseudocode hints that deployment should not run for pull request builds. The `CD` stage therefore only runs when the pipeline is not triggered as a PR.

## Security and DevOps considerations
- No secrets are hardcoded in YAML.
- ACR and AKS access are expected to be handled through Azure DevOps service connections.
- The built image is versioned using `Build.BuildId` for traceability.
- Deployment uses a dedicated `imagePullSecret` rather than anonymous registry pulls.
- CI and CD are separated so deployment consumes a published artifact rather than reconstructing state.
- Variables are centralized to reduce drift and repeated hardcoded values.

## Possible enhancements if there were more time
- Add a validation stage for YAML linting or manifest validation.
- If the AKS cluster is already integrated with Azure Container Registry using managed identity or kubelet identity, the pipeline could be simplified by removing the `imagePullSecret` creation step and relying on cluster-level ACR pull permissions instead.
- Add environment approvals or checks in Azure DevOps.
- Add a namespace creation step if the namespace is not guaranteed to exist.
- Add branch policies and PR validation behavior separately from deployment behavior.

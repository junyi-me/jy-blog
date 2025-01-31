---
date: 2025-01-31
title: GitHub Actions Runner on your Kubernetes cluster
image: images/pipeline.jpg
tags: [github, CI/CD, kubernetes]
categories: [self-hosting]
---

As written in this post: [Using GitHub Actions to automatically build and push docker images]({{< ref "/post/github-actions-docker" >}}), I often use GitHub Actions to build and push docker images to Docker Hub.

I was happy about that, but I had one problem:

Every time I had to watch the action to finish, and then **manually restart** the deployment on my Kubernetes cluster to pull the image.

Since I had some computing resource in my Kubernetes cluster, I thought: why not run the GitHub Actions on my Kubernetes cluster? It will enable GitHub Actions to run `kubectl` commands directly in my cluster, and therefore automatically update any deployment. That is the motivation for this post, and it is what introduced me to [Actions Runner Controller](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller#introduction).

This post will guide you through setting up Actions Runner Controller on your Kubernetes cluster and using it in your GitHub Actions workflow.

## Create a GitHub organization (optional)

Once set up, the Actions Runner Controller (ARC) can be registered to be used by a single repository or an organization. I really hoped they would support using an ARC for multiple repositories in the same user account, but at the time of writing, it has to be either a single repository or an organization. Since I want to use it for multiple repositories, I created an organization.

To create an organization, just follow the official docs: [Creating a new organization from scratch](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/creating-a-new-organization-from-scratch).

If you have a personal repository that you want to use for this tutorial, you can move it to the newly craeted organization by following this guide: [Transferring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository).

## Deploy Actions Runner Controller

It is a pretty straightforward process to deploy ARC. Just follow the official guide: [Quickstart for Actions Runner Controller](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller).

> [!TIP]
> If you are planning to use ARC for actions that involve containerized workloads, make sure to include the following option in the `helm install` command for runner set:\
> `--set containerMode.type="dind"`\
> which enables Docker-in-Docker. It is required since action runners are docker containers themselves.

This will create two pods in the `arc-systems` namespace, one for the controller and one for the runner set. Once an action has requested to use the runner set, a pod will be created in the `arc-runners` namespace.

## Use ARC from your repository

If you followed the above guide, you should have a runner registered to your repository or organization. Now you can use it in your workflow file like this:

```yml
name: Deploy to Kubernetes

on:
  push:
    branches:
      - master

env:
  DOCKER_REPO: ${{ secrets.DOCKER_USERNAME }}/example

jobs:
  build:
    runs-on: ubuntu-latest

    outputs:
      tagname: ${{ steps.set-tag.outputs.dateTag }}

    steps:
      # Checkout the repository code
      - name: Checkout code
        uses: actions/checkout@v3

      # Log in to Docker Hub
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # Set date tag as a variable
      - name: Set date tag
        id: set-tag
        run: |
          tag=$(date +'%Y%m%d')
          echo "DATE_TAG=$tag" >> $GITHUB_ENV
          echo "dateTag=$tag" >> $GITHUB_OUTPUT

      # Build the Docker image with both tags
      - name: Build Docker image
        run: |
          docker build -t $DOCKER_REPO:release \
                       -t $DOCKER_REPO:${{ env.DATE_TAG }} .

      # Push both tags to Docker Hub
      - name: Push Docker image
        run: |
          docker push $DOCKER_REPO:release
          docker push $DOCKER_REPO:${{ env.DATE_TAG }}

  deploy:
    needs: [build]
    runs-on: jylab-runner-set

    steps:
      - name: Restart deployment
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
        uses: actions-hub/kubectl@master
        with:
          args: set image deployment/myself-deployment myself=${{ env.DOCKER_REPO }}:${{ needs.build.outputs.tagname }}
```

Here, the `build` step uses GitHub's runner to build and push the docker image. The `deploy` step uses the ARC runner that runs inside my Kubernetes cluster to update the deployment with the new image. It uses [actions-hub/kubectl](https://github.com/actions-hub/kubectl) to run `kubectl` commands.

For details about the `build` job, see [Using GitHub Actions to automatically build and push docker images]({{< ref "/post/github-actions-docker" >}}).

For the secrets in the above manifest, I chose to set them all on the organization level. `DOCKER_USERNAME` and `DOCKER_PASSWORD` are just string values, but the `KUBE_CONFIG` is a bit different. It is the content of the `~/.kube/config` base64 encoded. You can get it by running:
```bash
cat ~/.kube/config | base64
```

> [!TIP]
> For a HA cluster where the IP of master node is not static, you can use the hostname `kubernetes.default.svc` in the `KUBE_CONFIG` file. For example:
> ```yaml
> clusters:
> - cluster:
>     certificate-authority-data: ...
>     server: https://kubernetes.default.svc
> ```
> By leveraging the internal DNS of Kubernetes, we can avoid the need to update the `KUBE_CONFIG` secret every time the master node IP changes.

As for how to set these secrets, you can follow the official guide: [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions).

## Conclusion

Setting up my own GitHub Actions runner was pretty daunting at first, but ARC has made it quite a bit easier. It's awesome to have `kubectl` commands integrated into GitHub Actions.


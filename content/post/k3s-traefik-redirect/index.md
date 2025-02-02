---
date: 2025-02-01
title: Redirect http to https with k3s + Traefik
image: images/network.jpg
tags: [k3s, kubernetes, traefik, self-hosting]
categories: [self-hosting]
---

It is a common practice to redirect all http traffic to https. I had neglected it for so long, and finally did it (properly) today. Here's how I did it with the default k3s deployment that came with k3s.

> [!WARNING]
> This post has been updated. [Jump to the correct way](#the-correct-way).

## What NOT to do

Previously I tried to directly add an option to the Traefik deployment like this one:
```yaml
- --entrypoints.web.http.redirections.entryPoint.to=:443
```
to the `traefik` deployment in the `kube-system` namespace.

This worked, and I had just forgotten about it till today.

However, one day, I accidentally accessed my domain [http://junyi.me](http://junyi.me) without https, and it did not redirect me to https. \
Looking into the `traefik` deployment, I quickly realized the pod was restarted, and the option was lost.

It turns out that since the `traefik` deployment is managed by k3s using a **helm chart**, each time there is a problem with the deployment, k3s will automatically re-apply the helm chart, causing any manual changes to be lost.

## What NOT to do (part 2)

So I decided to sit down and learn about how helm charts work, and how to interact with them in k3s.

And turns out it's pretty simple. Like anything else in a kubernetes cluster, you can run commands like `kubectl get`, `kubectl describe`, and `kubectl edit` on helm charts. For instance, helm charts that are installed in the current namespace can be viewed with:
```bash
kubectl get helmcharts
```

So I just needed to update it with:
```bash
kubectl edit helmchart traefik -n kube-system
```

And add the following to the `spec.valuesContent` section:
```yaml
  ports:
    web:
      redirectTo:
        port: websecure
```

Save and exit, and the `traefik` pod will be restarted with the new configuration.

Available config values are well documented in the [values.yaml](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml) file on the official Traefik helm chart repository.

## The correct way

A few hours later, I checked my domain again, and it was again not redirecting to https. After some googling again, I finally learned the correct way to handle this. With k3s managing the `traefik` helm chart, we are not supposed to directly edit the deployment, **nor the helm chart**.

The correct way is to create a resource called `HelmChartConfig` in the `kube-system` namespace, and specify the values like above in the `spec.valuesContent` section.

Example:
```yaml
# traefik-custom-conf.yaml

apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      web:
        redirectTo:
          port: websecure
```

Then apply it with:
```bash
kubectl apply -f traefik-custom-conf.yaml
```

This will create a `HelmChartConfig` resource, and subsequently restart the `traefik` pod with the new configuration.

## Confirming the change

To confirm it's working, I accessed [http://junyi.me](http://junyi.me) again, and this time it redirected me to [https://junyi.me](https://junyi.me).

For a real test, I restarted the `traefik` deployment:
```bash
kubectl rollout restart deployment traefik -n kube-system
```

And the redirection was still there.

## Conclusion

This was a good opportunity for me to be familiar with helm charts, how to interact with them, and where to look for resources like documentation. I'm sure it will help me in the future when I need to customize more stuff in my cluster, or even create my own helm charts.


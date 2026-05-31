# Cert-manager DNSMadeEasy webhook

This is a cert-manager webhook for the DNSMadeEasy. It is used to get Let´s encrypt certificates using DNSMadeEasy as DNS resolver.

## Installation
Install from the command line
```bash
docker pull ghcr.io/khumbal/dnsmadeeasy-webhook:latest
```

Use as base image in Dockerfile:
```
FROM ghcr.io/khumbal/dnsmadeeasy-webhook:latest
```

## Deploying the webhook

Use the [angelnu helm charts](https://github.com/angelnu/helm-charts/tree/main/charts/apps/dnsmadeeasy-webhook)

## Building the code

```bash
docker build -t dnsmadeeasy-webhook .
```

or if you want build and test the code:

```bash
docker build --build-arg TEST_ZONE_NAME=<your domain>. -t dnsmadeeasy-webhook .
```

Before you can run the test suite, you need to set your `apykey.yaml`with your DNSMadeEasy API key. See [instructions](testdata/dnsmadeeasy/README.md).

## Create a new release

Use the GitHub releases to tag a new version. The workflow should then build and upload a new version matching the tag.

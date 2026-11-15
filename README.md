# Inception of Things (IoT)

*This project has been created as part of the 42 curriculum by bchokri oettaqui cmaami.*

## Description

Inception of Things is a System Administration project that introduces Kubernetes through K3s, K3d, Vagrant, and Argo CD.

The goal is to create virtual machines, deploy web applications in a Kubernetes cluster, and automate application deployment using GitHub and Argo CD.

## Parts

### Part 1: K3s and Vagrant

- Create two virtual machines using Vagrant.
- Configure a K3s cluster with one Server and one ServerWorker.
- Assign dedicated IP addresses:
  - Server: `192.168.56.110`
  - ServerWorker: `192.168.56.111`
- Configure SSH access without a password.
- Install and configure K3s and kubectl.

### Part 2: K3s and Applications

- Create one virtual machine with K3s in server mode.
- Deploy three web applications.
- Configure Ingress to route requests based on the hostname.
- Use three different hostnames:
  - `app1.com`
  - `app2.com`
  - `app3.com`
- Configure multiple replicas for the second application.
- Use `app3` as the default application.

### Part 3: K3d and Argo CD

- Install Docker and K3d.
- Create a Kubernetes cluster using K3d.
- Install and configure Argo CD.
- Create two namespaces:
  - `argocd`
  - `dev`
- Deploy an application from a public GitHub repository.
- Configure automatic deployment using Argo CD.
- Manage two application versions: `v1` and `v2`.
- Update the application version through GitHub and verify the deployment.

### Bonus: GitLab

- Deploy GitLab locally.
- Configure GitLab to work with the Kubernetes cluster.
- Create a dedicated `gitlab` namespace.
- Make the Part 3 deployment workflow work with GitLab.

## Technologies

- Linux
- Vagrant
- VirtualBox
- K3s
- K3d
- Kubernetes
- kubectl
- Docker
- Argo CD
- GitHub
- GitLab (Bonus)

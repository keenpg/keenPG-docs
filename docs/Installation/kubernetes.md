# Installation of keenPGO on Kubernetes Engine installed via RKE2

In this documentation you will be deploying  keenPGO on
[Rancher Kubernetes Engine (RKE2) :octicons-link-external-16:](https://docs.rke2.io/).
RKE2 is a Kubernetes distribution that you can run standalone or
manage with the [Rancher :octicons-link-external-16:](https://ranchermanager.docs.rancher.com/)
Kubernetes management platform.

This document assumes basic familiarity with the platform. Please consult the user manual for further information. [RKE2 official documentation :octicons-link-external-16:](https://docs.rke2.io/).

## Prerequisites

Ensure you have the following setup and credentials::

1. **Linux hosts** compliant with the [RKE2 requirements :octicons-link-external-16:](https://docs.rke2.io/install/requirements). For production-grade environments, deploy a minimum of 3 nodes to allow the Operator to distribute workloads as outlined in [system requirements](System-Requirements.md).

2. **Root or sudo** access on each host to install and start RKE2 services.

3. **kubectl** to manage and deploy applications on Kubernetes. Install it
    [following the official installation instructions :octicons-link-external-16:](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
    RKE2 also ships a `kubectl` binary under `/var/lib/rancher/rke2/bin/` on
    server nodes.


## Create the RKE2 cluster

You can create the cluster [with the RKE2 installation script :octicons-link-external-16:](https://docs.rke2.io/install/quickstart) or [provision it
through Rancher :octicons-link-external-16:](https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/launch-kubernetes-with-rancher). Both approaches give you a standard Kubernetes API endpoint
that the Operator uses.


## Configure kubectl access

On a server node, RKE2 writes the kubeconfig to `/etc/rancher/rke2/rke2.yaml`.
Copy it to your workstation and point `kubectl` at it:

```bash
mkdir -p ~/.kube
sudo cat /etc/rancher/rke2/rke2.yaml > ~/.kube/rke2.yaml
export KUBECONFIG=~/.kube/rke2.yaml
```

If you connect from a remote machine, replace `127.0.0.1` in the kubeconfig
`server:` URL with the reachable address of your RKE2 server node.

Verify that the nodes are ready:

```bash
kubectl get nodes
```

## Configure storage

keenPGO needs PersistentVolumes for database data. Confirm
that your cluster has a default StorageClass:

```bash
kubectl get storageclass -A
```

RKE2 does not always ship a default StorageClass. For testing, you can install via local storage or NFS CSI driver for dev
the [Local Path Provisioner :octicons-link-external-16:](https://github.com/rancher/local-path-provisioner).
For production, use a CSI driver appropriate for your infrastructure, such as
[Longhorn :octicons-link-external-16:](https://longhorn.io/) when you manage the cluster with Rancher.

## Install the Operator and deploy your PostgreSQL cluster

1. Create the Kubernetes namespace for your cluster. It is a good practice to isolate workloads in Kubernetes by installing the Operator in a custom namespace.

    ```bash
    kubectl create ns keenpg-operator
    ```


2. Deploy the Operator using the following command:

    ```bash
    git clone https://github.com/keenpg/keenpg-operator.git -b 6.0
    
    kubectl apply --server-side -f config/keenpg -n keenpg-operator
    ```


    At this point, the Operator Pod is up and running.

3. Once the Operator has been started and console Pod and Console DB pods are up, and you can deploy DB instance via CLI or UI:
   Sample DB Yaml with name database.yaml.
```yaml
apiVersion: keenpg.io/v1beta1
kind: KeenPGCluster
metadata:
  name: cluster1
spec:
  postgresVersion: 17
  instances:
    - dataVolumeClaimSpec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
  backups:
    pgbackrest:
      repos:
        - name: repo1
          volume:
            volumeClaimSpec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 1Gi
```

    ```bash
    kubectl apply -f database.yaml 
    ```

  

    ```bash
    kubectl get keenpg 
    ```

    
## Production ready Sample DB yaml for PROD workload.

Please find the sample production DB cluster yaml which is being by our customer for big database size and high workload .

```yaml
apiVersion: keenpg.io/v1beta1
kind: KeenPGCluster
metadata:
  name: prodcluster
spec:
  postgresVersion: 17
  instances:
    - dataVolumeClaimSpec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
  backups:
    pgbackrest:
      repos:
        - name: repo1
          volume:
            volumeClaimSpec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 1Gi
```


!!! warning

    This is a suggestion only, to understand the production DB Yaml only!

## Verifying the cluster operation

Documentation team is working on it.



## Removing the RKE2 cluster

To delete a manually installed RKE2 cluster, run the uninstall script on each
node (agent nodes first, then server nodes):

```bash
/usr/local/bin/rke2-uninstall.sh
```


!!! warning

    After deleting the cluster, all data stored in it will be lost!

# Install keenPGO for PostgreSQL on Minikube

Installing the keenPGO on [Minikube :octicons-link-external-16:](https://github.com/kubernetes/minikube)
is the easiest way to try it for dev environment and learning purpose. 

Minikube runs
Kubernetes on GNU/Linux, Windows, or macOS system using a system-wide
hypervisor, such as VirtualBox, KVM/QEMU, VMware Fusion or Hyper-V. Using it is
a popular way to test Kubernetes application locally prior to deploying it on a
cloud.

This document describes how to deploy the Operator and Percona Distribution
for PostgreSQL on Minikube.

## Set up Minikube {.power-number}

1. [Install Minikube :octicons-link-external-16:](https://kubernetes.io/docs/tasks/tools/install-minikube/), using a way recommended for your system. This includes the installation of the following three components:

    1. kubectl tool,

    2. a hypervisor, if it is not already installed,

    3. actual minikube package

    
2. After the installation, initialize and start the Kubernetes cluster. The parameters we pass for the following command increase the virtual machine limits for the CPU cores, memory, and disk, to ensure stable work of the Operator:

    ```bash
    minikube start --memory=5120 --cpus=4 --disk-size=30g
    ```
    ```bash
    Minikube with Driver docker
    minikube start --memory=5120 --cpus=4 --disk-size=30g --driver docker
    ```
    

    This command downloads needed virtualized images, then initializes and runs the
    cluster.

3. After Minikube is successfully started, you can optionally run the
    Kubernetes dashboard, which visually represents the state of your cluster.
    Executing `minikube dashboard` starts the dashboard and opens it in your
    default web browser.

## Deploy the keenPGO {.power-number}

1. Create the Kubernetes namespace for your cluster. It is a good practice to isolate workloads in Kubernetes by installing the Operator in a custom namespace. For example, let's name it `keenpgo-operator`:

    ```bash
    kubectl create namespace keenpgo-operator
    ```

    ??? example "Expected output"

        ``` {.text .no-copy}
        namespace/keenpgo-operator was created
        ```

    We will use this namespace further on in this document. If you used another name, make sure to replace it in the following commands.

2. Deploy the Operator using the following command:

    ```bash
    kubectl apply --server-side -f https://raw.githubusercontent.com/keenpgo/keenpgo-postgresql-operator/v{{ release }}/deploy/bundle.yaml -n keenpgo-operator
    ```

    ??? example "Expected output"

        --8<-- "kubectl-apply-bundle-response.txt"

    As the result you have the Operator Pod up and running.

3. Deploy keenPGO for PostgreSQL:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/keenpgo/keenpgo-postgresql-operator/v{{ release }}/deploy/cr.yaml -n keenpgo-operator
    ```

    ??? example "Expected output"

        ```{.text .no-copy}
        keenpgpgcluster.pgv2.keenpgo.com/cluster1 created
        ```



4. The DB cluster creation process may take some time. When the process is over your
    cluster will obtain the `ready` status. You can check it with the following
    command:
   
    ```bash
    kubectl get keenpgcluster -n keenpgo-operator
    ```
    
    ??? example "Expected output"
   
        --8<-- "kubectl-get-pg-response.txt"






# Quickstart

This guide takes you from an empty Kubernetes cluster to a running
PostgreSQL database managed by keenPGO. It should take about ten minutes.

!!! tip "Just testing?"
    No cluster yet? Start a local one with [Minikube](installation/minikube.md)
    and come back here.

## Prerequisites for quickstart

- A running Kubernetes cluster, above version 1.31.x
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) configured to reach the cluster
- You must have permission to create namespaces and custom resource definitions required for keenPGO
- The `psql` client, if you want to connect from your own machine to perform operations on created keenPGO database instance.

Check that `kubectl` can reach your cluster:

```bash
kubectl get nodes
```

## Step 1: Install the operator

Create a namespace and install keenpgo-operator into it:

```bash
kubectl create namespace keenpgo-operator
kubectl apply -n keenpgo-operator -f <operator-manifest-url>
```

Prefer Helm, or running on OpenShift? See the
[installation guides](Installation/index.md).

Wait until the operator is running:

```bash
kubectl get pods -n keenpgo-operator
```

The operator pod should report `Running` and `1/1` ready:

```text
NAME                       READY   STATUS    RESTARTS   AGE
<operator-pod-name>        1/1     Running   0          30s
```

## Step 2: Create a PostgreSQL cluster

Save the following as `my-cluster.yaml`:

```yaml
apiVersion: <api-group>/<version>
kind: keenpgcluster
metadata:
  name: my-cluster
  namespace: keenpg-test
spec:
  postgresVersion: 16
  instances:
    - replicas: 2
      storage:
        size: 5Gi
```

Apply it:

```bash
kubectl apply -f my-cluster.yaml
```

Watch the cluster come up:

```bash
kubectl get pods -n keenpg-test --watch
```

When the database pods show `Running` and ready, the cluster is up. Press
`Ctrl+C` to stop watching.

## Step 3: Find your credentials

keenPGO creates a user for the cluster and stores the credentials in a
Kubernetes Secret named `<secret-name-pattern>`.

List the available fields:

```bash
kubectl get secret <secret-name> -n keenpg-test -o jsonpath='{.data}' | tr ',' '\n'
```

The Secret contains these values:

| Key | Description |
|---|---|
| `user` | The database user name |
| `password` | The password for that user |
| `dbname` | The default database |
| `host` | The service name of the primary instance |
| `port` | The port the database listens on |
| `uri` | A ready-to-use connection string |

Read a single value, for example the password:

```bash
kubectl get secret <secret-name> -n keenpg \
  -o jsonpath='{.data.password}' | base64 --decode
```

!!! warning
    Treat these credentials like any other secret. Don't paste them into
    chat, tickets or source control.

## Step 4: Connect to the database

=== "Port-forward (from your machine)"

    In one terminal, forward the database port:

    ```bash
    kubectl port-forward -n keenpg svc/<primary-service-name> 5432:5432
    ```

    In a second terminal, connect with `psql`:

    ```bash
    PGPASSWORD=$(kubectl get secret <secret-name> -n keenpg -o jsonpath='{.data.password}' | base64 --decode) \
    psql -h localhost -U <user> -d <dbname>
    ```

=== "From inside the cluster"

    Pods in the same cluster can use the connection string stored in the
    Secret directly:

    ```bash
    kubectl get secret <secret-name> -n keenpg \
      -o jsonpath='{.data.uri}' | base64 --decode
    ```

Once connected, test it:

```sql
SELECT version();
```

## Step 5: Connect an application

Applications should read connection details from the Secret rather than
hard-coding them. Add environment variables to your Deployment that
reference the Secret:

```yaml
env:
  - name: DB_HOST
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: host
  - name: DB_PORT
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: port
  - name: DB_NAME
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: dbname
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: user
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: password
```

## Clean up

To remove the test cluster and the operator:

```bash
kubectl delete -f my-cluster.yaml
kubectl delete -n keenpg -f <operator-manifest-url>
kubectl delete namespace keenpg
```

## Next steps

- [Back up and restore your data](backups.md)
- [Secure your cluster](security.md)
- [Troubleshoot common problems](troubleshooting.md)

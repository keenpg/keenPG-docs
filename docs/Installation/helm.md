# keenpg-operator Helm chart

Installs the KeenPG operator (`KeenPGCluster`, `PGUpgrade`, `PGAdmin` CRDs) and,
optionally, the KeenPG web console with its own PostgreSQL database.

This chart is the Helm equivalent of the kustomize targets in `config/`:

| kustomize            | Helm                                              |
|----------------------|---------------------------------------------------|
| `config/default`     | defaults (operator + CRDs + RBAC)                 |
| `config/keenpg`      | `--set console.enabled=true`                      |
| `config/singlenamespace` | `--set rbac.clusterWide=false`                |

## Install

```bash
helm install keenpg ./keenpg-operator \
  --namespace keenpg-operator --create-namespace
```

With the web console:

```bash
helm install keenpg ./keenpg-operator -n keenpg-operator --create-namespace \
  --set console.enabled=true
```

Private `quay.io/keenpg` repositories:

```bash
helm install keenpg ./keenpg-operator -n keenpg-operator --create-namespace \
  --set pullSecret.create=true \
  --set-file pullSecret.dockerconfigjson=$HOME/.config/containers/auth.json
```

Console login (a random admin password is generated unless you set
`console.admin.password`):

```bash
kubectl -n keenpg-operator get secret keenpgo-console-admin \
  -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n keenpg-operator port-forward svc/keenpgo-console 8080:80
```



## Main values

| Key | Default | Description |
|-----|---------|-------------|
| `operator.image.repository` / `.tag` | `quay.io/keenpg/keenpgo` / `v6.0` | Operator image |
| `operator.debug` | `false` | `KEENPG_DEBUG` (the kustomize manifest ships `true`) |
| `operator.featureGates` | `""` | `KEENPG_FEATURE_GATES` |
| `rbac.clusterWide` | `true` | `false` = Role/RoleBinding + `KEENPG_TARGET_NAMESPACE` |
| `rbac.name` | `keenpg-operator` | ClusterRole name (change for multiple installs) |
| `relatedImages.*` | see `values.yaml` | `RELATED_IMAGE_*` images for Postgres, pgBackRest, pgBouncer, exporter, upgrade, pgAdmin, collector |
| `pullSecret.*` | off | Create/use the registry pull Secret |
| `console.enabled` | `false` | Deploy console + console DB |
| `console.service.type` | `ClusterIP` | Use `NodePort` + `nodePort: 30080` for the upstream behaviour |
| `console.ingress.*` | off | Optional Ingress |
| `console.db.storage.size` | `10Gi` | Console DB volume |

## Notes

- The console DB password Secret (`keenpgo-console-db`) is generated once and
  kept on `helm uninstall` (`helm.sh/resource-policy: keep`), because the
  PVC also survives and the database keeps its first password. Delete both to
  start from scratch.
- Console, console DB and their Secret/ConfigMap/PVC names are fixed (the
  console finds them by name): one console per namespace.
- The monitoring stack under `config/monitoring` (Prometheus, Grafana,
  Alertmanager) is not part of this chart.

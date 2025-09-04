# Rancher Get Info

A **very basic** script to retrieve information about Projects, Namespaces, Users under Projects, and their corresponding permissions from clusters in Rancher.

## Usage

1. Download the all cluster's kubeconfig file from Rancher UI.
2. Copy the kubeconfig file to the same directory as the `get_info.sh` script.
3. Run the `get_info.sh` script.

```bash
bash get_info.sh
```

The Output looks like this:

```bash
...
Cluster: my-cluster, Project: Default, Users: warner, Role: project-owner, Namespace: default
...
```
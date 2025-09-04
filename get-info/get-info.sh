#!/bin/bash

# 上下文切到 Local 集群
export KUBECONFIG=$(pwd)/local.yaml

# 遍历所有 Cluster
for cluster in $(kubectl get clusters.management.cattle.io --no-headers | awk '{ print $1 }');do
    clusterName=$(kubectl get clusters.management.cattle.io "$cluster" -o jsonpath='{.spec.displayName}')

    # 遍历所有 Project
    for project in $(kubectl -n "$cluster" get projects.management.cattle.io --no-headers | awk '{ print $1 }');do
        projectName=$(kubectl -n "$cluster" get projects.management.cattle.io "$project" -o jsonpath='{.spec.displayName}')

        # 上下文切到下游集群
        export KUBECONFIG=$(pwd)/$clusterName.yaml

        # 获取该 Project 的所有 Namespace
        for namespace in $(kubectl get ns --no-headers | awk '{ print $1 }');do
            kubectl get ns "$namespace" -L "field.cattle.io/projectId" | grep "$project"  >/dev/null
            # 检查 Namespace 是否属于该 Project
            if [ $? -eq 0 ];then
                namespaces+=("$namespace")
            fi
        done

        # 上下文切回 Local 集群
        export KUBECONFIG=$(pwd)/local.yaml

        # 遍历所有 ProjectRoleTemplateBinding
        for prtb in $(kubectl -n "$project" get projectroletemplatebindings.management.cattle.io --no-headers | awk '{ print $1 }');do
            # 获取 User 和 Role
            userID=$(kubectl -n "$project" get projectroletemplatebindings.management.cattle.io "$prtb" -o jsonpath='{.userName}')
            userName=$(kubectl get users.management.cattle.io "$userID" -o jsonpath='{.displayName}')
            role=$(kubectl -n "$project" get projectroletemplatebindings.management.cattle.io "$prtb" -o jsonpath='{.roleTemplateName}')

            # 输出信息
            echo "Cluster: $clusterName, Project: $projectName, User: $userName, Role: $role, Namespace: ${namespaces[@]}"
        done

    done
    
done
#!/bin/bash

NAMESPACE="cattle-impersonation-system"

echo "Namespace: $NAMESPACE"

# Get all secrets referenced by ServiceAccounts via the rancher.io/service-account.secret-ref annotation
kubectl -n "$NAMESPACE" get sa -o jsonpath='{range .items[*]}{.metadata.annotations.rancher\.io/service-account\.secret-ref}{"\n"}{end}' | awk -F/ '{print $NF}' | grep -v '^$' > /tmp/annotation_secrets.txt

# Get all secrets referenced through the native secrets array.
kubectl -n "$NAMESPACE" get sa -o jsonpath='{range .items[*]}{range .secrets[*]}{.name}{"\n"}{end}{end}' | grep -v '^$' > /tmp/array_secrets.txt

cat /tmp/annotation_secrets.txt /tmp/array_secrets.txt | sort | uniq > /tmp/referenced_secrets.txt

REF_COUNT=$(cat /tmp/referenced_secrets.txt | wc -l)
echo "Found $REF_COUNT secret(s) referenced by active ServiceAccounts."

# Get all secrets of type kubernetes.io/service-account-token in the namespace
kubectl -n "$NAMESPACE" get secret --field-selector type=kubernetes.io/service-account-token --no-headers | awk '{ print $1 }' | sort | uniq > /tmp/all_token_secrets.txt

TOTAL_COUNT=$(cat /tmp/all_token_secrets.txt | wc -l)
echo "Found $TOTAL_COUNT service-account-token secret(s) in total."

# Compare all secrets against the referenced list; write unreferenced ones to the deletion list
echo "Getting stale secrets..."

STALE_COUNT=0
> /tmp/secrets_to_delete.txt

while read -r secret; do
    if [ -z "$secret" ]; then continue; fi

    if ! grep -qw "^${secret}$" /tmp/referenced_secrets.txt; then
        echo "$secret" >> /tmp/secrets_to_delete.txt
        ((STALE_COUNT++))
    fi
done < /tmp/all_token_secrets.txt

STALE_COUNT=$(cat /tmp/secrets_to_delete.txt | wc -l)
echo "Summary: Found $STALE_COUNT stale secret(s)."

# Generate the deletion command
if [ "$STALE_COUNT" -gt 0 ]; then
    echo ""
    echo "The list of stale secrets has been saved to /tmp/secrets_to_delete.txt"
    echo "To delete them, run the following command:"
    echo ""
    echo "xargs -a /tmp/secrets_to_delete.txt kubectl -n $NAMESPACE delete secret"
    echo ""
else
    echo "No stale secrets to delete."
fi

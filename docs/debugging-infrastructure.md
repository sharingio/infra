# Infrastructure Debugging Reference

## 1. OCI (Oracle Cloud Infrastructure) Nodes

### List all instances
```bash
# All instances in compartment
oci compute instance list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --query 'data[*].{"name":"display-name","state":"lifecycle-state","id":"id"}' \
  --output table

# Only running instances
oci compute instance list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --lifecycle-state RUNNING \
  --output table
```

### Get instance details
```bash
# Get specific instance
oci compute instance get --instance-id <ocid>

# Get instance VNIC (network) attachments
oci compute vnic-attachment list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --instance-id <ocid>

# Get VNIC details (IP addresses)
oci network vnic get --vnic-id <vnic-ocid>
```

### Instance actions
```bash
# Reboot instance
oci compute instance action --action SOFTRESET --instance-id <ocid>

# Stop instance
oci compute instance action --action STOP --instance-id <ocid>

# Start instance
oci compute instance action --action START --instance-id <ocid>

# Force stop (hard reset)
oci compute instance action --action RESET --instance-id <ocid>
```

### Check serial console output
```bash
# Get console history (boot logs)
oci compute console-history capture \
  --instance-id <ocid>

# List console histories
oci compute console-history list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --instance-id <ocid>

# Get console content
oci compute console-history get-content \
  --console-history-id <history-ocid>
```

### Network Load Balancer
```bash
# List NLBs
oci nlb network-load-balancer list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia

# Get NLB details
oci nlb network-load-balancer get --network-load-balancer-id <nlb-ocid>

# Get backend set health
oci nlb backend-set-health get \
  --network-load-balancer-id <nlb-ocid> \
  --backend-set-name <name>
```

### Security Lists / Network Security Groups
```bash
# List security lists in VCN
oci network security-list list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --vcn-id <vcn-ocid>

# Get security list rules
oci network security-list get --security-list-id <ocid>
```

---

## 2. Talos Nodes

### Prerequisites
```bash
# Talosconfig location
export TALOSCONFIG=/tmp/talosconfig

# Control plane IPs (from terraform output)
tofu output -json | jq -r '.controlplane_ips.value[]'
```

### List cluster members
```bash
talosctl --talosconfig /tmp/talosconfig -n <control-plane-ip> get members
```

### Check node services
```bash
# List all services
talosctl --talosconfig /tmp/talosconfig -n <node-ip> services

# Get specific service status
talosctl --talosconfig /tmp/talosconfig -n <node-ip> service kubelet
talosctl --talosconfig /tmp/talosconfig -n <node-ip> service etcd
talosctl --talosconfig /tmp/talosconfig -n <node-ip> service apid
```

### Read machine configuration
```bash
# Get running config
talosctl --talosconfig /tmp/talosconfig -n <node-ip> get machineconfig -o yaml

# Get specific config section
talosctl --talosconfig /tmp/talosconfig -n <node-ip> read /system/state/config.yaml
```

### Logs and diagnostics
```bash
# Kernel messages (dmesg)
talosctl --talosconfig /tmp/talosconfig -n <node-ip> dmesg

# Service logs
talosctl --talosconfig /tmp/talosconfig -n <node-ip> logs kubelet
talosctl --talosconfig /tmp/talosconfig -n <node-ip> logs etcd
talosctl --talosconfig /tmp/talosconfig -n <node-ip> logs containerd

# Follow logs
talosctl --talosconfig /tmp/talosconfig -n <node-ip> logs -f kubelet
```

### Cluster health
```bash
# Check etcd health
talosctl --talosconfig /tmp/talosconfig -n <control-plane-ip> etcd members
talosctl --talosconfig /tmp/talosconfig -n <control-plane-ip> etcd status

# Check kubelet health
talosctl --talosconfig /tmp/talosconfig -n <node-ip> health
```

### Maintenance operations
```bash
# Upgrade node
talosctl --talosconfig /tmp/talosconfig -n <node-ip> upgrade --image <image-url>

# Reboot node
talosctl --talosconfig /tmp/talosconfig -n <node-ip> reboot

# Shutdown node
talosctl --talosconfig /tmp/talosconfig -n <node-ip> shutdown

# Reset node (wipe and reinstall)
talosctl --talosconfig /tmp/talosconfig -n <node-ip> reset --graceful=false
```

### Apply configuration changes
```bash
# Patch config
talosctl --talosconfig /tmp/talosconfig -n <node-ip> patch machineconfig --patch-file <patch.yaml>

# Apply new config
talosctl --talosconfig /tmp/talosconfig -n <node-ip> apply-config --file <config.yaml>
```

---

## 3. Kubernetes Nodes

### Prerequisites
```bash
export KUBECONFIG=/tmp/kubeconfig
```

### List nodes
```bash
# All nodes
kubectl get nodes -o wide

# With labels
kubectl get nodes --show-labels

# Specific node details
kubectl describe node <node-name>
```

### Node status and conditions
```bash
# Get node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[-1].type}{"\t"}{.status.conditions[-1].status}{"\n"}{end}'

# Check node resources
kubectl top nodes

# Check node capacity
kubectl describe nodes | grep -A 5 "Capacity:"
```

### Debug node issues
```bash
# Check kubelet logs (via talosctl)
talosctl --talosconfig /tmp/talosconfig -n <node-ip> logs kubelet

# Check system pods on node
kubectl get pods -A -o wide --field-selector spec.nodeName=<node-name>

# Check events for node
kubectl get events --field-selector involvedObject.name=<node-name>
```

### Cordon/Drain nodes
```bash
# Cordon (prevent new pods)
kubectl cordon <node-name>

# Drain (evict pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon (allow scheduling)
kubectl uncordon <node-name>
```

---

## 4. Common Debugging Scenarios

### Cluster not reachable
1. Check OCI instances are RUNNING
2. Check NLB health status
3. Check security list allows port 443/6443
4. Try direct IP access: `curl -sk https://<control-plane-ip>:6443/healthz`

### Talos API not responding
1. Check OCI security list allows port 50000
2. Check instance serial console for boot issues
3. Try reboot via OCI: `oci compute instance action --action SOFTRESET`

### Pods can't connect to API server
1. Check Cilium pods are healthy: `kubectl get pods -n kube-system -l k8s-app=cilium`
2. Check kube-proxy: `kubectl get pods -n kube-system -l k8s-app=kube-proxy`
3. Check kubernetes endpoints: `kubectl get endpoints kubernetes`
4. Test from pod: `kubectl exec -it <pod> -- curl -sk https://kubernetes.default/healthz`

### Node NotReady
1. Check kubelet logs via talosctl
2. Check node conditions: `kubectl describe node <name>`
3. Check CNI (Cilium) pods on that node
4. Check if node is being upgraded/rebooted

---

## 5. Quick Reference - Current Cluster

### IPs
- **API Server NLB**: 161.153.25.21:443
- **DNS (reserved)**: 161.153.15.215
- **Ingress (reserved)**: 144.24.33.179
- **Wireguard (reserved)**: 132.226.67.218

### Control Plane Nodes
| Name | Internal IP | Public IP |
|------|-------------|-----------|
| sharingio-control-plane-assured-leopard | 10.0.10.36 | (check tofu output) |
| sharingio-control-plane-beloved-lizard | 10.0.10.101 | (check tofu output) |
| sharingio-control-plane-handy-monkey | 10.0.10.53 | (check tofu output) |

### Config Files
- Kubeconfig: `/tmp/kubeconfig`
- Talosconfig: `/tmp/talosconfig`
- Terraform state: `/disk/home/ii/infra/terraform.tfstate`

### Get control plane public IPs
```bash
cd /disk/home/ii/infra
tofu output -json | jq '.controlplane_ips.value'
```

---

## 6. Serial Console Access (OCI)

OCI provides two key serial console features:
1. **Live console connection** - SSH to the serial console in real-time
2. **Console history capture** - Retrieve historical boot logs (including after crashes!)

### Prerequisites
You need an SSH key pair configured in OCI Console settings for live connections.

### Connect to live serial console
```bash
# Create SSH connection to serial console
# Format: ssh -o ProxyCommand='ssh -W %h:%p -p 443 ocid1.instanceconsoleconnection.oc1...<ocid>@instance-console.<region>.oci.oraclecloud.com' ocid1.instance.oc1...<instance_ocid>

# First, create a console connection
oci compute instance-console-connection create --instance-id <instance_ocid>

# Get connection details
oci compute instance-console-connection list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia

# The output includes SSH connection string
```

### View HISTORICAL console output (boot logs)

This is extremely useful for debugging boot issues, kernel panics, or understanding
what happened when a node becomes unreachable!

```bash
# Step 1: Get instance ID (by name)
INSTANCE_ID=$(oci compute instance list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --query 'data[?"display-name"==`sharingio-control-plane-handy-monkey`].id | [0]' \
  --raw-output)
echo "Instance ID: $INSTANCE_ID"

# Step 2: Capture console history (triggers OCI to save current console buffer)
HISTORY_ID=$(oci compute console-history capture \
  --instance-id $INSTANCE_ID \
  --query 'data.id' --raw-output)
echo "Console History ID: $HISTORY_ID"

# Step 3: Wait a few seconds for capture to complete
sleep 5

# Step 4: Download the console output
oci compute console-history get-content \
  --instance-console-history-id $HISTORY_ID \
  --file /tmp/console-history.txt

# Step 5: View the output
less /tmp/console-history.txt
# or search for errors
grep -i "error\|panic\|fail" /tmp/console-history.txt
```

### List previous console captures
```bash
# See all captured console histories for an instance
oci compute console-history list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia \
  --instance-id $INSTANCE_ID \
  --query 'data[*].{id:id,"time-created":"time-created"}' \
  --output table
```

### Quick one-liner to get console logs for a node
```bash
# Get console output for node by name
get_console() {
  local NAME="$1"
  local COMPARTMENT="ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia"
  local IID=$(oci compute instance list --compartment-id $COMPARTMENT --query "data[?\"display-name\"==\`$NAME\`].id | [0]" --raw-output)
  local HID=$(oci compute console-history capture --instance-id $IID --query 'data.id' --raw-output)
  sleep 3
  oci compute console-history get-content --instance-console-history-id $HID --file /tmp/${NAME}-console.txt
  echo "Console saved to /tmp/${NAME}-console.txt"
}

# Usage:
get_console "sharingio-control-plane-handy-monkey"
tail -100 /tmp/sharingio-control-plane-handy-monkey-console.txt
```

---

## 7. Talos Console & Dashboard

### Interactive Talos Dashboard
```bash
# Launch Talos dashboard (requires terminal with cursor support)
talosctl --talosconfig /tmp/talosconfig -n <node-ip> dashboard
```

### Monitor in tmux session
```bash
# Create tmux session for monitoring
tmux new-session -d -s talos-monitor

# Window 0: Talos dashboard on control plane
tmux send-keys -t talos-monitor:0 'talosctl --talosconfig /tmp/talosconfig -n 132.226.106.123 dashboard' Enter

# Window 1: Follow kubelet logs
tmux new-window -t talos-monitor
tmux send-keys -t talos-monitor:1 'talosctl --talosconfig /tmp/talosconfig -n 132.226.106.123 logs -f kubelet' Enter

# Window 2: Kubernetes watch
tmux new-window -t talos-monitor
tmux send-keys -t talos-monitor:2 'watch -n5 "KUBECONFIG=/tmp/kubeconfig kubectl get nodes; echo; kubectl get pods -A | head -30"' Enter

# Attach to session
tmux attach -t talos-monitor
```

---

## 8. tmux Sessions for Long-Running Commands

### Create monitoring session
```bash
# Create main monitoring session
tmux new-session -d -s infra-monitor

# Pane layout with multiple views
tmux split-window -h -t infra-monitor
tmux split-window -v -t infra-monitor:0.0
tmux split-window -v -t infra-monitor:0.1

# Pane 0: Node status watch
tmux send-keys -t infra-monitor:0.0 'watch -n10 "KUBECONFIG=/tmp/kubeconfig kubectl get nodes -o wide"' Enter

# Pane 1: Pod status watch
tmux send-keys -t infra-monitor:0.1 'watch -n10 "KUBECONFIG=/tmp/kubeconfig kubectl get pods -A --sort-by=.metadata.creationTimestamp | tail -20"' Enter

# Pane 2: OCI instance status
tmux send-keys -t infra-monitor:0.2 'watch -n30 "oci compute instance list --compartment-id ocid1.tenancy.oc1..aaaaaaaamz7ywh3epitrng2d5a7rj7o6thfwjvz72n4hg2apiq7mvj5rpoia --query \"data[*].{name:\\\"display-name\\\",state:\\\"lifecycle-state\\\"}\" --output table 2>/dev/null"' Enter

# Pane 3: Shell for commands
tmux send-keys -t infra-monitor:0.3 'export KUBECONFIG=/tmp/kubeconfig' Enter

tmux attach -t infra-monitor
```

### Quick tmux commands reference
```bash
# List sessions
tmux ls

# Attach to session
tmux attach -t <session-name>

# Detach from session
# Press Ctrl+b, then d

# Kill session
tmux kill-session -t <session-name>

# Create new window in session
tmux new-window -t <session-name>

# Switch between windows
# Press Ctrl+b, then window number (0-9)

# Switch between panes
# Press Ctrl+b, then arrow keys
```

### Run terraform in background tmux
```bash
# Create session for terraform
tmux new-session -d -s terraform
tmux send-keys -t terraform 'cd /disk/home/ii/infra && tofu apply -auto-approve 2>&1 | tee tofu-apply.log' Enter

# Check on progress
tmux attach -t terraform
# or view log
tail -f /disk/home/ii/infra/tofu-apply.log
```

---

## 9. Current Control Plane Public IPs

| Name | Internal IP | Public IP |
|------|-------------|-----------|
| sharingio-control-plane-assured-leopard | 10.0.10.36 | 132.226.106.123 |
| sharingio-control-plane-beloved-lizard | 10.0.10.101 | 129.146.106.207 |
| sharingio-control-plane-handy-monkey | 10.0.10.53 | 137.131.27.255 |

### Quick access commands
```bash
# Set common variables
export TALOSCONFIG=/tmp/talosconfig
export KUBECONFIG=/tmp/kubeconfig
export CP1=132.226.106.123  # assured-leopard
export CP2=129.146.106.207  # beloved-lizard
export CP3=137.131.27.255   # handy-monkey

# Example: Check all control planes
for ip in $CP1 $CP2 $CP3; do echo "=== $ip ==="; talosctl -n $ip services | head -5; done
```

# Create a Kubernetes cluster with AKS (Azure Kubernetes Service) using Kubenet networking and Log Analytics via Terraform

By default, AKS clusters use `kubenet`. With `kubenet`, nodes get an IP address from the Azure virtual network subnet.
Pods receive an IP address from a logically different address space to the Azure virtual network subnet of the nodes.
Therefore, NAT (Network Address Translation) is then configured so that pods are able to reach resources on the Azure virtual network.
<br>
<br>

![Image](https://docs.microsoft.com/en-us/azure/aks/media/use-kubenet/kubenet-overview.png)


<br>

With `kubenet`, only the nodes receive an IP address in the virtual network subnet. 
Pods across multiple nodes cannot communicate directly with each other. 
Instead, User Defined Routing (UDR) and IP forwarding can be used for connectivity between pods across nodes. 
Azure supports a maximum of 400 routes in a UDR, so it is not possible to have an AKS cluster larger than 400 nodes. 
The maximum number of pods per node that you can configure with `kubenet` in AKS is 110. 

<br>

Therefore, you should use `kubenet` if: 

* You have a limited IP address space. 

* Most of communications amon pods are within the cluster. 

* You do not need advanced AKS features such as `Virtual Nodes` or `Azure Network Policy`. 



## Set up an Azure Storage to store Terraform state

Terraform tracks state locally via the `terraform.tfstate` file. 
This approach is considered as a fine method if only one person works on the Terraform module. 
If multiple persons work together on the Terraform module, `Azure Storage` is used to track the Terraform state remotely. 
Therefore, we need to create a storage container into which the Terraform state file can be stored. 

<br>
In this regard, there are 4 steps to be done. The first 3 steps should be performed by running `backend.tf`. 

### Step 1: Azure Resource Group

We need to create an Azure Resource Group which includes the storage account in order to store the Terraform state. 
It would be more appropriate if we create an individual resource group different from the resource group in which all the required Azure resources exist. 

### Step 2: Azure Storage Account

The storage account provides a unique namespace for your Azure Storage data that is accessible from anywhere in the world over HTTP or HTTPS. 
Data in the Azure storage account is durable and highly available, secure, and massively scalable. 
Therefore, We create an Azure storage account which contains all of our Azure Storage data objects such as blobs to store the Terraform state. 

### Step 3: Azure Storage Container

We should create a blob container within the Azure storage account to store the Terraform state file. 
Blob storage container also provides the locking mechanism. It means that only one person can gain access to the state file and run `terraform plan` or `terraform apply` at the same time. 
This mechanism ensures the Terraform state file will not be corrupted due to mutual access. 

### Step 4: Configure the Terraform backend

When you run `backend.tf` and it has been successfully performed, you need to configure the Terraform backend. 
To this end, two parameters named `storage_account_name` and `storage_access_key` should be fetched firstly.


<br>
<br>

```
root@station1:~# terraform output storage_account_name
backend6e780a30fa87a67b
```

<br>
<br>

```
root@station1:~# terraform output storage_access_key
k7z89BHy9yQIEWxJU/tVrOamIe9fKwFQcZcG6d/o8hU2J9iaJcokTYd7fxVlRS7ITmGaAgx9Zub+8jdS0vNpCg==
```

<br>
These two values should be manually put in `init.tf`. This is because the Terraform backend defined in `init.tf` would not accept variables automatically.


## Results

We now list the cluster nodes' IP address.

<br>

```
root@station1:~# kubectl get nodes -o wide
NAME                              STATUS   ROLES   AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-default-25778934-vmss000000   Ready    agent   3m28s   v1.14.7   192.168.1.4   <none>        Ubuntu 16.04.6 LTS   4.15.0-1077-azure   docker://3.0.10+azure
```

<br>

The output shows that the IP address of the node is `192.168.1.4`. This is because we already provided an address prefix for the subnet in `variables.tf` as follows:

<br>
<br>

```
variable "address_prefix" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "192.168.1.0/24"
}
```

<br>

So far, neither `deployment` nor `pod` has been created.

<br>
<br>

```
root@station1:~# kubectl get deployments -o wide
No resources found in default namespace.

root@station1:~# kubectl get pods -o wide
No resources found in default namespace.
```

<br>

Now, we just deploy the `nginx` deployment.

<br>
<br>

```
root@station1:~# kubectl apply -f sample-deployment.yaml
deployment.apps/nginx-deployment created

root@station1:~# kubectl get deployments -o wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES         SELECTOR
nginx-deployment   1/1     1            1           3m18s   nginx        nginx:1.14.2   app=nginx
```

<br>
We list the pods' IP address.

<br>
<br>

```
root@station1:~# kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                              NOMINATED NODE   READINESS GATES
nginx-deployment-756d9fd5f9-vhhx8   1/1     Running   0          31s   10.244.0.11   aks-default-25778934-vmss000000   <none>           <none>
```

<br>

The output shows that the IP address of the pod is `10.244.0.11`. This is because we already provided the IP address range for pods in `variables.tf` as follows:

<br>
<br>

```
variable "pod_cidr" {
  description = "IP address range (in CIDR notation) used for pod IP addresses."
  type        = string
  default     = "10.244.0.0/16"
}
```

<br>
We would like to expose the service to clients outside the cluster. 
To this end, we create a Load Balancer-type service for nginx.

<br>
<br>

```
root@station1:~# kubectl expose deployment nginx-deployment --type=LoadBalancer --name nginx-http
service/nginx-http exposed
```

<br>
We list the services' IP address.

<br>
<br>

```
root@station1:~# kubectl get services -o wide
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)        AGE   SELECTOR
kubernetes   ClusterIP      10.0.0.1      <none>         443/TCP        23m   <none>
nginx-http   LoadBalancer   10.0.39.124   51.11.225.21   80:31040/TCP   55s   app=nginx
```

<br>

The output shows that the IP address of the service is `10.0.39.124`. This is because we already provided the IP address range for services in `variables.tf` as follows:

<br>
<br>

```
variable "service_cidr" {
  description = "It is the network range used by the Kubernetes services."
  type        = string
  default     = "10.0.0.0/16"
}
```

<br>

You can see that the web page is now accessible from anywhere in the world at: `http://51.11.225.21:80`

<br>
<br>

```
root@station1:~# curl 51.11.225.21:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

<br>
If you would like to get inside the nginx container in the pod, run the following command:

<br>
<br>

```
root@station1:~# kubectl exec -it nginx-deployment-756d9fd5f9-vhhx8 -c nginx -- bash
```


## SSH to the Azure cluster node

For the maintenance or troubleshooting, you can connect to the Azure AKS cluster node via SSH.
To this end, first of all, you need to create a `debian` container on the cluster as follows. This container is called `helper`.
After running the following command, you will get inside the container instance automatically.

<br>

```
root@station1:~# kubectl run --generator=run-pod/v1 -it --rm aks-ssh --image=debian

root@aks-ssh:/# 
```

<br>
Now, open a new terminal window and copy your private SSH key into the `helper` pod. This private key is used to create the SSH into the AKS node.

<br>
<br>

```
root@station1:~# kubectl cp ~/.ssh/id_rsa $(kubectl get pod -l run=aks-ssh -o jsonpath='{.items[0].metadata.name}'):/id_rsa
```

<br>
If required, change `~/.ssh/id_rsa` to location of your private SSH key. 
Now if you come back to previous terminal window where you are into the `helper` container, you can see the private key `id_rsa`.

<br>
<br>

```
root@aks-ssh:/# dir
bin  boot  dev  etc  home  id_rsa  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

<br>
In the `helper` container, you can connect to the cluster node and SSH to it. 
After running the following command, you will get inside the cluster node automatically.

<br>
<br>

```
root@aks-ssh:/# apt-get update && apt-get install openssh-client -y

root@aks-ssh:/# chmod 0600 id_rsa

root@aks-ssh:/# ssh -i id_rsa ubuntu@192.168.1.4

ubuntu@aks-default-25778934-vmss000000:~$
```

<br>

This username which is used to connect to the cluster node via SSH is `ubuntu` since the admin username for the Linux OS of the nodes in the cluster is already defined in `variables.tf` as follows:

<br>
<br>

```
variable "admin_username" {
  description = "The admin username for the Linux OS of the nodes in the cluster."
  type        = string
  default     = "ubuntu"
}
```

<br>

When you are in the cluster node machine, run `ip addr show docker0` command to check the bridge's IP address and netmask.

<br>
<br>

```
ubuntu@aks-default-25778934-vmss000000:~$ ip addr show docker0
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:2f:ba:83:d0 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
ubuntu@aks-default-25778934-vmss000000:~$
```

<br>

The output shows that `inet` is `172.17.0.1/16`. This is because we already provided the IP address range for the Docker bridge on nodes in `variables.tf` as follows:

<br>
<br>

```
variable "docker_bridge_cidr" {
  description = "IP address range (in CIDR notation) used as the Docker bridge IP address on nodes."
  type        = string
  default     = "172.17.0.1/16"
}
```


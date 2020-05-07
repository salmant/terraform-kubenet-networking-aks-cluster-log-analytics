
variable "project" {
  description = "The name of the project."
  type        = string
  default     = "DemoProject"
}

variable "department" {
  description = "The department who works on the project."
  type        = string
  default     = "Engineering"
}

variable "team" {
  description = "The team who works on the project."
  type        = string
  default     = "DevOps"
}

variable "stage" {
  description = "Development, Staging, Production, etc."
  type        = string
  default     = "Development"
}

# Changing this forces a new Resource Group to be created.
variable "resource_group_name" {
  description = "The name of the Resource Group in which all resources should exist."
  type        = string
  default     = "ResourceGroupDemo"
}

# Changing this forces a new Resource Group to be created.
variable "location" {
  description = "The Azure Region where the Resource Group should exist."
  type        = string
  default     = "France Central"
}

variable log_analytics_workspace_name {
  description = "It specifies the name of the Log Analytics Workspace."
  type        = string
  default     = "testLogAnalyticsWorkspaceName"
}

# Log Analytics available regions: https://azure.microsoft.com/global-infrastructure/services/?products=monitor
variable log_analytics_workspace_location {
  description = "It specifies the supported Azure location where the Log Analytics Workspace exists."
  type        = string
  default     = "eastus"
}

# Log Analytics pricing: https://azure.microsoft.com/pricing/details/monitor/
variable log_analytics_workspace_sku {
  description = "Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, and PerGB2018"
  type        = string
  default     = "Free"
}

# To protect the application and data from datacenter failures.
variable "availability_zones" {
  description = "A list of Availability Zones across which the Node Pool should be spread."
  type        = list(number)
  default     = [1, 2]
}

# It identifies the cluster which is created on the resource group.
variable "cluster_name" {
  description = "The name of the managed cluster."
  type        = string
  default     = "ManagedClusterDemo"
}

# Changing this forces a new resource to be created.
variable "dns_prefix" {
  description = "It can contain only letters, numbers, and hyphens."
  type        = string
  default     = "ManagedClusterDemo-dns"
}

# If not specified, the latest recommended version will be used at provisioning time (but will not auto-upgrade).
variable "kubernetes_version" {
  description = "Version of Kubernetes specified when creating the AKS managed cluster."
  type        = string
  default     = "1.14.7"
}

# This username is used to connect to the nodes in the AKS Cluster via SSH
variable "admin_username" {
  description = "The admin username for the Linux OS of the nodes in the cluster."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "The path to a pre-existing ssh public key to use."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# This must be between 1 and 100 and between 'min_count' and 'max_count'.
variable "node_count" {
  description = "The initial number of nodes which should exist in this Node Pool."
  type        = number
  default     = 1
}

# If required!
variable "enable_node_public_ip" {
  description = "If the Kubernetes Auto Scaler should be enabled for this Node Pool."
  type        = bool
  default     = false
}

# If it is set to false both 'min_count' and 'max_count' fields need to be set to null.
variable "enable_auto_scaling" {
  description = "If the Kubernetes Auto Scaler should be enabled for this Node Pool."
  type        = bool
  default     = true
}

# This must be between 1 and 100.
variable "max_count" {
  description = "The maximum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 4
}

# This must be between 1 and 100.
variable "min_count" {
  description = "The minimum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 1
}

# Changing this forces a new resource to be created.
variable "max_pods" {
  description = "The maximum number of pods that can run on each agent."
  type        = number
  default     = 30
}

# It should be carefully selected according to the use case.
variable "vm_size" {
  description = "The size of the Virtual Machine in this Node Pool."
  type        = string
  default     = "Standard_D2s_v3"
}

# Changing this forces a new resource to be created. It should be carefully selected according to the use case.
variable "os_disk_size_gb" {
  description = "The size of the OS Disk which should be used for each agent in the Node Pool."
  type        = number
  default     = 80
}


# Changing this forces a new resource to be created.
variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "192.168.0.0/16"
}

# To add the subnet to the virtual network, we need to provide an address prefix. The address prefix is again in CIDR format.
variable "address_prefix" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "192.168.1.0/24"
}

# When 'network_plugin' is set to 'kubenet' the 'network_policy' field can only be set to 'calico'.
variable "network_policy" {
  description = "The network plugin which is used by kubelet."
  type        = string
  default     = "calico"
}

# Changing this forces a new resource to be created.
variable "service_cidr" {
  description = "It is the network range used by the Kubernetes services."
  type        = string
  default     = "10.0.0.0/16"
}

# Changing this forces a new resource to be created.
variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)."
  type        = string
  default     = "10.0.0.10"
}

# Changing this forces a new resource to be created.
variable "docker_bridge_cidr" {
  description = "IP address range (in CIDR notation) used as the Docker bridge IP address on nodes."
  type        = string
  default     = "172.17.0.1/16"
}

# Changing this forces a new resource to be created.
variable "pod_cidr" {
  description = "IP address range (in CIDR notation) used for pod IP addresses."
  type        = string
  default     = "10.244.0.0/16"
}


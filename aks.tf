
/*
* Create an Azure Resource Group for the AKS Cluster
*/
resource "azurerm_resource_group" "standard_demo" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags = "${merge(
    local.common_tags,
    map(
      "CostAllocation", "300",
      "Reason", "test",
    )
  )}"

}

/*
* The Log Analytics Workspace name has to be unique across the whole of azure, not just the current subscription/tenant.
* So, we generate a random suffix for the Log Analytics Workspace name.
*/
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "test" {
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = "${var.log_analytics_workspace_location}"
  resource_group_name = azurerm_resource_group.standard_demo.name
  sku                 = "${var.log_analytics_workspace_sku}"
}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.test.location
  resource_group_name   = azurerm_resource_group.standard_demo.name
  workspace_resource_id = azurerm_log_analytics_workspace.test.id
  workspace_name        = azurerm_log_analytics_workspace.test.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

/*
* Create an application within Azure Active Directory (AD)
* You can think of this as an identity for the application which needs access to Azure resources.
*/
resource "azuread_application" "app_demo" {
  name  = "${var.project}-app_demo"
}

/*
* To allow an AKS cluster to interact with other Azure resources such as AKS subnet, a Service Principal should be created.
*/
resource "azuread_service_principal" "auth" {
  application_id = "${azuread_application.app_demo.application_id}"

  tags = [
    "${var.project}",
    "${var.stage}",
  ]

}

/*
* We need to supply a password for the application registration within Azure Active Directory.
*/
resource "random_string" "client_secret" {
  length           = 32
  special          = true
  override_special = "/@\" "
}

/*
* Duration for which the generated password is valid until is 8760h (1 year).
*/
resource "azuread_service_principal_password" "duration" {
  service_principal_id = "${azuread_service_principal.auth.id}"
  value                = "${random_string.client_secret.result}"
  end_date_relative    = "8760h" # 1 year
  # end_date           = "2021-05-01T01:02:03Z"
}

/*
* Manage a password associated with the application within Azure Active Directory.
*/
resource "azuread_application_password" "duration" {
  application_object_id = "${azuread_application.app_demo.id}"
  value                 = "${random_string.client_secret.result}"
  end_date_relative     = "8760h" # 1 year
  # end_date            = "2021-05-01T01:02:03Z"
}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

/*
* Create the Virtual Network (VNet)
*/
resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-aks-network"
  location            = azurerm_resource_group.standard_demo.location
  resource_group_name = azurerm_resource_group.standard_demo.name
  address_space       = ["${var.address_space}"]
  #dns_servers        = ["${var.dns_servers}"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "test",
      "Role", "test",
    )
  )}"

}

/*
* Create an AKS Subnet to be used by nodes.
*/
resource "azurerm_subnet" "node_subnet" {
  name                 = "node-subnet"
  resource_group_name  = azurerm_resource_group.standard_demo.name
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "${var.address_prefix}"
}

/*
* Grant AKS Cluster access to join the node-subnet
*/
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = "${azurerm_subnet.node_subnet.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.auth.object_id}"
}

/*
* Create an AKS kubernetes cluster
*/
resource "azurerm_kubernetes_cluster" "scalable_aks" {
  name                = "${var.cluster_name}"
  resource_group_name = azurerm_resource_group.standard_demo.name
  location            = azurerm_resource_group.standard_demo.location
  dns_prefix          = "${var.dns_prefix}"
  kubernetes_version  = "${var.kubernetes_version}"
  depends_on          = [azurerm_role_assignment.aks_subnet]

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  default_node_pool {
    name                    = "default"
    type                    = "VirtualMachineScaleSets"
    enable_auto_scaling     = "${var.enable_auto_scaling}"
    # enable_node_public_ip = "${var.enable_node_public_ip}"
    node_count              = "${var.node_count}"
    max_count               = "${var.max_count}"
    min_count               = "${var.min_count}"
    max_pods                = "${var.max_pods}"
    vm_size                 = "${var.vm_size}"
    os_disk_size_gb         = "${var.os_disk_size_gb}"
    availability_zones      = "${var.availability_zones}"
    vnet_subnet_id          = "${azurerm_subnet.node_subnet.id}"
  }

  service_principal {
    client_id     = "${azuread_service_principal.auth.application_id}"
    client_secret = "${random_string.client_secret.result}"
  }

  network_profile {
    network_plugin     = "kubenet"
    network_policy     = "${var.network_policy}"
    # 'docker_bridge_cidr', 'dns_service_ip' and 'service_cidr' should all be empty or all should be set
	service_cidr       = "${var.service_cidr}"
    dns_service_ip     = "${var.dns_service_ip}"
    docker_bridge_cidr = "${var.docker_bridge_cidr}"
    pod_cidr           = "${var.pod_cidr}"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
    }
  }

  tags = "${merge(
    local.common_tags,
    map(
      "NodePool", "Single",
      "Reason", "test",
    )
  )}"

  # To configure 'kubectl' in order to point 'kubeconfig' to the cluster.
  provisioner "local-exec" {
    command="az aks get-credentials -g ${azurerm_resource_group.standard_demo.name} -n ${azurerm_kubernetes_cluster.scalable_aks.name} --overwrite-existing"
  }

}


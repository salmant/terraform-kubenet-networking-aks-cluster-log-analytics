
terraform {
  required_version = ">= 0.12.24"
  # The terraform backend would not accept variables
  backend "azurerm" {
    # storage_account_name = <storage_account_name>
	storage_account_name   = "backend6e780a30fa87a67b"
    container_name         = "backend-sc"
    key                    = "terraform.tfstate"
	# access_key           = <storage_access_key>
	access_key             = "k7z89BHy9yQIEWxJU/tVrOamIe9fKwFQcZcG6d/o8hU2J9iaJcokTYd7fxVlRS7ITmGaAgx9Zub+8jdS0vNpCg=="
  }
}

provider "azurerm" {
  version = "~>2.7.0"
  features {}
}

provider "azuread" {
  version = "~>0.8.0"
}

provider "random" {
  version = "~>2.2.0"
}

provider "kubernetes" {
  version                = "~> 1.11.1"
  host                   = azurerm_kubernetes_cluster.scalable_aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}


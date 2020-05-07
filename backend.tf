
/*
* It specifies the supported Azure location where the resource group which includes the storage account exists.
*/
variable "backend_resource_group_location" {
  description = "The Azure Region where the Resource Group which includes the storage account should exist."
  type        = string
  default     = "France Central"
}

/*
* It defines the tier to use for the storage account.
*/
variable "storage_account_tier" {
  description = "Valid options are Standard and Premium."
  type        = string
  default     = "Standard"
}

/*
* It defines the type of replication to use for this storage account.
*/
variable "storage_account_replication_type" {
  description = "Valid options are LRS, GRS, RAGRS and ZRS."
  type        = string
  default     = "LRS"
}

/*
* Create an Azure Resource Group which includes the storage account to store the Terraform state.
*/
resource "azurerm_resource_group" "backend_rg" {
  name     = "backend-rg"
  location = "${var.backend_resource_group_location}"
}

# For storage accounts, we must provide a name for the resource that is unique across Azure. 
# Generate a suffix for the storage account name
resource "random_id" "storage_account_name_suffix" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
	resource_group = "azurerm_resource_group.backend_rg.name"
  }

  byte_length = 8
}

/*
* Create an Azure storage account which contains all of our Azure Storage data objects such as blobs to store the Terraform state.
*/
resource "azurerm_storage_account" "backend_sa" {
  # 'name' can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long.
  name                     = "backend${random_id.storage_account_name_suffix.hex}"
  resource_group_name      = azurerm_resource_group.backend_rg.name
  location                 = azurerm_resource_group.backend_rg.location
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"

  lifecycle {
    prevent_destroy = true
  }

}

/*
* Create a blob container within the Azure storage account.
*/
resource "azurerm_storage_container" "backend_sc" {
  name                  = "backend-sc"
  storage_account_name  = azurerm_storage_account.backend_sa.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }

}

output "storage_account_name" {
  description = "It specifies the name of the storage account."
  value = "${azurerm_storage_account.backend_sa.name}"
}

output "storage_access_key" {
  description = "The primary access key for the storage account."
  value = "${azurerm_storage_account.backend_sa.primary_access_key}"
}


output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_token" {
  description = "The authentication token for the cluster"
  value       = module.eks.cluster_token
  sensitive   = true
}

output "node_groups" {
  description = "EKS node groups"
  value       = module.eks.eks_managed_node_groups
}

output "key_pair_name" {
  description = "The key pair name"
  value       = module.key_pair.key_pair_name
}

output "key_pair_private_key_pem" {
  description = "Private key data in PEM format"
  value       = module.key_pair.private_key_pem
  sensitive   = true
}

output "remote_access_security_group_id" {
  description = "ID of the security group for remote access"
  value       = aws_security_group.remote_access.id
}
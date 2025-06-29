output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_cluster.cluster_certificate_authority_data
}

output "cluster_token" {
  description = "The authentication token for the cluster"
  value       = module.eks_cluster.cluster_token
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ap-northeast-1 --name ${module.eks_cluster.cluster_name}"
}

output "kustomize_apply_commands" {
  description = "Commands to apply kustomize configurations"
  value = {
    dev     = "kubectl apply -k k8s/overlays/dev"
    staging = "kubectl apply -k k8s/overlays/staging"
    prod    = "kubectl apply -k k8s/overlays/prod"
  }
}
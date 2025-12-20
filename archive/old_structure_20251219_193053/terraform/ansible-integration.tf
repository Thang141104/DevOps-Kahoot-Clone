# Generate Ansible inventory from Terraform outputs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible-inventory.tpl", {
    jenkins_ip = aws_instance.jenkins_server.public_ip
    k8s_master_ip = aws_instance.k8s_master.public_ip
    k8s_worker_ips = aws_instance.k8s_workers[*].public_ip
  })
  filename = "${path.module}/../ansible/inventory/hosts"
  
  depends_on = [
    aws_instance.jenkins_server,
    aws_instance.k8s_master,
    aws_instance.k8s_workers
  ]
}

# Run Ansible playbooks after infrastructure is ready
resource "null_resource" "run_ansible_jenkins" {
  depends_on = [
    local_file.ansible_inventory,
    aws_instance.jenkins_server
  ]
  
  triggers = {
    instance_id = aws_instance.jenkins_server.id
  }
  
  provisioner "local-exec" {
    command = "sleep 60 && cd ${path.module}/../ansible && ansible-playbook -i inventory/hosts playbooks/jenkins-setup.yml"
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "run_ansible_k8s" {
  depends_on = [
    local_file.ansible_inventory,
    aws_instance.k8s_master,
    aws_instance.k8s_workers
  ]
  
  triggers = {
    master_id = aws_instance.k8s_master.id
    worker_ids = join(",", aws_instance.k8s_workers[*].id)
  }
  
  provisioner "local-exec" {
    command = "sleep 60 && cd ${path.module}/../ansible && ansible-playbook -i inventory/hosts playbooks/k8s-setup.yml"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Copy kubeconfig from K8s master to Jenkins
resource "null_resource" "copy_kubeconfig_to_jenkins" {
  depends_on = [
    null_resource.run_ansible_k8s,
    null_resource.run_ansible_jenkins
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      scp -i jenkins-key.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.k8s_master.public_ip}:/home/ubuntu/.kube/config ./kubeconfig
      scp -i jenkins-key.pem -o StrictHostKeyChecking=no ./kubeconfig ubuntu@${aws_instance.jenkins_server.public_ip}:/home/ubuntu/.kube/config
      ssh -i jenkins-key.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.jenkins_server.public_ip} "sudo cp /home/ubuntu/.kube/config /var/lib/jenkins/.kube/config && sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config"
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

data "template_file" "ingress" {
  template             = "${file(var.ingress_controller_file)}"

  vars = {
    cluster_name       = var.cluster_name
    vpc_id             = var.vpc_id
    region             = var.region

  } 
}

data "template_file" "rbac" {
  template             = "${file(var.rbac_file)}"
}

resource "null_resource" "apply" {
  triggers = {
    ingress_controller_file = md5(data.template_file.ingress.rendered)
  }

  depends_on = [

  ]

  provisioner "local-exec" {
    command  = <<EOF
aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}
echo '${data.template_file.rbac.rendered}' | kubectl apply -f -
echo '${data.template_file.ingress.rendered}' | kubectl apply -f -
EOF
  }
}
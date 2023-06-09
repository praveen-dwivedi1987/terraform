#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get Linux AMI ID using SSM Parameter endpoint in us-west-2
data "aws_ssm_parameter" "linuxAmiOregon" {
  provider = aws.region-worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "jenkins-master"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create key-pair for logging into EC2 in us-west-2
resource "aws_key_pair" "worker-key" {
  provider   = aws.region-worker
  key_name   = "jenkins-worker"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.subnet_1.id

  tags = {
    Name = "jenkins_master_tf"
    Role = "jenkins_master"
  }
  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]

  provisioner "local-exec" {
        working_dir = var.ansible_dir
        command = "sleep 120; ansible-playbook -i jenkins_master_aws_ec2.yml install_jenkins_master.yaml --private-key=~/.ssh/id_rsa"
  }
}

#Create EC2 in us-west-2
resource "aws_instance" "jenkins-worker-oregon" {
  provider                    = aws.region-worker
  count                       = var.workers-count
  ami                         = data.aws_ssm_parameter.linuxAmiOregon.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg-oregon.id]
  subnet_id                   = aws_subnet.subnet_1_oregon.id
  private_ip                  = var.worker-private-ip[count.index]
  tags = {
    Name              = join("_", ["jenkins_worker_tf", count.index + 1])
    Master_Private_IP = aws_instance.jenkins-master.private_ip
    Role              = "jenkins_worker"
  }
  depends_on = [aws_main_route_table_association.set-worker-default-rt-assoc]
    provisioner "local-exec" {
        working_dir = var.ansible_dir
        command = "sleep 120; ansible-playbook -i jenkins_worker_aws_ec2.yml setup_jenkins_worker.yaml --private-key=~/.ssh/id_rsa"
  }
}

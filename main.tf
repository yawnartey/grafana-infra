#create keypair
resource "aws_key_pair" "grafana-keypair" {
  key_name   = "grafana-keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

#create vpc
resource "aws_vpc" "grafana-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "grafana-vpc"
  }
}

#creating internet gateway for the vpc
resource "aws_internet_gateway" "grafana-igw" {
  vpc_id = aws_vpc.grafana-vpc.id
  tags = {
    Name = "grafana-igw"
  }
}

#create subnet 
resource "aws_subnet" "grafana-subnet" {
  vpc_id            = aws_vpc.grafana-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "grafana-subnet"
  }
}

#creating the route table
resource "aws_route_table" "grafana-route-table" {
  vpc_id = aws_vpc.grafana-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grafana-igw.id
  }
  tags = {
    Name = "grafana-route-table"
  }
}

#associate subnet to route table
resource "aws_route_table_association" "grafana-route-table-association" {
  subnet_id      = aws_subnet.grafana-subnet.id
  route_table_id = aws_route_table.grafana-route-table.id
}

#create grafana node
resource "aws_instance" "grafana-node" {
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.grafana-subnet.id
  vpc_security_group_ids = [aws_security_group.grafana-sg.id]
  key_name = "grafana-keypair"
  tags = {
    Name = "Grafana"
  }
}

#security group
resource "aws_security_group" "grafana-sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.grafana-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "Allow etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kubelet, Kube-scheduler and Kube-controller-manager"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Allow NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "Allow Port 3000 for Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana-sg"
  }
}
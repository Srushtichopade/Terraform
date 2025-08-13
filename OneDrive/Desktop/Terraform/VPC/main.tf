provider "aws" {
  region     = "ap-south-1"
}


resource "tls_private_key" "srushtikeypairkey" {
 algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
 key_name = "srushtikeypair"
 public_key = "${tls_private_key.srushtikeypairkey.public_key_openssh}"
 depends_on = [
  tls_private_key.srushtikeypairkey
 ]
}

resource "local_file" "key" {
 content = "${tls_private_key.srushtikeypairkey.private_key_pem}"
 filename = "srushtikeypair.pem"
 file_permission ="0400"
 depends_on = [
  tls_private_key.srushtikeypairkey
 ]
}

resource "aws_vpc" "srushtivpc" {
 cidr_block = "10.0.0.0/16"
 instance_tenancy = "default"
 enable_dns_hostnames = "true" 
 tags = {
  Name = "srushtivpc"
 }
}

resource "aws_security_group" "srushtisg" {
 name = "srushtisg"
 description = "This firewall allows SSH, HTTP and MYSQL"
 vpc_id = "${aws_vpc.srushtivpc.id}"
 
 ingress {
  description = "SSH"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 ingress { 
  description = "HTTP"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 ingress {
  description = "TCP"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 tags = {
  Name = "srushtisg"
 }
}

resource "aws_subnet" "public" {
 vpc_id = "${aws_vpc.srushtivpc.id}"
 cidr_block = "10.0.0.0/24"
 availability_zone = "ap-south-1a"
 map_public_ip_on_launch = "true"
 
 tags = {
  Name = "my_public_subnet"
 } 
}
resource "aws_subnet" "private" {
 vpc_id = "${aws_vpc.srushtivpc.id}"
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-south-1b"
 
 tags = {
  Name = "my_private_subnet"
 }
}

resource "aws_internet_gateway" "srushtigw" {
 vpc_id = "${aws_vpc.srushtivpc.id}"

 tags = {
  Name = "srushtigw"
 }
}

resource "aws_route_table" "srushtirt" {
 vpc_id = "${aws_vpc.srushtivpc.id}"
 
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.srushtigw.id}"
 }
 
 tags = {
  Name = "srushtirt"
 }
}

resource "aws_route_table_association" "a" {
 subnet_id = "${aws_subnet.public.id}"
 route_table_id = "${aws_route_table.srushtirt.id}"
}

resource "aws_route_table_association" "b" {
 subnet_id = "${aws_subnet.private.id}"
 route_table_id = "${aws_route_table.srushtirt.id}"
}

resource "aws_instance" "myserver" {
 ami = "ami-02a2af70a66af6dfb"
 instance_type = "t2.micro"
 key_name = "${aws_key_pair.generated_key.key_name}"
 vpc_security_group_ids = [ "${aws_security_group.srushtisg.id}" ]
 subnet_id = "${aws_subnet.public.id}"
 
 tags = {
  Name = "myserver"
 }
}
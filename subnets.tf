data "aws_availability_zones" "available" {}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.public_cidrs[count.index]            
  availability_zone       = random_shuffle.az_list.result[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}_public_${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.private_cidrs[count.index]          
  availability_zone       = random_shuffle.az_list.result[count.index] 
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}_private_${count.index + 1}"
  }
}

# output "number_of_az" {
#   value = length(data.aws_availability_zones.available.names)
# }

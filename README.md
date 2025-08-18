<h1>Build a VPC network from scratch in Terraform.</h1>
<h2>Lab Overview</h2>
Amazon Virtual Private Cloud (Amazon VPC) gives you the ability to provision a logically isolated section of the Amazon Web Services (AWS) Cloud where you can launch AWS resources in a virtual network that you define. You have complete control over your virtual networking environment, including selecting your IP address ranges, creating subnets, and configuring route tables and network gateways.
In this lab, you Terraform to build a virtual private cloud (VPC) and other network components required to deploy resources, such as an Amazon Elastic Compute Cloud (Amazon EC2) instance.

<h2>Objectives</h2>
By the end of this lab, you should be able to do the following:
• Create a VPC with a private and public subnet, an internet gateway, and a NAT gateway.

• Configure route tables associated with subnets to local and internet-bound traffic by using an internet gateway and a NAT gateway.

Building VPC allow us to define the CIDR block and Availability Zones and automatically create the necessary subnets, route tables, NAT Gateway, and Internet Gateway in order to make this a fully functional VPC in which we can deploy resources.

<h1>Architecture</h1>

<img width="683" height="357" alt="image" src="https://github.com/user-attachments/assets/0d958188-ecf5-4143-bb0c-e0b8a6db92ca" />


<h1>Building the Virtual Private Cloud module</h1>
It’s time to get started! Go ahead and create a brand new directory (I’ll name mine Networking), and within that directory, create the necessary files and directories for this project as outlined below. We’ll fill them in as we go along. 

<h1>Task 1: VPC Module</h1>

I will first define the module in our root main.tf (not the one within the modules directory) file. /main.tf

<img width="572" height="365" alt="image" src="https://github.com/user-attachments/assets/15a378d2-8adb-4dec-be94-2b8e86e13250" />


Lab_VPC is a variable defined in the vpc module that we’ll plan to build. For now you’ll want to understand that we’re defining the VPC’s CIDR block, enabling DNS support, specifying the availability zones, and adding tags to the VPC. These values allow us to customize our network and will be passed to the vpc module.

Setting cidr_block to 10.0.0.0/16 will create a VPC with that network.
Enabling dns_hostnames and dns_support will allow our instances to resolve DNS names and have DNS resolution.
Setting availability_zones to ["us-east-1a", "us-east-1b"] will create the VPC’s subnets in us-east-1a and us-east-1b respectively. The module is capable of scaling subnets and associated network components into multiple availability zones if desired.
Finally we are setting tags

<h2>Task 1.1: VPC Module Variables File</h2>h2>
Next, let’s define the variables for the VPC module in the variables.tf file in the vpc module directory.

Modules/vpc/variables.tf

This file defines the vpc_config variable that gets passed to the VPC module. It’s an object type that contains the VPC’s CIDR block, DNS settings, availability zones, and tags. We covered the variables and their values already but here we can see the type of value expected for each. Let’s take a look,

cidr_block is a string so the expected value should be in quotes e.g., "10.0.0.0/16"
enable_dns_hostnames and enable_dns_support are optional boolean values that default to true if not provided
availability_zones is a list of strings that should be in square brackets e.g., ["us-east-1a", "us-east-1b"]
tags is a map of strings that should be in curly brackets
Within the description, we’ve got an <<EOT followed by a description and ending with EOT. EOT, if you’re not familiar, is used for multi-line strings where we start with << and then a delimiter, in this case EOT to indicate where it starts and where it ends. So it’s not providing functionality, it’s just helping us write a larger description

<img width="591" height="378" alt="image" src="https://github.com/user-attachments/assets/25b2831a-096c-48f6-93b3-81cc95e61b2c" />

Now, let’s begin creating the VPC module’s main.tf file.

In this file, we’re creating local variables to store the number of public and private subnets we’ll create. We’re setting the number of subnets to the length of the availability zones provided in the vpc_config variable. This allows us to scale the number of subnets based on the number of availability zones provided. So, if we provide two availability zones e.g., ["us-east-1a", "us-east-1b"], we’ll create two public and two private subnets in each zone.

We’re also using a data source to get the current region. This will allow us to reference the region in our resources without hardcoding it.

Modules/vpc/main.tf

Next, let’s create the VPC and Internet Gateway resources. The VPC resource is created with the CIDR block, DNS settings, and tags provided in the vpc_config variable. The Internet Gateway is attached to the VPC and tagged with a name.

Mdules/vpc/main.tf

<img width="517" height="119" alt="image" src="https://github.com/user-attachments/assets/e7b1c7b7-1671-4984-942c-983fe992de8c" />

Now that we have a VPC, we need to create resources within it.
    
<h2>Public Subnets</h2>

Let’s start by creating public subnets.
    
 Modules/vpc/main.tf
  
   <img width="587" height="170" alt="image" src="https://github.com/user-attachments/assets/d9b0258f-049e-452e-b926-4d3212cb7ddb" />


In this section, we’re creating subnets based on the number of availability zones provided in the vpc_config variable. If we provide two availability zones, then a subnet will be created and associated with each zone. The CIDR block for each subnet is automatically generated based on the VPC CIDR block by using the terraform cidrsubnet function. The subnets are tagged with a name e.g., tf_public_subnet_1 and tf_public_subnet_2 if we have two availability zones.

It’s important to note that subnets are all private by default until we associate them with a route table that has a route to the Internet Gateway. However, by naming our terraform resource block public, it’ll make it easier to distinguish and reference these resources later on.

<h2>Route table for the public subnets</h2>
Now let’s create a route table for the public subnets. We’re associating the route table with the public subnets and creating a route to the VPC’s Internet Gateway, which will make them public. This route will allow non-local traffic to be sent to the Internet Gateway.

Modules/vpc/main.tf

     # create a route table for the public subnets
     resource "aws_route_table" "public" {
       vpc_id = aws_vpc.vpc.id
       route {
         cidr_block = "0.0.0.0/0"
         gateway_id = aws_internet_gateway.igw.id
       }
     }
     
     # Associate the route table with the public subnets
     resource "aws_route_table_association" "public" {
       count          = local.num_of_public_subnets       # creates an association for each public subnet
       subnet_id      = aws_subnet.public[count.index].id # gets each public subnet id
       route_table_id = aws_route_table.public.id         # adds the associations to the route table
     }
<h2>Create Private Subnets</h2>

Modules/vpc/main.tf

##### Private Subnets and Associated Route Tables #####
     
     # create private subnets
     resource "aws_subnet" "private" {
       count             = local.num_of_private_subnets                           # creates a subnet for each availability zone
       vpc_id            = aws_vpc.vpc.id                                         # assigns the subnet to the VPC
       availability_zone = var.lab_vpc.availability_zones[count.index]         # assigns each subnet to an availability zone
       cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index + 1) # function that automatically creates subnet CIDR blocks based on the VPC CIDR block
       tags = {
         "Name" = "tf_private_subnet_${count.index + 1}"
       }
     }

In this section, we’re creating private subnets. The process is similar to creating public subnets but our CIDR block is generated slightly differently so the subnets don’t overlap with the public subnets. Subnetting can get a little bit tricky, so if you’re not already familiar with it, I would highly recommend checking out the documentation for the cidrsubnet() function

<h2>Route table associations for private subnet</h2>
Modules/vpc/main.tf

     # create route tables for each private
     resource "aws_route_table" "private" {
       count  = local.num_of_private_subnets
       vpc_id = aws_vpc.vpc.id
     
       route {
         cidr_block     = "0.0.0.0/0"
         nat_gateway_id = aws_nat_gateway.ngw[count.index].id
       }
     }
     
     # Associate the route tables with the private subnets
     resource "aws_route_table_association" "private" {
       count          = local.num_of_private_subnets                        # creates an association for each private subnet
       subnet_id      = aws_subnet.private[count.index].id                  # gets each private subnet id
       route_table_id = element(aws_route_table.private[*].id, count.index) # associates the private subnets with each private route tables
     }

In this section, we’re creating and associating the route table with the private subnets and creating a route to the NAT Gateway. This route will allow non-local traffic to be sent to the NAT Gateway and out to the internet.

<h2>Create Elastic IP and NAT Gateway</h2>
Finally, let’s create the Elastic IP and NAT Gateway resources. The NAT Gateway gets deployed in each public subnet and is associated with an Elastic IP.

Modules/vpc/main.tf

     # Create an Elastic IP for each NAT Gateway
     resource "aws_eip" "ngw" {
       count = local.num_of_public_subnets # Number of NAT Gateways
     
       tags = {
         "Name" = "tf_nat_gateway_${count.index + 1}"
       }
     }
     
     # Create a NAT Gateway for each public subnet
     resource "aws_nat_gateway" "ngw" {
       count         = local.num_of_public_subnets                   # creates a NAT Gateway for each public subnet
       allocation_id = element(aws_eip.ngw[*].id, count.index)       # assigns an Elastic IP to each NAT Gateway
       subnet_id     = element(aws_subnet.public[*].id, count.index) # assigns each NAT Gateway to a public subnet
       depends_on    = [aws_internet_gateway.igw]                    # NAT Gateway depends on the Internet Gateway
     
       tags = {
         "Name" = "tf_nat_gateway_${count.index + 1}"
       }
     }

<h2>Task 1.3: VPC Module Outputs File</h2>

Before we wrap up with our VPC, let’s go ahead and output values. We’ll want the outputs to include the VPC ID, public subnet IDs, private subnet IDs, Internet Gateway ID, and NAT Gateway IDs. This allows us to easily reference and use those resources elsewhere if needed.

Modules/vpc/outputs.tf

     # output map of vpc related resources
     output "vpc_resources" {
       value = {
         vpc_id              = aws_vpc.vpc.id
         public_subnet_ids   = aws_subnet.public[*].id
         private_subnet_ids  = aws_subnet.private[*].id
         internet_gateway_id = aws_internet_gateway.igw.id
         nat_gateway_ids     = aws_nat_gateway.ngw[*].id
       }
     }

That’s it for the VPC module! We’ve created a network with subnets, route tables, NAT Gateway, and Internet Gateway. We’ve also tagged our resources for easy identification. Let’s move on to deployment to test this out and make sure it works!








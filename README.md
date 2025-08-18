<h1>Build a VPC network from scratch using Terraform.</h1>
<h2>Lab Overview</h2>
Create a fully functional VPC with public and private subnets, route tables, NAT Gateways, and an Internet Gateway. All using Terraform.
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

<img width="563" height="343" alt="image" src="https://github.com/user-attachments/assets/ea44a5c0-1af6-408e-8d2d-9aa8610bcc0f" />

<img width="496" height="106" alt="image" src="https://github.com/user-attachments/assets/9a5009aa-820b-45f7-8b4f-f5c58801c36e" />


<h2>Create Private Subnets</h2>

Modules/vpc/main.tf

##### Private Subnets and Associated Route Tables #####
     
<img width="670" height="415" alt="image" src="https://github.com/user-attachments/assets/b2b823d0-849e-465e-8b63-966425a7c135" />

In this section, we’re creating private subnets. The process is similar to creating public subnets but our CIDR block is generated slightly differently so the subnets don’t overlap with the public subnets. Subnetting can get a little bit tricky, so if you’re not already familiar with it, I would highly recommend checking out the documentation for the cidrsubnet() function

<h2>Route table associations for private subnet</h2>
Modules/vpc/main.tf

   <img width="514" height="300" alt="image" src="https://github.com/user-attachments/assets/1ab3649c-d11c-4ee1-82b4-012d25260d1d" />


In this section, we’re creating and associating the route table with the private subnets and creating a route to the NAT Gateway. This route will allow non-local traffic to be sent to the NAT Gateway and out to the internet.

<h2>Create Elastic IP and NAT Gateway</h2>
Finally, let’s create the Elastic IP and NAT Gateway resources. The NAT Gateway gets deployed in each public subnet and is associated with an Elastic IP.

Modules/vpc/main.tf

  <img width="410" height="304" alt="image" src="https://github.com/user-attachments/assets/b5d3bf50-5483-404a-aec9-7045928f7dba" />

<h2>Task 1.3: VPC Module Outputs File</h2>

Before we wrap up with our VPC, let’s go ahead and output values. We’ll want the outputs to include the VPC ID, public subnet IDs, private subnet IDs, Internet Gateway ID, and NAT Gateway IDs. This allows us to easily reference and use those resources elsewhere if needed.

Modules/vpc/outputs.tf

<img width="555" height="232" alt="image" src="https://github.com/user-attachments/assets/88ebf95a-1111-426c-943c-08b6b134277e" />



That’s it for the VPC module! We’ve created a network with subnets, route tables, NAT Gateway, and Internet Gateway. We’ve also tagged our resources for easy identification. Let’s move on to deployment to test this out and make sure it works!

<h1>Testing deployment of our VPC</h1>

From the root directory, we should have the following files defined:

main.tf

<img width="409" height="313" alt="image" src="https://github.com/user-attachments/assets/16e49bf2-d526-42a8-93a1-6a411b0aa36e" />

provider.tf
<img width="312" height="107" alt="image" src="https://github.com/user-attachments/assets/21aaa715-b693-44df-884c-eb878f1e75dc" />


Configure your AWS CLI

<img width="548" height="140" alt="image" src="https://github.com/user-attachments/assets/a6a1946e-d065-4feb-af5e-13826a4729bd" />

After configuring the ClI, we need to initialize the terraform configuration.

<img width="703" height="275" alt="image" src="https://github.com/user-attachments/assets/121fbdce-ceee-4741-80b5-01ad7ef0c050" />

Validate and format the code: 

    terraform validate

<img width="533" height="193" alt="image" src="https://github.com/user-attachments/assets/d34e0b33-e4cd-40f6-906e-50a875ec6720" />

Next, run a plan. The full output won’t be shown here but you should see a plan to create 17 resources from the VPC module.

    terraform plan

<img width="926" height="400" alt="image" src="https://github.com/user-attachments/assets/359322fa-23b2-4755-b571-5b1235096020" />

Finally, apply the changes to build the module.

    terraform apply

<img width="795" height="72" alt="image" src="https://github.com/user-attachments/assets/c04dc7ab-c8ad-4571-9b50-b6f67c66c923" />

 
Once the resources get created, we can navigate to the AWS Management Console using the lab’s provided credentials to view the VPC network we’ve built. Search for VPC and click on “Your VPCs” in the menu, and then select the VPC created and click the ‘Resource map’ tab to see the network flow.

<img width="958" height="134" alt="image" src="https://github.com/user-attachments/assets/5ada9d1b-bdae-4d59-959c-d25754965754" />

If you highlight on vpc_igw as seen in the image below, you’ll see how only the public subnets are associated with the Internet Gateway.

<img width="797" height="198" alt="image" src="https://github.com/user-attachments/assets/4a54d45c-bae4-4496-9f5d-dfeb5b046668" />

The private subnets are each associated with a NAT Gateway in their respective availability zones.

<img width="760" height="188" alt="image" src="https://github.com/user-attachments/assets/743a73e5-7454-4708-99a8-7fe2137eb47a" />

<h1>Conclusion & Terraform Destroy</h1>
    • Created a VPC with a private and public subnet, an internet gateway, and a NAT gateway
    • Configured route tables associated with subnets to local and internet-bound traffic by using an internet gateway and a NAT gateway


















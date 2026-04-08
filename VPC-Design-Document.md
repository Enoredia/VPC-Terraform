### VPC Design Document

#### •	Region & Availability Zones
Region: eu-west-2 (London)

I selected the region closest to West Africa and cost effective, which is eu-west-1 , to ensure affordability for ShopNaija and to ensure high availability.  eu-west-1 is a mainstream AWS region with broad service availability and multiple AZs, which is helpful for building the full architecture. 
Two availability zones to ensure enough resilience for AZ failure, while keeping cost lower than a 3-AZ design.


#### •	VPC CIDR Block
VPC CIDR: 10.10.0.0/16

I chose a /16 CIDR block to ensure sufficient IP address space for the required subnets across two availability zones while allowing for future scalability. The architecture requires at least six subnets for public, application, and database layers, each typically sized at /24. A /16 provides enough flexibility to accommodate growth, additional services, and future environments without requiring reconfiguration of the VPC.


#### •	Subnet Design

|Subnet Name	  |  CIDR Block	    |      AZ	  |   Type	   |     Purpose                    |
|-----------------|-----------------|-------------|------------|--------------------------------|
| public-subnet-a | 10.10.1.0/24 | eu-west-1a  |  Public	   | Load balancer, Bastion Host, NAT gateway    |
| public-subnet-b | 10.10.2.0/24	| eu-west-1b  |  Public	   | Load balancer (backup)         |  
| app-tier-a    | 10.10.11.0/24	| eu-west-1a  |  Private   | Backend/API servers                |
| app-tier-b    | 10.10.12.0/24	| eu-west-1b  |  Private   | Backend/API servers (backup)       |
| db-tier-a     | 10.10.21.0/24	| eu-west-1a  |  Private   | RDS database                   |
| db-tier-b     | 10.10.22.0/24	| eu-west-1b  |  Private   | RDS database (backup)          |


#### •	Component Decisions

**Internet Gateway — 1**
One Internet Gateway is enough for the entire VPC. It serves as the single entry and exit point between the VPC and the public internet.

**NAT Gateway — 1**
I would use one NAT Gateway initially for cost optimization, with a design that allows scaling to 1 per Availability Zone for high availability. 

**Route Tables — 3**
I would use three route tables: one for public subnets, one for private application subnets, and one for private database subnets. The public route table routes internet traffic through the Internet Gateway, the private application route table routes outbound traffic through a NAT Gateway, and the database route table has only local routes to ensure full isolation. This design ensures proper traffic flow, security, and simplicity while supporting scalability. 


**Bastion Host** — I would include a bastion host in a public subnet with a public IP, restrict inbound SSH (port 22) access to only trusted IP addresses, allow outbound access to private instances, and configure private instances to accept SSH connections only from the bastion host’s security group.



#### •	Traffic Flow

**Scenario 1: Customer in Lagos visits the ShopNaija website**
When a customer in Lagos visits the ShopNaija website, the request leaves their browser and travels over the internet to the AWS environment, where it enters the VPC through the Internet Gateway. It is then received by the Application Load Balancer in the public subnet, which forwards the request to a app server in the private subnet. The app server processes the request and sends the response back through the load balancer, out via the Internet Gateway, and back across the internet to the user’s browser.


`Customer browser => Internet => AWS => Internet Gateway => Load Balancer (public subnet) => App Server (private subnet) => Load balancer => Internet Gateway => Internet => Customer browser  ` 
 
 
**Scenario 2: DevOps engineer SSHes into a backend app server**
The DevOps engineer first SSHs into the bastion host in the public subnet using its public IP, and then from the bastion host, SSHs into the backend application server in the private subnet using its private IP, since the app server is not directly accessible from the internet.


`Engineer terminal(SSH) => Bastion Host (public-subnet-a) => App Server (app-tier-a/ app-tier-b)`


**Scenario 3: App server calls the Paystack API to process a payment**
The backend app server sends the request to its route table, which routes outbound traffic to the NAT Gateway in the public subnet; the NAT Gateway then forwards the request through the Internet Gateway to the Paystack API on the internet, and the response returns through the same path back to the app server.

`App Server (private subnet) => Route table => NAT Gateway (public-subnet-a) => Internet Gateway => Internet => Paystack API => same path back`

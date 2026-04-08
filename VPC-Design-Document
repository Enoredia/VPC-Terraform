### VPC Design Document

#### •	Region & Availability Zones
Region: eu-west-2 (London)

I selected London because it offers the lowest latency to West Africa compared to other regions. My users in Nigeria will experience significantly better response times routing through. This directly improves user experience and perceived performance.
Availability Zones: eu-west-2a and eu-west-2b

Two AZs provide high availability — if one data centre experiences an outage, the other continues serving traffic.

#### •	VPC CIDR Block
VPC CIDR: 10.10.0.0/16

The 10.0.0.0/16 prefix was chosen because it provides 65,536 available addresses across the 10.10.x.x range, giving ample room for multiple subnets across tiers and AZs. 10.10.0.0 was selected over the common 10.0.0.0 to avoid overlap in cases where VPC peering with other environments (staging, dev) might be needed in future.

#### •	Subnet Design

|Subnet Name	  |  CIDR Block	    |      AZ	  |   Type	   |     Purpose                    |
|-----------------|-----------------|-------------|------------|--------------------------------|
| public-subnet-a | 10.10.1.0/24    | eu-west-2a  |  Public	   | Load balancer, Bastion Host    |
| public-subnet-b | 10.10.2.0/24	| eu-west-2b  |  Public	   | Load balancer (backup)         |  
| app-subnet-a    | 10.10.3.0/24	| eu-west-2a  |  Private   | App/API servers                |
| app-subnet-b    | 10.10.4.0/24	| eu-west-2b  |  Private   | App/API servers (backup)       |
| db-subnet-a     | 10.10.5.0/24	| eu-west-2a  |  Private   | RDS database                   |
| db-subnet-b     | 10.10.6.0/24	| eu-west-2b  |  Private   | RDS database (backup)          |

Each subnet uses a /24 prefix, this gives me 251 usable addresses per subnet (256 minus the 5 AWS reserves). The third octet increases sequentially (1 through 6), making the addressing easy to read and audit. There are no subnets overlap since each occupies a unique range within 10.10.0.0/16.

#### •	Component Decisions

**Internet Gateway — 1**
One Internet Gateway is enough for the entire VPC. It serves as the single entry and exit point between the VPC and the public internet, for both inbound customer traffic and outbound traffic from the NAT Gateway. They are highly available by default and do not require redundancy.

**NAT Gateway — 1**
One NAT Gateway placed in public-subnet-a enables private instances (app servers, database) to make outbound requests to the internet (e.g. calling the Paystack API, running system updates) without being reached from outside. The trade-off here is if eu-west-2a goes down, private instances temporarily lose outbound internet access. Setting up in 2 AZs would doubles cost. For our startup, one NAT Gateway is a good starting point.

**Route Tables — 2**
| Route Table	| Attached To |	Routes |
|---------------|-------------|--------|
| Public RT | public-subnet-a, public-subnet-b | Local (10.10.0.0/16) + 0.0.0.0/0 => IGW |
| Private RT | app-subnet-a/b, db-subnet-a/b | Local (10.10.0.0/16) + 0.0.0.0/0 => NAT GW |

**Bastion Host** — Yes, I would include one in the public-subnet-a
A bastion host will be placed in the public subnet to provide controlled SSH access to private instances. Engineers SSH into the bastion first, then from there SSH into app or database servers in the private subnets. This way, private instances never need a public IP.

**o	Security group rules provided for the bastion:**
| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Inbound | 22 | TCP | DevOps team IP only | SSH access from engineers |
| Outbound | 22 | TCP | 10.10.3.0/24, 10.10.4.0/24 | SSH into app servers |
| Outbound | 22 | TCP | 10.10.5.0/24, 10.10.6.0/24 | SSH into DB servers |

#### •	Traffic Flow Explanations

**Scenario 1: Customer in Lagos visits the ShopNaija website**
The customer's browser sends an HTTP/HTTPS request to the ShopNaija domain. The request travels over the public internet and arrives at the Internet Gateway attached to the VPC. The IGW forwards it to the Load Balancer sitting in the public subnet (public-subnet-a or public-subnet-b). The Load Balancer inspects forwards the request to one of the available app servers in the private subnets (app-subnet-a or app-subnet-b) based on the health check and routing rules. The app server processes the request, queries the database in the database subnet if needed, and sends a response back through the Load Balancer, through the IGW, and back to the customer's browser.

`Customer browser => Internet => Internet Gateway => Load Balancer (public subnet) => App Server (private subnet) => same path back`
 
 
**Scenario 2: DevOps engineer SSHes into a backend app server**
The engineer opens a terminal and SSHes into the Bastion Host using its public IP address. This request goes to the Bastion Host in public-subnet-a. From inside the bastion, the engineer then SSHes again using the private IP of the target app server in app-subnet-a or app-subnet-b. Because the bastion and app servers share the same VPC, this second SSH travels within the private network without touching the internet.

`Engineer terminal => Internet => Internet Gateway => Bastion Host (public-subnet-a) => App Server (app-subnet-a/b)`


**Scenario 3: App server calls the Paystack API to process a payment**
The app server in the private subnet has no public IP, it cannot reach the internet directly. Instead, it sends a request, which is routed to the NAT Gateway sitting in public-subnet-a. The NAT Gateway translates the private source IP to its own public IP (network address translation), then forwards the request through the Internet Gateway to the Paystack API on the public internet. The response follows the reverse path: 
Paystack => IGW => NAT Gateway => App Server.

`App Server (private subnet) => NAT Gateway (public-subnet-a) => Internet Gateway => Internet => Paystack API => same path back`

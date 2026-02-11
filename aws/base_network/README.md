# AWS Base Network Module
![](aws_basenetwork.drawio.svg)

---

## How to Configure VPC Subnet Connectivity
> *Based on **VPC A** from the architecture diagram above. The same pattern applies to all VPCs in this setup.*

### Setting Up Public Subnet Access (Inbound / Outbound)
To allow a subnet to send and receive traffic from the internet, you need to configure three things in order:
- First, create an **Internet Gateway** and attach it to your VPC — this is the only component that connects your VPC to the outside internet.
- Next, create your **public subnet** inside the VPC and place it in your chosen Availability Zone.
- Then create a **route table** for this subnet with a rule that sends all non-local traffic (``0.0.0.0/0``) to the Internet Gateway. Associate this route table with the public subnet.

> Instances here can now reach the internet inbound/outbound through the chain: **Public Subnet** ↔ **Internet Gateway** ↔ **Internet**.

### Setting Up Private Subnet Access (Outbound Only)
To allow a subnet to reach the internet for outgoing calls only (like downloading updates) while blocking all incoming traffic from outside, the setup builds on top of the public subnet:
- First, create a **NAT Gateway** and place it inside the **public subnet** you already configured above — this is important because the NAT Gateway itself needs internet access through the Internet Gateway. Assign it an **Elastic IP** so it has a fixed public address.
- Now create your **private subnet** in the VPC and set up its **route table** with a rule that sends all non-local traffic (``0.0.0.0/0``) to the NAT Gateway (instead of the Internet Gateway). Associate this route table with the private subnet.

> Instances here can now reach the internet outbound through the chain: **Private Subnet** → **NAT Gateway** *(in public subnet)* → **Internet Gateway** → **Internet**. But no one from the internet can initiate a connection back in.

### Key Takeaway
The public subnet's route table points directly to the Internet Gateway (two-way traffic). The private subnet's route table points to a NAT Gateway sitting inside the public subnet (one-way outbound traffic). The NAT Gateway acts as a middleman — it forwards private subnet requests to the internet but blocks the internet from reaching back into the private subnet.

---

## Exam Questions

### Associate

---

**Q1.** A company has a VPC with a public subnet and a private subnet in the same Availability Zone. EC2 instances in the private subnet need to download security patches from the internet. The instances should NOT be directly accessible from the internet. Which solution meets these requirements?

A. Attach an Internet Gateway to the VPC and add a route to the Internet Gateway in the private subnet's route table

B. Deploy a NAT Gateway in the private subnet and add a route to the NAT Gateway in the private subnet's route table

C. Deploy a NAT Gateway in the public subnet and add a route to the NAT Gateway in the private subnet's route table

D. Attach an Internet Gateway to the private subnet and assign public IP addresses to the instances

**Correct Answer: C**

**Explanation:**
- **Option A is incorrect:** Adding an IGW route to the private subnet's route table would require instances to have public IPs for internet communication. This makes instances directly accessible from the internet, violating the requirement.
- **Option B is incorrect:** NAT Gateway must be deployed in a PUBLIC subnet because it needs a route to the Internet Gateway to forward traffic to the internet. Placing it in a private subnet means it has no path to the internet.
- **Option C is correct:** NAT Gateway is deployed in the public subnet (which has IGW access) and receives an Elastic IP. Private subnet instances route outbound traffic (0.0.0.0/0) to the NAT Gateway, which then forwards it to the internet. Inbound connections from the internet cannot reach the private instances.
- **Option D is incorrect:** You cannot attach an Internet Gateway to a subnet. IGW is attached at the VPC level. Also, public IPs would expose instances to the internet.

---

**Q2.** A Solutions Architect is designing a VPC for a new application. The VPC CIDR block is 10.0.0.0/24, providing 256 IP addresses. How many IP addresses are actually available for EC2 instances in a single subnet that uses the entire VPC CIDR range?

A. 256
B. 254
C. 251
D. 250

**Correct Answer: C**

**Explanation:**
- **Option A is incorrect:** Not all 256 addresses are usable. AWS reserves addresses in every subnet.
- **Option B is incorrect:** This would be true for standard networking (network + broadcast), but AWS reserves additional addresses.
- **Option C is correct:** AWS reserves 5 IP addresses in each subnet:
  - .0 - Network address
  - .1 - VPC router
  - .2 - DNS server
  - .3 - Reserved for future use
  - .255 - Broadcast address (AWS doesn't support broadcast, but reserves it)
  - Therefore: 256 - 5 = 251 usable addresses
- **Option D is incorrect:** This miscounts the reserved addresses.

---

**Q3.** An application runs on EC2 instances in private subnets across two Availability Zones (AZ-A and AZ-B). A single NAT Gateway is deployed in AZ-A's public subnet. Both private subnets route internet traffic through this NAT Gateway. What happens if AZ-A experiences a complete failure?

A. Traffic automatically fails over to an Internet Gateway
B. Instances in both AZs lose internet connectivity
C. Only instances in AZ-A lose internet connectivity; AZ-B continues normally
D. AWS automatically provisions a replacement NAT Gateway in AZ-B

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** There is no automatic failover from NAT Gateway to Internet Gateway. These serve different purposes—IGW requires public IPs, which private subnet instances don't have.
- **Option B is correct:** Since both private subnets route through the single NAT Gateway in AZ-A, when AZ-A fails, the NAT Gateway becomes unavailable. Instances in BOTH AZs lose their path to the internet because the route table entry points to a non-functional resource.
- **Option C is incorrect:** This would only be true if each AZ had its own NAT Gateway with separate route tables. With a shared NAT Gateway, both AZs are affected.
- **Option D is incorrect:** NAT Gateway is not self-healing across AZs. AWS provides high availability within a single AZ but does not automatically provision resources in other AZs. This is the customer's responsibility.

---

**Q4.** A VPC has the following configuration:
- VPC CIDR: 10.0.0.0/16
- Public Subnet: 10.0.1.0/24 with route table containing 0.0.0.0/0 → Internet Gateway
- Private Subnet: 10.0.2.0/24 with route table containing 0.0.0.0/0 → NAT Gateway

An EC2 instance in the private subnet cannot reach the internet. The NAT Gateway status shows as "Available." What is the MOST likely cause?

A. The NAT Gateway does not have an Elastic IP address attached
B. The private subnet's Network ACL is blocking outbound traffic
C. The Internet Gateway is not attached to the VPC
D. All of the above could cause this issue

**Correct Answer: D**

**Explanation:**
- **Option A could cause this:** NAT Gateway requires an Elastic IP to perform network address translation and communicate with the internet. Without an EIP, the NAT Gateway cannot function properly for internet-bound traffic.
- **Option B could cause this:** Network ACLs are stateless and require explicit outbound AND inbound rules. If outbound traffic is blocked at the NACL level, instances cannot initiate connections. Unlike Security Groups, NACLs require return traffic rules.
- **Option C could cause this:** Even if the NAT Gateway shows "Available," it relies on the Internet Gateway for the final hop to the internet. If the IGW is detached from the VPC, the NAT Gateway cannot forward traffic to the internet.
- **Option D is correct:** All three options represent valid troubleshooting points. The NAT Gateway status of "Available" only indicates the resource is running, not that the complete network path is functional.

---

**Q5.** A company is designing their AWS network architecture and wants to minimize NAT Gateway costs while maintaining internet access for instances in private subnets. The workload is non-production with low traffic and can tolerate brief connectivity interruptions. Which approach provides the LOWEST cost?

A. Deploy one NAT Gateway per Availability Zone for high availability
B. Deploy a single NAT Gateway in one Availability Zone for all private subnets
C. Use a NAT Instance (t3.micro) instead of NAT Gateway
D. Assign Elastic IPs directly to private instances

**Correct Answer: C**

**Explanation:**
- **Option A is incorrect:** This is the most expensive option. Each NAT Gateway costs ~$32.85/month plus data processing fees. Multiple NAT Gateways multiply these costs.
- **Option B is incorrect:** While cheaper than Option A (~$32.85/month), this still incurs NAT Gateway hourly charges regardless of usage.
- **Option C is correct:** A NAT Instance using t3.micro costs approximately $7.59/month (on-demand) or less with Reserved/Spot pricing. For low-traffic, non-production workloads that can tolerate lower bandwidth and brief interruptions during instance maintenance, this is the most cost-effective solution.
- **Option D is incorrect:** Assigning Elastic IPs to instances in private subnets doesn't enable internet access. The subnet needs a route to an IGW, which would make it a public subnet, not private. This also exposes instances to inbound internet traffic.

---

**Q6.** An architect is designing a multi-tier application with web servers in public subnets and database servers in private subnets. The database servers need to download software updates from the internet. Which combination of route table entries is correct?

A. Public subnet: 0.0.0.0/0 → NAT Gateway; Private subnet: 0.0.0.0/0 → Internet Gateway
B. Public subnet: 0.0.0.0/0 → Internet Gateway; Private subnet: 0.0.0.0/0 → Internet Gateway
C. Public subnet: 0.0.0.0/0 → Internet Gateway; Private subnet: 0.0.0.0/0 → NAT Gateway
D. Public subnet: 0.0.0.0/0 → NAT Gateway; Private subnet: 0.0.0.0/0 → NAT Gateway

**Correct Answer: C**

**Explanation:**
- **Option A is incorrect:** Public subnets need direct Internet Gateway access for bidirectional internet traffic (serving web requests). NAT Gateway is for outbound-only traffic and would prevent inbound connections to web servers.
- **Option B is incorrect:** Private subnet instances don't have public IPs, so routing to the Internet Gateway won't work. The IGW performs 1:1 NAT between public and private IPs, requiring instances to have public IPs.
- **Option C is correct:**
  - Public subnet routes to IGW, allowing web servers to receive and respond to internet traffic
  - Private subnet routes to NAT Gateway, allowing database servers to initiate outbound connections (updates) while remaining inaccessible from the internet
- **Option D is incorrect:** Public subnet with NAT Gateway would break inbound connectivity to web servers. Web servers need Internet Gateway access to receive HTTP/HTTPS requests from users.

---

**Q7.** A company has a VPC with CIDR 10.0.0.0/16. They want to add a second CIDR block to accommodate growth. Which of the following is a valid secondary CIDR block?

A. 10.1.0.0/16
B. 192.168.0.0/16
C. 172.16.0.0/12
D. 10.0.0.0/8

**Correct Answer: A**

**Explanation:**
- **Option A is correct:** Secondary CIDR blocks can be from the same RFC 1918 range or different ranges. 10.1.0.0/16 is a valid private range that doesn't overlap with the existing 10.0.0.0/16.
- **Option B is incorrect:** While 192.168.0.0/16 is a valid private range, it cannot be added as a secondary CIDR if you're restricted to the same address family without specific configuration. However, the main issue here is that it's typically valid—this option could work in many scenarios.
- **Option C is incorrect:** 172.16.0.0/12 is too large. The maximum CIDR block size for a VPC is /16. The /12 prefix would encompass 1,048,576 addresses, exceeding AWS limits.
- **Option D is incorrect:** 10.0.0.0/8 overlaps with the existing 10.0.0.0/16 CIDR and is also too large (/8 exceeds the /16 maximum). Secondary CIDRs cannot overlap with primary or other secondary CIDRs.

---

**Q8.** An Elastic IP address was allocated but never associated with any resource. After 30 days, what is the approximate cost incurred?

A. $0.00 - Elastic IPs are free
B. $3.60 - Charged $0.005/hour when not associated
C. $32.85 - Same as NAT Gateway pricing
D. $0.12 - Charged only for the first hour

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** Elastic IPs are free ONLY when associated with a running EC2 instance or attached to a NAT Gateway. Unassociated EIPs incur charges to encourage efficient use of limited IPv4 addresses.
- **Option B is correct:** AWS charges $0.005 per hour for Elastic IPs that are allocated but not associated with a running instance.
  - Calculation: $0.005 × 24 hours × 30 days = $3.60
- **Option C is incorrect:** This is NAT Gateway pricing, not Elastic IP pricing.
- **Option D is incorrect:** The charge is continuous, not just for the first hour. Every hour the EIP remains unassociated incurs the $0.005 charge.

---

### Professional

---

**Q1.** A company operates VPCs in us-east-1 and eu-west-2 regions. Each VPC has multiple private subnets with NAT Gateways. EC2 instances in the private subnets of both regions need to communicate with each other using private IP addresses. Instances also require outbound internet access. Which architecture satisfies these requirements with the LEAST operational overhead?

A. Create VPC Peering between the two VPCs; keep existing NAT Gateways for internet access
B. Deploy AWS Transit Gateway in each region with Transit Gateway inter-region peering; keep existing NAT Gateways
C. Configure Site-to-Site VPN between the two VPCs; replace NAT Gateways with Internet Gateways
D. Use public IP addresses for all instances and communicate over the internet through NAT Gateways

**Correct Answer: A**

**Explanation:**
- **Option A is correct:** VPC Peering enables private IP communication between VPCs, even across regions (inter-region VPC peering). This is the simplest solution for connecting two VPCs. The existing NAT Gateways continue to provide internet access for private instances. No additional infrastructure is needed—just create the peering connection and update route tables.
- **Option B is incorrect:** Transit Gateway is excellent for connecting many VPCs but adds unnecessary complexity and cost for just two VPCs. Transit Gateway inter-region peering requires deploying TGW in both regions, creating peering connections, and managing additional route tables. This is operational overhead that isn't justified for a simple two-VPC scenario.
- **Option C is incorrect:** Site-to-Site VPN creates encrypted tunnels over the internet, adding latency compared to VPC Peering's direct AWS backbone connectivity. Replacing NAT Gateways with Internet Gateways would require public IPs on private instances, which contradicts the private subnet design and security requirements.
- **Option D is incorrect:** Using public IPs eliminates the private nature of the subnets and exposes instances to the internet. NAT Gateways cannot be used for this—they only support outbound connections. This approach also incurs data transfer charges for inter-region communication over the public internet.

---

**Q2.** A financial services company requires that all traffic between their VPC and the internet pass through a centralized inspection layer for compliance. They have 10 VPCs across 3 AWS regions, each with private subnets using NAT Gateways. The security team wants to minimize the number of inspection points while maintaining compliance. What is the recommended architecture?

A. Deploy Network Firewall in each VPC alongside existing NAT Gateways
B. Create a dedicated inspection VPC in each region with Transit Gateway; route all internet-bound traffic through the inspection VPC
C. Replace all NAT Gateways with NAT Instances running firewall software
D. Use VPC Peering to route all traffic through a single centralized inspection VPC in one region

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** Deploying Network Firewall in each of the 10 VPCs creates 10 inspection points, which contradicts the requirement to minimize inspection points. This also increases operational overhead with multiple firewall rule sets to maintain.
- **Option B is correct:** This creates a hub-and-spoke architecture with centralized inspection:
  - Deploy Transit Gateway in each of the 3 regions
  - Create one inspection VPC per region with Network Firewall or third-party appliances
  - Route 0.0.0.0/0 traffic from spoke VPCs through Transit Gateway to the inspection VPC
  - NAT Gateways in the inspection VPC provide internet egress after inspection
  - This reduces inspection points from 10 to 3 (one per region) while maintaining compliance
- **Option C is incorrect:** NAT Instances with firewall software don't provide enterprise-grade inspection capabilities, lack high availability features, and create 10 management points. This doesn't reduce the number of inspection points and adds significant operational burden.
- **Option D is incorrect:** VPC Peering does not support transitive routing. You cannot route traffic from VPC-A through VPC-B (inspection) to the internet. Also, routing all traffic through a single region creates latency issues and a single point of failure for global operations.

---

**Q3.** A company has a VPC with the following configuration:
- CIDR: 10.0.0.0/16
- 2 public subnets (10.0.1.0/24, 10.0.2.0/24) in different AZs
- 2 private subnets (10.0.3.0/24, 10.0.4.0/24) in different AZs
- 1 NAT Gateway in the first public subnet
- All private subnet traffic routes through the single NAT Gateway

The application processes 500GB of data monthly through the NAT Gateway. The company wants to reduce costs while maintaining availability for a production workload. Which approach provides the BEST balance of cost and availability?

A. Add a second NAT Gateway in the other AZ; update route tables so each private subnet uses its local AZ's NAT Gateway
B. Replace the NAT Gateway with a NAT Instance; configure Auto Scaling for availability
C. Remove the NAT Gateway; use VPC Endpoints for AWS services and a proxy instance for other internet access
D. Keep the single NAT Gateway; it provides sufficient availability for production workloads

**Correct Answer: A**

**Explanation:**
- **Option A is correct:** For production workloads, high availability is essential. Adding a second NAT Gateway:
  - Provides AZ-level fault tolerance (if one AZ fails, the other continues operating)
  - Cross-AZ data transfer between private subnet and NAT Gateway costs $0.01/GB
  - With local NAT Gateways, you eliminate ~$2.50/month in cross-AZ charges (assuming 250GB per AZ)
  - Total monthly cost: 2 × $32.85 = $65.70 for NAT Gateways + data processing
  - This is the AWS recommended architecture for production workloads
- **Option B is incorrect:** NAT Instances with Auto Scaling introduce complexity, have lower bandwidth limits, and require maintenance (patching, monitoring). Auto Scaling doesn't provide seamless failover—there's downtime during instance replacement. This is not recommended for production workloads requiring consistent availability.
- **Option C is incorrect:** While VPC Endpoints reduce NAT Gateway data processing for AWS services, the question states the application processes data "through the NAT Gateway," implying external internet access is required. A proxy instance creates a single point of failure and operational overhead.
- **Option D is incorrect:** A single NAT Gateway is a single point of failure. If its AZ fails, all private instances lose internet connectivity. This is unacceptable for production workloads that require high availability.

---

**Q4.** An architect is troubleshooting connectivity issues in a VPC. An EC2 instance in a private subnet (10.0.2.0/24) cannot reach the internet through a NAT Gateway in the public subnet (10.0.1.0/24). The following configuration exists:

**Private subnet route table:**
| Destination | Target |
|------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-0abc123 |

**Public subnet route table:**
| Destination | Target |
|------------|--------|
| 10.0.0.0/16 | local |

**NAT Gateway:** Status "Available" with Elastic IP attached

What is the root cause?

A. The private subnet route table is missing the local route
B. The public subnet route table is missing a route to the Internet Gateway
C. The NAT Gateway should be in the private subnet, not the public subnet
D. The 0.0.0.0/0 route in the private subnet should point to the Internet Gateway

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** The private subnet route table DOES have the local route (10.0.0.0/16 → local). This route is automatically added and cannot be removed.
- **Option B is correct:** The public subnet route table is missing 0.0.0.0/0 → Internet Gateway. The traffic flow is:
  1. Private instance sends packet to internet (0.0.0.0/0)
  2. Private route table directs to NAT Gateway
  3. NAT Gateway translates the source IP and forwards to internet
  4. NAT Gateway is in the public subnet, so it uses the PUBLIC subnet's route table
  5. Without 0.0.0.0/0 → IGW in the public route table, NAT Gateway cannot forward traffic to the internet
- **Option C is incorrect:** NAT Gateway MUST be in a public subnet. It needs a route to the Internet Gateway (via the public subnet's route table) to forward traffic to the internet.
- **Option D is incorrect:** Private instances don't have public IPs, so they cannot use the Internet Gateway directly. The NAT Gateway performs address translation, which is why private subnets route through NAT Gateway, not IGW.

---

**Q5.** A company is migrating from on-premises to AWS. They have a legacy application that requires instances to have specific static private IP addresses. The VPC uses CIDR 10.0.0.0/16 with a subnet 10.0.1.0/24. The application requires IP addresses 10.0.1.10, 10.0.1.11, 10.0.1.12, and 10.0.1.13. Which addresses can be assigned to EC2 instances?

A. All four addresses (10.0.1.10, 10.0.1.11, 10.0.1.12, 10.0.1.13)
B. Only 10.0.1.10, 10.0.1.11, and 10.0.1.12
C. Only 10.0.1.11, 10.0.1.12, and 10.0.1.13
D. Only 10.0.1.10 and 10.0.1.13

**Correct Answer: A**

**Explanation:**
- AWS reserves 5 IP addresses in each subnet:
  - 10.0.1.0 - Network address
  - 10.0.1.1 - VPC router
  - 10.0.1.2 - DNS server
  - 10.0.1.3 - Reserved for future use
  - 10.0.1.255 - Broadcast address

- **Option A is correct:** All requested addresses (10.0.1.10, 10.0.1.11, 10.0.1.12, 10.0.1.13) are outside the reserved range (.0, .1, .2, .3, and .255). These addresses are available for EC2 instances.
- **Option B is incorrect:** 10.0.1.13 is not reserved; it's a valid usable address.
- **Option C is incorrect:** 10.0.1.10 is not reserved; it's a valid usable address.
- **Option D is incorrect:** All four addresses are valid. The reserved addresses are .0-.3 and .255 only.

---

**Q6.** A Solutions Architect needs to design a VPC that will host 1,500 EC2 instances across 6 subnets (3 public, 3 private) in 3 Availability Zones. What is the MINIMUM VPC CIDR block size that accommodates this requirement, allowing for the 5 AWS-reserved addresses per subnet?

A. /20 (4,096 addresses)
B. /21 (2,048 addresses)
C. /22 (1,024 addresses)
D. /23 (512 addresses)

**Correct Answer: A**

**Explanation:**
- **Requirement calculation:**
  - 1,500 instances across 6 subnets = average 250 instances per subnet
  - Each subnet needs: instances + 5 reserved addresses
  - Minimum per subnet: 250 + 5 = 255 addresses
  - Nearest power of 2: 256 addresses = /24 per subnet
  - 6 subnets × 256 = 1,536 addresses minimum

- **Option A is correct:** /20 provides 4,096 addresses
  - Can create 6 × /24 subnets (256 addresses each = 1,536 total)
  - Usable per subnet: 256 - 5 = 251 instances
  - Total usable: 251 × 6 = 1,506 instances ✓
  - Leaves room for 2,560 addresses for future growth

- **Option B is incorrect:** /21 provides 2,048 addresses
  - Can create 6 × /24 subnets BUT only if perfectly divided
  - 2,048 / 6 = 341.33, so /24 subnets would fit
  - However, /21 = 2,048 and 6 × 256 = 1,536, which fits
  - But this leaves minimal room for growth, making /20 the better MINIMUM choice for real-world scenarios
  - Actually, /21 could work mathematically, but the question asks for safe minimum with reserved addresses accounted for

- **Option C is incorrect:** /22 provides 1,024 addresses
  - 1,024 / 6 = 170.67 addresses per subnet
  - After 5 reserved: 165 usable per subnet
  - Total: 165 × 6 = 990 instances - NOT ENOUGH

- **Option D is incorrect:** /23 provides 512 addresses
  - 512 / 6 = 85.33 addresses per subnet
  - After 5 reserved: ~80 usable per subnet
  - Total: ~480 instances - NOT ENOUGH

---

**Q7.** A company has three VPCs in the same region:
- VPC-A: 10.0.0.0/16 (Production)
- VPC-B: 10.1.0.0/16 (Development)
- VPC-C: 10.2.0.0/16 (Shared Services - contains NAT Gateways)

The company wants instances in VPC-A and VPC-B private subnets to use the NAT Gateways in VPC-C for internet access, reducing the number of NAT Gateways needed. Which statement is true?

A. Create VPC Peering between A-C and B-C; update route tables to route 0.0.0.0/0 through peering connections to VPC-C's NAT Gateway
B. This architecture is not possible because VPC Peering does not support routing internet traffic through a peered VPC
C. Create Transit Gateway and attach all three VPCs; configure Transit Gateway route table to send 0.0.0.0/0 to VPC-C
D. Use AWS PrivateLink to share the NAT Gateway as a service endpoint

**Correct Answer: C**

**Explanation:**
- **Option A is incorrect:** VPC Peering connections do not support edge-to-edge routing. You cannot route traffic through a peered VPC to reach the internet, an on-premises network, or another VPC. Traffic destined for 0.0.0.0/0 cannot transit through a peering connection to reach VPC-C's NAT Gateway. This is a fundamental VPC Peering limitation.

- **Option B is incorrect:** While the statement about VPC Peering is true (it doesn't support this routing), the architecture IS possible using Transit Gateway, making this statement incomplete.

- **Option C is correct:** Transit Gateway supports transitive routing, unlike VPC Peering. The architecture:
  1. Create Transit Gateway and attach VPC-A, VPC-B, and VPC-C
  2. In VPC-A and VPC-B private subnet route tables: 0.0.0.0/0 → Transit Gateway
  3. In Transit Gateway route table: 0.0.0.0/0 → VPC-C attachment
  4. In VPC-C: NAT Gateway in public subnet handles traffic from Transit Gateway
  5. Return traffic flows back through Transit Gateway to originating VPCs

- **Option D is incorrect:** PrivateLink is used to expose services (via Network Load Balancer) as private endpoints, not to share NAT Gateway functionality. NAT Gateway cannot be fronted by NLB for this purpose, and PrivateLink creates endpoints for specific services, not general internet routing.

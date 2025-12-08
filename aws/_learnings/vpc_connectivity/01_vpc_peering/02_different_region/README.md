# VPC Peering - Cross-Region (Different Region)

## Exam Questions

### Associate

---

**Q1.** A company has two VPCs in different AWS regions:
- VPC-A in us-east-1 (N. Virginia): 10.0.0.0/16
- VPC-C in eu-west-2 (London): 192.168.0.0/16

They want to establish VPC peering between these VPCs. What is required for the peering connection to become active?

A. Set auto_accept = true on the peering request since it's the same AWS account

B. Create a peering request in us-east-1 specifying eu-west-2 as peer_region, then accept the request in eu-west-2

C. VPC peering does not support cross-region connectivity; use AWS Transit Gateway instead

D. Create identical peering connections in both regions simultaneously

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** Cross-region VPC peering does NOT support auto_accept, even within the same account. This is only available for same-region peering.
- **Option B is correct:** For cross-region VPC peering:
  1. Create a peering request in the requester region (us-east-1)
  2. Specify `peer_region` = "eu-west-2" in the request
  3. Create an accepter resource in the peer region (eu-west-2) to accept the connection
  4. Update route tables in BOTH regions
  This two-step process is required because the VPCs exist in different regions with separate AWS control planes.
- **Option C is incorrect:** VPC peering fully supports cross-region connectivity. Transit Gateway is an alternative but not required.
- **Option D is incorrect:** You create ONE peering connection from the requester side and accept it from the accepter side; you don't create two separate connections.

---

**Q2.** After establishing cross-region VPC peering between us-east-1 and eu-west-2, an EC2 instance in us-east-1 cannot communicate with an instance in eu-west-2. The peering connection shows "Active" status. What should be checked first?

A. Whether DNS resolution is enabled on the peering connection

B. Whether route tables in both regions have routes pointing to the peer VPC's CIDR via the peering connection

C. Whether the instances are using the same security group

D. Whether both instances have public IP addresses

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** DNS resolution settings affect DNS queries across peered VPCs but don't affect basic IP connectivity. If instances can't ping each other by IP, DNS isn't the issue.
- **Option B is correct:** The most common issue after creating VPC peering is missing routes. You must add routes in BOTH regions:
  - us-east-1 route tables: 192.168.0.0/16 → pcx-xxxxx
  - eu-west-2 route tables: 10.0.0.0/16 → pcx-xxxxx
  Routes are NOT automatically added when creating a peering connection.
- **Option C is incorrect:** Security groups cannot be shared across regions. Each region needs its own security groups, and they must allow traffic from the peer VPC's CIDR.
- **Option D is incorrect:** VPC peering uses private IP addresses. Public IPs are not required for peering connectivity.

---

**Q3.** A Solutions Architect is designing a cross-region VPC peering solution. The application requires low latency communication. Which statement about cross-region VPC peering latency is accurate?

A. Cross-region VPC peering adds zero additional latency because it uses AWS's private backbone

B. Cross-region VPC peering latency is primarily determined by the physical distance between regions (typically 60-100ms between us-east-1 and eu-west-2)

C. Cross-region VPC peering has a fixed 10ms latency regardless of region distance

D. Latency can be reduced to same-region levels by enabling "accelerated peering"

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** While VPC peering uses AWS's private backbone (not the public internet), physical distance still introduces latency. Speed of light limitations apply even on private networks.
- **Option B is correct:** Cross-region latency is primarily determined by:
  - Physical distance between regions
  - Network hops within AWS backbone
  - Typical latencies:
    - us-east-1 to us-west-2: ~60-70ms
    - us-east-1 to eu-west-2: ~70-90ms
    - us-east-1 to ap-southeast-1: ~200-250ms
  This is significantly higher than same-region latency (~1-2ms).
- **Option C is incorrect:** There is no fixed latency; it varies by region distance.
- **Option D is incorrect:** There is no "accelerated peering" feature for VPC peering. AWS Global Accelerator is a different service that doesn't apply to VPC peering.

---

**Q4.** A company has established cross-region VPC peering between us-east-1 and eu-west-2. What are the data transfer costs for traffic flowing through this peering connection?

A. Free - VPC peering has no data transfer charges

B. Standard inter-region data transfer rates apply ($0.02/GB or higher depending on regions)

C. Same as intra-region rates since it's using AWS backbone

D. Only charged for egress, ingress is free

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** Only SAME-region VPC peering data transfer is free. Cross-region peering incurs charges.
- **Option B is correct:** Cross-region VPC peering data transfer is charged at standard inter-region rates:
  - Data transferred "out" to a peered VPC in another region is charged
  - Rates vary by region pair (typically $0.02/GB for US-EU traffic)
  - This is the same as other cross-region data transfer (EC2, S3, etc.)
  - Data transfer can become significant for high-throughput applications
- **Option C is incorrect:** Using AWS backbone doesn't exempt you from cross-region charges. The backbone is for security and reliability, not cost.
- **Option D is incorrect:** Both directions are considered when calculating charges, though the billing model charges the sender.

---

**Q5.** An architect needs to create cross-region VPC peering using Terraform. Which provider configuration is correct?

A. Use a single provider and specify `peer_region` in the resource

B. Configure two providers with region aliases, use `aws_vpc_peering_connection` with one provider and `aws_vpc_peering_connection_accepter` with the other

C. Use `aws_vpc_peering_connection` with `auto_accept = true` and `peer_region` specified

D. Create the peering connection resource in both providers simultaneously

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** While you can specify `peer_region` in the peering request, you need a second provider to accept the connection in the peer region.
- **Option B is correct:** The correct Terraform pattern for cross-region peering:
  ```hcl
  provider "aws" {
    alias  = "nvirginia"
    region = "us-east-1"
  }
  provider "aws" {
    alias  = "london"
    region = "eu-west-2"
  }

  resource "aws_vpc_peering_connection" "requester" {
    provider    = aws.nvirginia
    peer_region = "eu-west-2"
    # ... other config
  }

  resource "aws_vpc_peering_connection_accepter" "accepter" {
    provider                  = aws.london
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
    auto_accept              = true
  }
  ```
- **Option C is incorrect:** `auto_accept = true` doesn't work for cross-region peering; you need a separate accepter resource.
- **Option D is incorrect:** You create ONE peering connection and ONE accepter, not two peering connections.

---

### Professional

---

**Q1.** A multinational company has the following VPC setup:
- VPC-HQ in us-east-1 (10.0.0.0/16) - Headquarters
- VPC-EU in eu-west-2 (172.16.0.0/16) - European Office
- VPC-APAC in ap-southeast-1 (192.168.0.0/16) - Asia Pacific Office

They want all three VPCs to communicate with each other using VPC peering. How many peering connections are needed, and what is a key limitation to consider?

A. 1 peering connection; VPC peering supports transitive routing between regions

B. 3 peering connections; each region pair needs a direct peering connection, and latency between us-east-1 and ap-southeast-1 will be highest

C. 2 peering connections; traffic from eu-west-2 to ap-southeast-1 can route through us-east-1

D. 3 peering connections; but this architecture is not recommended due to bandwidth limits on cross-region peering

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** VPC peering does NOT support transitive routing, regardless of regions. Each VPC pair needs its own peering connection.
- **Option B is correct:**
  - 3 peering connections needed: HQ↔EU, HQ↔APAC, EU↔APAC
  - Full mesh formula: N×(N-1)/2 = 3×2/2 = 3
  - Latency varies significantly by region pair:
    - us-east-1 ↔ eu-west-2: ~70-90ms
    - us-east-1 ↔ ap-southeast-1: ~200-250ms
    - eu-west-2 ↔ ap-southeast-1: ~180-220ms
  - Applications need to account for these latency differences.
- **Option C is incorrect:** VPC peering is non-transitive; EU cannot reach APAC through HQ even if both are peered with HQ.
- **Option D is incorrect:** VPC peering has no bandwidth limits; it uses AWS backbone without bottlenecks. However, costs increase with cross-region traffic.

---

**Q2.** A company is troubleshooting their cross-region VPC peering setup:
- VPC-A in us-east-1 (10.0.0.0/16) peered with VPC-C in eu-west-2 (192.168.0.0/16)
- Peering connection status: Active
- Route tables updated in both regions
- Security groups allow ICMP from peer VPC CIDR

An instance in us-east-1 (10.0.1.50) can ping an instance in eu-west-2 (192.168.0.20), but the eu-west-2 instance cannot initiate connections to us-east-1. What is the most likely cause?

A. Cross-region VPC peering only allows one-way traffic from requester to accepter

B. Network ACLs in us-east-1 are blocking inbound traffic from 192.168.0.0/16

C. The security group in us-east-1 doesn't allow inbound traffic from the eu-west-2 CIDR

D. The route table in eu-west-2 is missing or has an incorrect route to 10.0.0.0/16

**Correct Answer: C or D (depends on specific scenario, but C is most likely given the stated setup)**

**Explanation:**
- **Option A is incorrect:** VPC peering is fully bidirectional. Both requester and accepter VPCs can initiate connections.
- **Option B is possible:** Network ACLs are stateless. If the eu-west-2 subnet's NACL doesn't have explicit rules allowing return traffic from us-east-1, connections would fail. However, default NACLs allow all traffic.
- **Option C is correct:** The question states "security groups allow ICMP from peer VPC CIDR" but this is often misconfigured:
  - The us-east-1 security group must allow inbound from 192.168.0.0/16
  - The eu-west-2 security group must allow inbound from 10.0.0.0/16
  - If only one direction is configured, traffic works one way only
  - Security groups are stateful, so if us-east-1→eu-west-2 works, the return traffic is allowed. But NEW connections from eu-west-2 need explicit inbound rules on us-east-1.
- **Option D is possible:** If the route table in eu-west-2 is missing the route to 10.0.0.0/16, traffic cannot be initiated from eu-west-2. However, the question states "route tables updated in both regions."

---

**Q3.** A Solutions Architect is evaluating cross-region VPC peering vs. AWS Transit Gateway for connecting 4 VPCs across 2 regions (2 VPCs per region). All VPCs need full mesh connectivity. Which factors favor using VPC peering over Transit Gateway?

A. VPC peering is better because it supports transitive routing, reducing management overhead

B. VPC peering is better for lower latency point-to-point connections and has no per-GB data processing charges

C. Transit Gateway is always preferred for multi-region scenarios due to simplified routing

D. VPC peering cannot span regions, so Transit Gateway is the only option

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** VPC peering does NOT support transitive routing. This is actually a disadvantage requiring more peering connections.
- **Option B is correct:** VPC peering advantages over Transit Gateway:
  - **Lower latency:** Direct point-to-point connection without intermediate hops
  - **No data processing charges:** TGW charges $0.02/GB processed; VPC peering has no processing fee
  - **No hourly charges:** TGW has hourly attachment fees (~$0.05/hour per attachment)
  - For 4 VPCs with full mesh:
    - VPC Peering: 6 connections, inter-region data transfer only
    - TGW: 4 attachments × 2 TGWs + peering, plus data processing + hourly fees
  - For steady-state high-throughput workloads, VPC peering can be significantly cheaper
- **Option C is incorrect:** Transit Gateway offers simpler routing but at higher cost. The "better" choice depends on requirements.
- **Option D is incorrect:** VPC peering fully supports cross-region connectivity.

---

**Q4.** A company has cross-region VPC peering between us-east-1 and eu-west-2. They want instances in eu-west-2 to resolve private DNS hostnames of instances in us-east-1 (e.g., `ip-10-0-1-50.ec2.internal`). What configuration is required?

A. DNS resolution works automatically over VPC peering; no additional configuration needed

B. Enable "DNS resolution from accepter VPC" and "DNS resolution from requester VPC" on the peering connection from both sides

C. Create Route 53 Private Hosted Zones and associate with both VPCs

D. Cross-region VPC peering does not support DNS resolution; use IP addresses instead

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** DNS resolution across peered VPCs requires explicit configuration; it's not automatic.
- **Option B is correct:** To enable private DNS resolution across cross-region VPC peering:
  1. Modify the peering connection settings
  2. Enable "Allow DNS resolution from accepter VPC to requester VPC" (in accepter region)
  3. Enable "Allow DNS resolution from requester VPC to accepter VPC" (in requester region)
  4. Both settings needed for bidirectional DNS resolution
  5. Instances can then resolve private hostnames like `ip-10-0-1-50.ec2.internal`

  In Terraform:
  ```hcl
  resource "aws_vpc_peering_connection_options" "requester" {
    provider = aws.nvirginia
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
    requester {
      allow_remote_vpc_dns_resolution = true
    }
  }

  resource "aws_vpc_peering_connection_options" "accepter" {
    provider = aws.london
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
    accepter {
      allow_remote_vpc_dns_resolution = true
    }
  }
  ```
- **Option C is incorrect:** Route 53 Private Hosted Zones are an alternative but don't enable resolution of EC2 internal DNS names like `ip-x-x-x-x.ec2.internal`.
- **Option D is incorrect:** Cross-region peering does support DNS resolution; it just requires configuration.

---

**Q5.** A financial services company operates in us-east-1 and eu-west-2 with cross-region VPC peering for disaster recovery. They need to ensure compliance with data residency requirements. Which statement is correct about data flow over cross-region VPC peering?

A. Data flows over the public internet but is encrypted by AWS automatically

B. Data stays on AWS private backbone and never traverses the public internet, but is not encrypted by default

C. Data is automatically encrypted with AWS-managed keys when crossing regions

D. Cross-region VPC peering routes traffic through AWS Direct Connect regardless of customer configuration

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** VPC peering traffic stays on AWS private backbone and never uses the public internet.
- **Option B is correct:** Key points about cross-region VPC peering data flow:
  - **Private backbone:** All traffic stays within AWS's private global network
  - **No public internet:** Traffic is never exposed to public internet paths
  - **Not encrypted by default:** VPC peering provides private routing but NOT encryption
  - **Encryption responsibility:** If encryption in transit is required, applications must implement TLS/SSL or use VPN over the peering connection
  - **Compliance implications:** Data residency is about WHERE data is stored/processed. VPC peering itself doesn't change where data resides; it just enables communication.
- **Option C is incorrect:** AWS does NOT automatically encrypt VPC peering traffic. This is the customer's responsibility.
- **Option D is incorrect:** Direct Connect is a separate service; VPC peering uses AWS backbone independently of Direct Connect.

---

**Q6.** An architect is designing a hybrid cloud architecture with:
- On-premises data center connected via VPN to VPC-A in us-east-1
- VPC-A peered with VPC-C in eu-west-2

Can on-premises servers access resources in VPC-C through VPC-A?

A. Yes, VPN traffic can transit through VPC-A to reach VPC-C via the peering connection

B. No, VPC peering does not support transitive routing; a separate VPN or Direct Connect to eu-west-2 is needed

C. Yes, but only if "Gateway routing" is enabled on the peering connection

D. Yes, if the on-premises network configures VPC-A as a transit point

**Correct Answer: B**

**Explanation:**
- **Option A is incorrect:** VPC peering does NOT allow VPN traffic to transit through to peered VPCs.
- **Option B is correct:** VPC peering is explicitly non-transitive for:
  - VPN connections
  - Direct Connect connections
  - Internet Gateway access
  - NAT Gateway access
  - VPC endpoint access

  To reach VPC-C from on-premises:
  - Option 1: Create separate VPN/Direct Connect to VPC-C
  - Option 2: Use AWS Transit Gateway (supports transitive routing)
  - Option 3: Use EC2 instances as software routers (complex, not recommended)

  The routing table in VPC-A cannot forward VPN traffic to the peering connection even if routes are added.
- **Option C is incorrect:** There is no "Gateway routing" option on VPC peering connections.
- **Option D is incorrect:** The on-premises network configuration cannot override VPC peering's non-transitive nature; this is an AWS infrastructure limitation.

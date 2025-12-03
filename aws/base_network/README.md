# AWS Base Network Module

## Cost Estimation

### Fixed Monthly Costs (per NAT Gateway)

| Item | Calculation | Monthly Cost |
|------|-------------|--------------|
| NAT Gateway | $0.045 × 730 hours | ~$32.85 |
| Elastic IP (associated) | Free when attached to NAT GW | $0.00 |
| **Subtotal per NAT GW** | | **~$32.85** |

**Current Configuration:**

| Region | VPCs | NAT Gateways | Monthly Cost |
|--------|------|--------------|--------------|
| N. Virginia (us-east-1) | vpc_a, vpc_b | 2 | ~$65.70 |
| London (eu-west-2) | vpc_c | 1 | ~$32.85 |
| **Total** | **3 VPCs** | **3 NAT GWs** | **~$98.55/month** |

### Variable Costs

| Item | Rate | Notes |
|------|------|-------|
| NAT Gateway Data Processing | $0.045/GB | Charged for all data processed through NAT GW |
| Data Transfer Out to Internet | $0.09/GB | First 10TB/month (standard AWS data transfer) |
| Cross-Region Data Transfer | $0.02/GB | Between us-east-1 and eu-west-2 |

**Example Monthly Cost (100GB data processing per NAT Gateway):**

| Component | Calculation | Cost |
|-----------|-------------|------|
| Fixed NAT Gateway costs | 3 NAT GWs × $32.85 | $98.55 |
| Data processing | 3 × 100GB × $0.045 | $13.50 |
| **Estimated Total** | | **~$112.05/month** |

> **Note**: Prices shown are approximate for us-east-1 and eu-west-2 regions. Refer to [AWS VPC Pricing](https://aws.amazon.com/vpc/pricing/) for current rates.

---

## Exam Questions

### Associate

**Q1: What is the purpose of a NAT Gateway in AWS?**

**Answer:** A NAT Gateway enables instances in a private subnet to connect to the internet or other AWS services while preventing the internet from initiating connections to those instances. It performs network address translation (NAT) for outbound traffic, allowing private instances to access software updates, external APIs, and other internet resources without exposing them to inbound internet traffic.

---

**Q2: What is the difference between an Internet Gateway and a NAT Gateway?**

**Answer:**
- **Internet Gateway (IGW)**: Allows resources with public IP addresses in public subnets to communicate directly with the internet. Traffic flows bidirectionally.
- **NAT Gateway**: Allows resources in private subnets (without public IPs) to initiate outbound connections to the internet while blocking inbound connections from the internet. Traffic is unidirectional (outbound only).

---

**Q3: A company has a VPC with public and private subnets across two Availability Zones. Instances in private subnets need internet access for software updates. What is the most highly available solution?**

**Answer:** Deploy a NAT Gateway in each Availability Zone's public subnet and configure the private subnet route tables to direct internet-bound traffic (0.0.0.0/0) to the NAT Gateway in the same AZ. This ensures high availability because if one AZ fails, instances in the other AZ can still access the internet through their local NAT Gateway.

---

**Q4: What happens to a NAT Gateway if its Availability Zone experiences a failure?**

**Answer:** If the AZ containing a NAT Gateway fails, all resources in private subnets routing through that NAT Gateway will lose internet connectivity. NAT Gateways are not automatically resilient across AZs. To achieve high availability, you must deploy separate NAT Gateways in each AZ and configure appropriate routing.

---

**Q5: Which of the following are valid use cases for VPC Peering?**

**Answer:**
- Connecting VPCs within the same AWS account
- Connecting VPCs across different AWS accounts
- Connecting VPCs across different AWS regions (inter-region peering)
- Enabling private IP communication between instances in peered VPCs

**Note:** VPC peering does NOT support transitive routing. If VPC-A is peered with VPC-B, and VPC-B is peered with VPC-C, VPC-A cannot communicate with VPC-C through VPC-B.

---

**Q6: What is the maximum CIDR block size for an AWS VPC?**

**Answer:** The maximum CIDR block size for a VPC is /16 (65,536 IP addresses). The minimum is /28 (16 IP addresses). AWS reserves 5 IP addresses in each subnet (first 4 and last 1) for internal networking purposes.

---

**Q7: A Solutions Architect needs to allow an EC2 instance in a private subnet to access an S3 bucket without traversing the internet. What is the most cost-effective solution?**

**Answer:** Create a Gateway VPC Endpoint for S3. Gateway endpoints for S3 and DynamoDB are free and route traffic directly to the service through the AWS private network, avoiding NAT Gateway data processing charges and internet data transfer costs.

---

### Professional

**Q1: A multinational company has VPCs in us-east-1, eu-west-2, and ap-southeast-1. They need to establish private connectivity between all VPCs with centralized network management. What is the recommended architecture?**

**Answer:** Use AWS Transit Gateway with inter-region peering. Deploy a Transit Gateway in each region and establish Transit Gateway peering connections between them. This provides:
- Hub-and-spoke architecture with centralized routing
- Simplified network management compared to multiple VPC peering connections
- Support for transitive routing
- Centralized monitoring and security policies
- Scalability to thousands of VPCs

---

**Q2: A company is designing a multi-account AWS architecture with 50 VPCs that all need private connectivity. The current design uses VPC peering, but management is becoming complex. How can they simplify the architecture while maintaining security boundaries?**

**Answer:** Migrate to AWS Transit Gateway with the following approach:
- Deploy Transit Gateway in a central networking account
- Share Transit Gateway across accounts using AWS Resource Access Manager (RAM)
- Use Transit Gateway route tables to segment traffic (e.g., production, development, shared services)
- Implement Transit Gateway Network Manager for centralized visibility
- Use Transit Gateway Connect for SD-WAN integration if needed

This reduces the peering connections from n(n-1)/2 (1,225 for 50 VPCs) to just 50 attachments.

---

**Q3: An application requires extremely low latency and high throughput network communication between EC2 instances. The instances are already in the same Availability Zone. What additional networking feature should be implemented?**

**Answer:** Enable Enhanced Networking using Elastic Network Adapter (ENA) and place instances in a Cluster Placement Group. For the highest performance requirements, consider:
- **Elastic Fabric Adapter (EFA)** for HPC workloads requiring OS-bypass capabilities
- **Cluster Placement Group** to minimize network latency by placing instances physically close
- **Jumbo Frames (MTU 9001)** within the VPC for larger packet sizes
- **Enhanced Networking with ENA** for up to 100 Gbps bandwidth

---

**Q4: A company needs to connect their on-premises data center to AWS with consistent network performance and dedicated bandwidth. They also require encryption for all traffic. What architecture should be implemented?**

**Answer:** Implement AWS Direct Connect with a VPN overlay:
1. **AWS Direct Connect**: Provides dedicated, consistent bandwidth (1 Gbps or 10 Gbps) with lower latency than internet-based connections
2. **Site-to-Site VPN over Direct Connect**: Create a public virtual interface and establish IPsec VPN tunnels over Direct Connect for encryption
3. **Alternatively**: Use Direct Connect with MACsec encryption (available on dedicated connections) for Layer 2 encryption

For high availability:
- Deploy Direct Connect connections in multiple locations
- Configure VPN as backup over the internet
- Use Direct Connect Gateway for multi-region connectivity

---

**Q5: A global company needs to route traffic from their VPCs to an on-premises inspection appliance before it reaches the internet. How should this be architected?**

**Answer:** Implement a centralized egress architecture with AWS Transit Gateway:
1. Create a **Transit Gateway** with multiple route tables (spoke VPCs, inspection VPC, shared services)
2. Deploy **inspection VPC** with Network Firewall or third-party appliances
3. Configure **appliance mode** on Transit Gateway to ensure symmetric routing
4. Use **Transit Gateway route table associations and propagations** to force traffic through inspection VPC
5. Route inspected traffic to NAT Gateways or back to on-premises via Direct Connect/VPN

For on-premises inspection specifically:
- Route 0.0.0.0/0 from Transit Gateway to on-premises via Direct Connect or VPN
- Implement on-premises firewall/inspection
- Return traffic through the same path for stateful inspection

---

**Q6: A company's security team requires all VPC traffic to be logged and analyzed for compliance. The solution must be cost-effective and retain logs for 7 years. What is the recommended architecture?**

**Answer:**
1. **Enable VPC Flow Logs** on all VPCs:
   - Publish to CloudWatch Logs for real-time analysis
   - Publish to S3 for long-term retention (more cost-effective)

2. **S3 Storage Strategy for 7-year retention**:
   - Use S3 Intelligent-Tiering or lifecycle policies
   - Transition to S3 Glacier after 90 days
   - Transition to S3 Glacier Deep Archive after 1 year

3. **Analysis**:
   - Use Amazon Athena for ad-hoc queries on S3 data
   - Amazon OpenSearch for real-time dashboards and alerting
   - AWS Security Hub for centralized findings

4. **Cost Optimization**:
   - Use custom flow log formats to capture only required fields
   - Aggregate flow logs at 10-minute intervals instead of 1-minute
   - Use S3 Requester Pays for cross-account access

---

**Q7: An organization is implementing a zero-trust network architecture on AWS. What combination of services and configurations should be used?**

**Answer:** Implement defense-in-depth with these components:

1. **Network Segmentation**:
   - Use multiple VPCs with Transit Gateway for isolation
   - Implement Security Groups with least-privilege rules (stateful)
   - Use Network ACLs for subnet-level stateless filtering

2. **Traffic Inspection**:
   - AWS Network Firewall for IDS/IPS and deep packet inspection
   - Gateway Load Balancer with third-party security appliances
   - VPC Traffic Mirroring for forensic analysis

3. **Access Control**:
   - AWS PrivateLink for private service access
   - VPC Endpoints to eliminate internet exposure for AWS services
   - AWS Verified Access for application-level zero trust

4. **Identity and Encryption**:
   - IAM policies with conditions for network-based restrictions
   - TLS/SSL for all application traffic
   - VPN or Direct Connect with encryption for hybrid connectivity

5. **Monitoring and Response**:
   - VPC Flow Logs with anomaly detection
   - Amazon GuardDuty for threat detection
   - AWS Security Hub for centralized security management

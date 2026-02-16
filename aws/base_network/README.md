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

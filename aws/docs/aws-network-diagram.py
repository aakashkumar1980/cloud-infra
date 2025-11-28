#!/usr/bin/env python3
"""
AWS Network Architecture Diagram
Generated using the 'diagrams' library (https://diagrams.mingrammer.com/)

This script generates a visual representation of the multi-region AWS
infrastructure defined in the aws/ directory.

Requirements:
    pip install diagrams

Usage:
    python aws-network-diagram.py

Output:
    aws_network_architecture.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2, EC2ElasticIpAddress
from diagrams.aws.network import (
    VPC,
    PublicSubnet,
    PrivateSubnet,
    InternetGateway,
    NATGateway,
    RouteTable
)
from diagrams.aws.general import InternetAlt1 as Internet, Users
from diagrams.aws.database import RDS
from diagrams.aws.security import Shield

# Alias for cleaner code
ElasticIp = EC2ElasticIpAddress


def create_aws_diagram():
    """Generate the AWS network architecture diagram."""

    graph_attr = {
        "fontsize": "24",
        "bgcolor": "#f5f5f5",
        "pad": "0.5",
        "splines": "ortho",
    }

    node_attr = {
        "fontsize": "12",
    }

    edge_attr = {
        "fontsize": "10",
    }

    with Diagram(
        "AWS Network Architecture",
        filename="aws_network_architecture",
        show=False,
        direction="TB",
        graph_attr=graph_attr,
        node_attr=node_attr,
        edge_attr=edge_attr,
        outformat="png"
    ):
        # Internet
        internet = Internet("Internet")

        # ==================== US-EAST-1 REGION ====================
        with Cluster("AWS Region: US-EAST-1 (N. Virginia)"):

            # VPC_A - Primary VPC with full internet access
            with Cluster("VPC_A: 10.0.0.0/24\n(Primary VPC)"):

                # Internet Gateway for VPC_A
                igw_a = InternetGateway("IGW\n(igw-vpc_a)")

                with Cluster("Public Subnet\n10.0.0.0/27 (us-east-1a)"):
                    # NAT Gateway in public subnet
                    nat_a = NATGateway("NAT Gateway")
                    eip_a = ElasticIp("Elastic IP")
                    rt_public_a = RouteTable("Public RT\n0.0.0.0/0 → IGW")

                    # Public instances
                    web_server_a = EC2("Web Server\n(Public IP)")

                with Cluster("Private Subnet\n10.0.0.32/27 (us-east-1b)"):
                    rt_private_a = RouteTable("Private RT\n0.0.0.0/0 → NAT")

                    # Private instances
                    app_server_a = EC2("App Server")
                    db_server_a = RDS("Database")

            # VPC_B - Isolated VPC (no internet)
            with Cluster("VPC_B: 172.16.0.0/26\n(Isolated VPC - No Internet)"):

                with Cluster("Private Subnet\n172.16.0.0/28 (us-east-1b)"):
                    rt_private_b = RouteTable("Private RT\nLocal only")

                    # Isolated instances
                    isolated_service_1 = EC2("Isolated\nService A")
                    isolated_service_2 = EC2("Isolated\nService B")

        # ==================== EU-WEST-2 REGION ====================
        with Cluster("AWS Region: EU-WEST-2 (London)"):

            # VPC_C - EU Region VPC
            with Cluster("VPC_C: 192.168.0.0/26\n(EU VPC)"):

                # Internet Gateway for VPC_C
                igw_c = InternetGateway("IGW\n(igw-vpc_c)")

                with Cluster("Public Subnet\n192.168.0.0/28 (eu-west-2a)"):
                    # NAT Gateway in public subnet
                    nat_c = NATGateway("NAT Gateway")
                    eip_c = ElasticIp("Elastic IP")
                    rt_public_c = RouteTable("Public RT\n0.0.0.0/0 → IGW")

                    # Public instances
                    web_server_c = EC2("EU Web Server\n(Public IP)")

                with Cluster("Private Subnet\n192.168.0.16/28 (eu-west-2b)"):
                    rt_private_c = RouteTable("Private RT\n0.0.0.0/0 → NAT")

                    # Private instances
                    app_server_c = EC2("EU App Server")
                    db_server_c = RDS("EU Database")

        # ==================== CONNECTIONS ====================

        # Internet to IGWs (bidirectional)
        internet >> Edge(color="darkorange", style="bold", label="HTTPS/HTTP") >> igw_a
        internet >> Edge(color="darkorange", style="bold", label="HTTPS/HTTP") >> igw_c

        # VPC_A connections
        igw_a >> Edge(color="green", label="inbound") >> web_server_a
        igw_a >> Edge(color="green") >> rt_public_a
        eip_a - nat_a
        nat_a >> Edge(color="purple", style="dashed", label="outbound") >> app_server_a
        nat_a >> Edge(color="purple", style="dashed") >> db_server_a

        # VPC_C connections
        igw_c >> Edge(color="green", label="inbound") >> web_server_c
        igw_c >> Edge(color="green") >> rt_public_c
        eip_c - nat_c
        nat_c >> Edge(color="purple", style="dashed", label="outbound") >> app_server_c
        nat_c >> Edge(color="purple", style="dashed") >> db_server_c

        # VPC_B internal connections (isolated)
        isolated_service_1 >> Edge(color="gray", style="dotted", label="internal only") >> isolated_service_2


def create_detailed_vpc_diagram():
    """Generate a detailed VPC-focused diagram."""

    graph_attr = {
        "fontsize": "20",
        "bgcolor": "#fafafa",
        "pad": "0.5",
    }

    with Diagram(
        "AWS VPC Detail - Network Flow",
        filename="aws_vpc_detail",
        show=False,
        direction="LR",
        graph_attr=graph_attr,
        outformat="png"
    ):
        internet = Internet("Internet\n(0.0.0.0/0)")

        with Cluster("VPC_A: 10.0.0.0/24"):
            igw = InternetGateway("Internet\nGateway")

            with Cluster("Public Subnet: 10.0.0.0/27"):
                nat = NATGateway("NAT GW")
                eip = ElasticIp("EIP")
                bastion = EC2("Bastion Host")
                web = EC2("Web Server")

            with Cluster("Private Subnet: 10.0.0.32/27"):
                app = EC2("App Server")
                db = RDS("Database")

        # Flow: Internet -> IGW -> Public resources
        internet >> Edge(color="orange", style="bold") >> igw
        igw >> Edge(color="green") >> [bastion, web]

        # Flow: NAT for private subnet outbound
        eip - nat
        [app, db] >> Edge(color="purple", style="dashed", label="outbound\nonly") >> nat
        nat >> igw

        # Internal communication
        web >> Edge(color="blue", label="internal") >> app
        app >> Edge(color="blue") >> db


def create_security_diagram():
    """Generate a security-focused diagram showing firewall rules."""

    graph_attr = {
        "fontsize": "20",
        "bgcolor": "#fff8e1",
        "pad": "0.5",
    }

    with Diagram(
        "AWS Security Groups & Firewall Rules",
        filename="aws_security_rules",
        show=False,
        direction="TB",
        graph_attr=graph_attr,
        outformat="png"
    ):
        internet = Internet("Internet")

        with Cluster("Security Boundary"):
            shield = Shield("Firewall Rules")

            with Cluster("Ingress Rules"):
                with Cluster("Allowed Inbound"):
                    rule_ssh = EC2("SSH:22\n(0.0.0.0/0)")
                    rule_http = EC2("HTTP:80\n(0.0.0.0/0)")
                    rule_https = EC2("HTTPS:443\n(0.0.0.0/0)")
                    rule_icmp = EC2("ICMP:-1\n(Ping)")

            with Cluster("VPC Resources"):
                web = EC2("Web Server")
                app = EC2("App Server")
                db = RDS("Database")

        internet >> Edge(color="red", label="ingress") >> shield
        shield >> [rule_ssh, rule_http, rule_https, rule_icmp]
        [rule_http, rule_https] >> web
        rule_ssh >> [web, app]

        web >> Edge(color="blue", label="internal") >> app >> db

        [web, app, db] >> Edge(color="green", style="dashed", label="egress\n0.0.0.0/0") >> internet


if __name__ == "__main__":
    print("Generating AWS Network Architecture diagrams...")
    print("-" * 50)

    print("1. Creating main architecture diagram...")
    create_aws_diagram()
    print("   ✓ Created: aws_network_architecture.png")

    print("2. Creating VPC detail diagram...")
    create_detailed_vpc_diagram()
    print("   ✓ Created: aws_vpc_detail.png")

    print("3. Creating security rules diagram...")
    create_security_diagram()
    print("   ✓ Created: aws_security_rules.png")

    print("-" * 50)
    print("All diagrams generated successfully!")
    print("\nTo view the diagrams, open the PNG files in the current directory.")

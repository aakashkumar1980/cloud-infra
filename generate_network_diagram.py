#!/usr/bin/env python3
"""
Generate 3D AWS Network Diagram
Creates a visual representation of the multi-region AWS infrastructure
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import numpy as np

# Set up the figure with high DPI for better quality
fig = plt.figure(figsize=(24, 18), dpi=150)
ax = fig.add_subplot(111, projection='3d')

# Color scheme
colors = {
    'internet': '#FF6B6B',
    'igw': '#4ECDC4',
    'vpc': '#45B7D1',
    'public_subnet': '#96CEB4',
    'private_subnet': '#FFEAA7',
    'route_table': '#DDA15E',
    'az': '#E8E8E8'
}

def draw_cube(ax, x, y, z, dx, dy, dz, color, alpha=0.3, label=''):
    """Draw a 3D cube/box"""
    # Define vertices
    vertices = [
        [x, y, z], [x+dx, y, z], [x+dx, y+dy, z], [x, y+dy, z],  # bottom
        [x, y, z+dz], [x+dx, y, z+dz], [x+dx, y+dy, z+dz], [x, y+dy, z+dz]  # top
    ]

    # Define the 6 faces
    faces = [
        [vertices[0], vertices[1], vertices[5], vertices[4]],  # front
        [vertices[2], vertices[3], vertices[7], vertices[6]],  # back
        [vertices[0], vertices[3], vertices[7], vertices[4]],  # left
        [vertices[1], vertices[2], vertices[6], vertices[5]],  # right
        [vertices[0], vertices[1], vertices[2], vertices[3]],  # bottom
        [vertices[4], vertices[5], vertices[6], vertices[7]]   # top
    ]

    # Create the 3D polygon collection
    poly = Poly3DCollection(faces, alpha=alpha, facecolor=color, edgecolor='black', linewidth=1.5)
    ax.add_collection3d(poly)

    # Add label at center
    if label:
        center_x, center_y, center_z = x + dx/2, y + dy/2, z + dz/2
        ax.text(center_x, center_y, center_z, label, fontsize=8, ha='center', va='center',
                weight='bold', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

def draw_cylinder(ax, x, y, z, radius, height, color, alpha=0.6, label=''):
    """Draw a cylinder (for IGW)"""
    theta = np.linspace(0, 2*np.pi, 30)
    x_circle = x + radius * np.cos(theta)
    y_circle = y + radius * np.sin(theta)

    # Bottom circle
    z_circle = np.full_like(x_circle, z)
    ax.plot(x_circle, y_circle, z_circle, color='black', linewidth=2)

    # Top circle
    z_circle_top = np.full_like(x_circle, z + height)
    ax.plot(x_circle, y_circle, z_circle_top, color='black', linewidth=2)

    # Side surface
    for i in range(len(theta)-1):
        vertices = [
            [x_circle[i], y_circle[i], z],
            [x_circle[i+1], y_circle[i+1], z],
            [x_circle[i+1], y_circle[i+1], z+height],
            [x_circle[i], y_circle[i], z+height]
        ]
        poly = Poly3DCollection([vertices], alpha=alpha, facecolor=color, edgecolor='black', linewidth=0.5)
        ax.add_collection3d(poly)

    if label:
        ax.text(x, y, z + height/2, label, fontsize=9, ha='center', va='center',
                weight='bold', bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

def draw_connection(ax, x1, y1, z1, x2, y2, z2, color='blue', style='-', linewidth=2):
    """Draw a line connection between two points"""
    ax.plot([x1, x2], [y1, y2], [z1, z2], color=color, linestyle=style, linewidth=linewidth)

# ============================================================================
# LAYER 0: Internet (Top)
# ============================================================================
internet_z = 35
draw_cube(ax, 15, 15, internet_z, 20, 20, 3, colors['internet'], alpha=0.5, label='INTERNET\n0.0.0.0/0')

# ============================================================================
# LAYER 1: Internet Gateways
# ============================================================================
igw_z = 28

# IGW for vpc_a (US-EAST-1)
igw_a_x, igw_a_y = 5, 25
draw_cylinder(ax, igw_a_x, igw_a_y, igw_z, 2.5, 3, colors['igw'], label='IGW\nvpc_a')
draw_connection(ax, 25, 25, internet_z, igw_a_x, igw_a_y, igw_z+3, color='red', linewidth=3)

# IGW for vpc_b (US-EAST-1)
igw_b_x, igw_b_y = 25, 25
draw_cylinder(ax, igw_b_x, igw_b_y, igw_z, 2.5, 3, colors['igw'], label='IGW\nvpc_b')
draw_connection(ax, 25, 25, internet_z, igw_b_x, igw_b_y, igw_z+3, color='red', linewidth=3)

# IGW for vpc_c (EU-WEST-2)
igw_c_x, igw_c_y = 45, 25
draw_cylinder(ax, igw_c_x, igw_c_y, igw_z, 2.5, 3, colors['igw'], label='IGW\nvpc_c')
draw_connection(ax, 25, 25, internet_z, igw_c_x, igw_c_y, igw_z+3, color='red', linewidth=3)

# ============================================================================
# LAYER 2: VPCs
# ============================================================================
vpc_z = 18

# VPC_A (US-EAST-1) - 10.0.0.0/24
vpc_a_x, vpc_a_y = 0, 20
draw_cube(ax, vpc_a_x, vpc_a_y, vpc_z, 18, 18, 4, colors['vpc'], alpha=0.2,
          label='VPC_A\n10.0.0.0/24\nus-east-1')
draw_connection(ax, igw_a_x, igw_a_y, igw_z, vpc_a_x+9, vpc_a_y+9, vpc_z+4, color='darkblue', linewidth=2.5)

# VPC_B (US-EAST-1) - 172.16.0.0/26
vpc_b_x, vpc_b_y = 20, 20
draw_cube(ax, vpc_b_x, vpc_b_y, vpc_z, 12, 12, 4, colors['vpc'], alpha=0.2,
          label='VPC_B\n172.16.0.0/26\nus-east-1')
draw_connection(ax, igw_b_x, igw_b_y, igw_z, vpc_b_x+6, vpc_b_y+6, vpc_z+4, color='darkblue', linewidth=2.5)

# VPC_C (EU-WEST-2) - 192.168.0.0/26
vpc_c_x, vpc_c_y = 38, 20
draw_cube(ax, vpc_c_x, vpc_c_y, vpc_z, 12, 12, 4, colors['vpc'], alpha=0.2,
          label='VPC_C\n192.168.0.0/26\neu-west-2')
draw_connection(ax, igw_c_x, igw_c_y, igw_z, vpc_c_x+6, vpc_c_y+6, vpc_z+4, color='darkblue', linewidth=2.5)

# ============================================================================
# LAYER 3: Availability Zones and Subnets
# ============================================================================
subnet_z = 8

# -------------------- VPC_A Subnets --------------------
# AZ us-east-1a
az_a_x, az_a_y = 1, 21
draw_cube(ax, az_a_x, az_a_y, subnet_z+5, 5, 8, 3, colors['az'], alpha=0.1)
ax.text(az_a_x+2.5, az_a_y+4, subnet_z+8, 'AZ\nus-east-1a', fontsize=7, ha='center', style='italic')

# Public subnet 1 (10.0.0.0/27)
draw_cube(ax, az_a_x+0.5, az_a_y+0.5, subnet_z, 4, 3.5, 4, colors['public_subnet'], alpha=0.6,
          label='PUBLIC\n10.0.0.0/27\nID:1')

# Private subnet 3 (10.0.0.64/27)
draw_cube(ax, az_a_x+0.5, az_a_y+4.5, subnet_z, 4, 3, 4, colors['private_subnet'], alpha=0.6,
          label='PRIVATE\n10.0.0.64/27\nID:3')

# Route Table for subnet 1
rt_a1_x, rt_a1_y = az_a_x+2.5, az_a_y+2
draw_cube(ax, rt_a1_x-0.8, rt_a1_y-0.3, subnet_z-2, 1.6, 0.6, 1.5, colors['route_table'], alpha=0.8,
          label='RTB\nvpc_a/1')
draw_connection(ax, rt_a1_x, rt_a1_y, subnet_z-2+1.5, rt_a1_x, rt_a1_y, subnet_z, color='orange', linewidth=2)
draw_connection(ax, rt_a1_x, rt_a1_y, subnet_z-2, igw_a_x, igw_a_y, igw_z, color='green', linewidth=1.5, style='--')

# AZ us-east-1b
az_b_x, az_b_y = 7, 21
draw_cube(ax, az_b_x, az_b_y, subnet_z+5, 5, 8, 3, colors['az'], alpha=0.1)
ax.text(az_b_x+2.5, az_b_y+4, subnet_z+8, 'AZ\nus-east-1b', fontsize=7, ha='center', style='italic')

# Public subnet 2 (10.0.0.32/27)
draw_cube(ax, az_b_x+0.5, az_b_y+0.5, subnet_z, 4, 3.5, 4, colors['public_subnet'], alpha=0.6,
          label='PUBLIC\n10.0.0.32/27\nID:2')

# Private subnet 4 (10.0.0.96/27)
draw_cube(ax, az_b_x+0.5, az_b_y+4.5, subnet_z, 4, 3, 4, colors['private_subnet'], alpha=0.6,
          label='PRIVATE\n10.0.0.96/27\nID:4')

# Route Table for subnet 2
rt_a2_x, rt_a2_y = az_b_x+2.5, az_b_y+2
draw_cube(ax, rt_a2_x-0.8, rt_a2_y-0.3, subnet_z-2, 1.6, 0.6, 1.5, colors['route_table'], alpha=0.8,
          label='RTB\nvpc_a/2')
draw_connection(ax, rt_a2_x, rt_a2_y, subnet_z-2+1.5, rt_a2_x, rt_a2_y, subnet_z, color='orange', linewidth=2)
draw_connection(ax, rt_a2_x, rt_a2_y, subnet_z-2, igw_a_x, igw_a_y, igw_z, color='green', linewidth=1.5, style='--')

# AZ us-east-1c
az_c_x, az_c_y = 13, 21
draw_cube(ax, az_c_x, az_c_y, subnet_z+5, 4, 8, 3, colors['az'], alpha=0.1)
ax.text(az_c_x+2, az_c_y+4, subnet_z+8, 'AZ\nus-east-1c', fontsize=7, ha='center', style='italic')

# Private subnet 5 (10.0.0.128/27)
draw_cube(ax, az_c_x+0.5, az_c_y+2, subnet_z, 3, 4, 4, colors['private_subnet'], alpha=0.6,
          label='PRIVATE\n10.0.0.128/27\nID:5')

# -------------------- VPC_B Subnets --------------------
# AZ us-east-1a
az_b1_x, az_b1_y = 21, 21
draw_cube(ax, az_b1_x, az_b1_y, subnet_z+5, 5, 5, 3, colors['az'], alpha=0.1)
ax.text(az_b1_x+2.5, az_b1_y+2.5, subnet_z+8, 'AZ\nus-east-1a', fontsize=7, ha='center', style='italic')

# Public subnet 1 (172.16.0.0/28)
draw_cube(ax, az_b1_x+0.5, az_b1_y+0.5, subnet_z, 4, 4, 4, colors['public_subnet'], alpha=0.6,
          label='PUBLIC\n172.16.0.0/28\nID:1')

# Route Table for vpc_b/1
rt_b1_x, rt_b1_y = az_b1_x+2.5, az_b1_y+2.5
draw_cube(ax, rt_b1_x-0.8, rt_b1_y-0.3, subnet_z-2, 1.6, 0.6, 1.5, colors['route_table'], alpha=0.8,
          label='RTB\nvpc_b/1')
draw_connection(ax, rt_b1_x, rt_b1_y, subnet_z-2+1.5, rt_b1_x, rt_b1_y, subnet_z, color='orange', linewidth=2)
draw_connection(ax, rt_b1_x, rt_b1_y, subnet_z-2, igw_b_x, igw_b_y, igw_z, color='green', linewidth=1.5, style='--')

# AZ us-east-1b
az_b2_x, az_b2_y = 27, 21
draw_cube(ax, az_b2_x, az_b2_y, subnet_z+5, 4, 5, 3, colors['az'], alpha=0.1)
ax.text(az_b2_x+2, az_b2_y+2.5, subnet_z+8, 'AZ\nus-east-1b', fontsize=7, ha='center', style='italic')

# Private subnet 2 (172.16.0.16/28)
draw_cube(ax, az_b2_x+0.5, az_b2_y+0.5, subnet_z, 3, 4, 4, colors['private_subnet'], alpha=0.6,
          label='PRIVATE\n172.16.0.16/28\nID:2')

# -------------------- VPC_C Subnets --------------------
# AZ eu-west-2a
az_c1_x, az_c1_y = 39, 21
draw_cube(ax, az_c1_x, az_c1_y, subnet_z+5, 5, 5, 3, colors['az'], alpha=0.1)
ax.text(az_c1_x+2.5, az_c1_y+2.5, subnet_z+8, 'AZ\neu-west-2a', fontsize=7, ha='center', style='italic')

# Public subnet 1 (192.168.0.0/28)
draw_cube(ax, az_c1_x+0.5, az_c1_y+0.5, subnet_z, 4, 4, 4, colors['public_subnet'], alpha=0.6,
          label='PUBLIC\n192.168.0.0/28\nID:1')

# Route Table for vpc_c/1
rt_c1_x, rt_c1_y = az_c1_x+2.5, az_c1_y+2.5
draw_cube(ax, rt_c1_x-0.8, rt_c1_y-0.3, subnet_z-2, 1.6, 0.6, 1.5, colors['route_table'], alpha=0.8,
          label='RTB\nvpc_c/1')
draw_connection(ax, rt_c1_x, rt_c1_y, subnet_z-2+1.5, rt_c1_x, rt_c1_y, subnet_z, color='orange', linewidth=2)
draw_connection(ax, rt_c1_x, rt_c1_y, subnet_z-2, igw_c_x, igw_c_y, igw_z, color='green', linewidth=1.5, style='--')

# AZ eu-west-2b
az_c2_x, az_c2_y = 45, 21
draw_cube(ax, az_c2_x, az_c2_y, subnet_z+5, 4, 5, 3, colors['az'], alpha=0.1)
ax.text(az_c2_x+2, az_c2_y+2.5, subnet_z+8, 'AZ\neu-west-2b', fontsize=7, ha='center', style='italic')

# Private subnet 2 (192.168.0.16/28)
draw_cube(ax, az_c2_x+0.5, az_c2_y+0.5, subnet_z, 3, 4, 4, colors['private_subnet'], alpha=0.6,
          label='PRIVATE\n192.168.0.16/28\nID:2')

# ============================================================================
# Add region labels
# ============================================================================
ax.text(9, 15, 24, 'REGION: US-EAST-1\n(N. Virginia)', fontsize=14, ha='center', weight='bold',
        bbox=dict(boxstyle='round,pad=0.8', facecolor='lightblue', alpha=0.7, edgecolor='navy', linewidth=2))

ax.text(44, 15, 24, 'REGION: EU-WEST-2\n(London)', fontsize=14, ha='center', weight='bold',
        bbox=dict(boxstyle='round,pad=0.8', facecolor='lightcoral', alpha=0.7, edgecolor='darkred', linewidth=2))

# ============================================================================
# Add legend
# ============================================================================
legend_elements = [
    mpatches.Patch(facecolor=colors['internet'], alpha=0.5, edgecolor='black', label='Internet'),
    mpatches.Patch(facecolor=colors['igw'], alpha=0.6, edgecolor='black', label='Internet Gateway'),
    mpatches.Patch(facecolor=colors['vpc'], alpha=0.2, edgecolor='black', label='VPC'),
    mpatches.Patch(facecolor=colors['public_subnet'], alpha=0.6, edgecolor='black', label='Public Subnet (w/ IGW route)'),
    mpatches.Patch(facecolor=colors['private_subnet'], alpha=0.6, edgecolor='black', label='Private Subnet (no IGW)'),
    mpatches.Patch(facecolor=colors['route_table'], alpha=0.8, edgecolor='black', label='Route Table'),
    mpatches.Patch(facecolor='none', edgecolor='green', linestyle='--', label='Route: 0.0.0.0/0 → IGW'),
    mpatches.Patch(facecolor='none', edgecolor='orange', label='Route Table Association'),
]

ax.legend(handles=legend_elements, loc='upper left', fontsize=10, framealpha=0.9,
          bbox_to_anchor=(0.02, 0.98))

# ============================================================================
# Set labels and title
# ============================================================================
ax.set_xlabel('X', fontsize=10)
ax.set_ylabel('Y', fontsize=10)
ax.set_zlabel('Network Layers', fontsize=10)

title_text = 'AWS Multi-Region Network Architecture (3D View)\nDev Environment - Terraform Managed'
ax.text2D(0.5, 0.98, title_text, transform=ax.transAxes, fontsize=18,
          weight='bold', ha='center', va='top',
          bbox=dict(boxstyle='round,pad=1', facecolor='lightgray', alpha=0.8, edgecolor='black', linewidth=2))

# Add route table details
details_text = """ROUTE TABLES (4 total):
• rtb-vpc_a/1: 10.0.0.0/24→local, 0.0.0.0/0→IGW
• rtb-vpc_a/2: 10.0.0.0/24→local, 0.0.0.0/0→IGW
• rtb-vpc_b/1: 172.16.0.0/26→local, 0.0.0.0/0→IGW
• rtb-vpc_c/1: 192.168.0.0/26→local, 0.0.0.0/0→IGW

SUMMARY:
• 2 Regions | 3 VPCs | 3 IGWs
• 8 Subnets (3 Public, 5 Private)
• 4 Route Tables | 6 Availability Zones"""

ax.text2D(0.72, 0.35, details_text, transform=ax.transAxes, fontsize=9,
          family='monospace', va='top', ha='left',
          bbox=dict(boxstyle='round,pad=0.8', facecolor='lightyellow', alpha=0.9,
                   edgecolor='black', linewidth=1.5))

# Set viewing angle for best 3D perspective
ax.view_init(elev=25, azim=45)

# Set axis limits
ax.set_xlim(0, 52)
ax.set_ylim(12, 42)
ax.set_zlim(0, 40)

# Remove grid for cleaner look
ax.grid(True, alpha=0.3)
ax.set_facecolor('#f0f0f0')

# Tight layout
plt.tight_layout()

# Save as high-quality JPEG
output_file = '/home/user/cloud-infra/aws_network_diagram_3d.jpg'
plt.savefig(output_file, format='jpg', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')

print(f"✓ 3D Network diagram saved to: {output_file}")
print(f"✓ Resolution: 7200x5400 pixels (300 DPI)")
print(f"✓ Format: JPEG")
print("✓ Diagram includes:")
print("  - Internet layer")
print("  - 3 Internet Gateways")
print("  - 3 VPCs across 2 regions")
print("  - 8 Subnets in 6 Availability Zones")
print("  - 4 Route Tables with routing details")
print("  - All network connections and associations")

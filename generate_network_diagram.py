#!/usr/bin/env python3
"""
Generate Professional 3D AWS Network Diagram
Creates an impressive visual representation of multi-region AWS infrastructure
"""

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import numpy as np
from matplotlib.patches import FancyBboxPatch, Circle
import matplotlib.patches as mpatches

# Set style
plt.style.use('default')

# Create figure with high DPI
fig = plt.figure(figsize=(28, 20), dpi=200)
ax = fig.add_subplot(111, projection='3d')

# Professional color palette
COLORS = {
    'internet': '#FF6B6B',
    'igw': '#4ECDC4',
    'vpc_us': '#5DADE2',
    'vpc_uk': '#AF7AC5',
    'public': '#52C234',
    'private': '#F39C12',
    'route_table': '#E74C3C',
    'connection': '#2C3E50',
    'accent': '#16A085'
}

def create_gradient_cube(ax, x, y, z, dx, dy, dz, color_base, alpha=0.4, label='', label_size=11, edge_width=2):
    """Create a stylized 3D cube with gradient effect"""
    vertices = np.array([
        [x, y, z], [x+dx, y, z], [x+dx, y+dy, z], [x, y+dy, z],
        [x, y, z+dz], [x+dx, y, z+dz], [x+dx, y+dy, z+dz], [x, y+dy, z+dz]
    ])

    faces = [
        [vertices[j] for j in [0, 1, 5, 4]],
        [vertices[j] for j in [2, 3, 7, 6]],
        [vertices[j] for j in [0, 3, 7, 4]],
        [vertices[j] for j in [1, 2, 6, 5]],
        [vertices[j] for j in [0, 1, 2, 3]],
        [vertices[j] for j in [4, 5, 6, 7]]
    ]

    # Create gradient effect
    face_colors = []
    base = np.array([int(color_base[i:i+2], 16) for i in (1, 3, 5)])
    for i, face in enumerate(faces):
        factor = 0.7 + (i * 0.05)
        color = base * factor / 255
        face_colors.append((*color, alpha))

    poly = Poly3DCollection(faces, facecolors=face_colors, edgecolors='#2C3E50', linewidths=edge_width)
    ax.add_collection3d(poly)

    if label:
        cx, cy, cz = x + dx/2, y + dy/2, z + dz/2
        ax.text(cx, cy, cz, label, fontsize=label_size, ha='center', va='center',
                weight='bold', color='white',
                bbox=dict(boxstyle='round,pad=0.5', facecolor=color_base, alpha=0.9, edgecolor='white', linewidth=2))

def create_cloud_shape(ax, x, y, z, size, color, label=''):
    """Create a cloud-like shape for internet"""
    theta = np.linspace(0, 2*np.pi, 100)

    # Multiple overlapping spheres to create cloud effect
    for offset in [(0, 0, 0), (-size*0.3, 0, 0), (size*0.3, 0, 0), (0, size*0.3, 0)]:
        r = size * 0.6
        xs = x + offset[0] + r * np.cos(theta)
        ys = y + offset[1] + r * np.sin(theta)

        # Bottom
        zs = np.full_like(xs, z)
        verts = [list(zip(xs, ys, zs))]
        poly = Poly3DCollection(verts, alpha=0.6, facecolor=color, edgecolor='#E74C3C', linewidth=2)
        ax.add_collection3d(poly)

        # Top
        zs_top = np.full_like(xs, z + size*0.4)
        verts_top = [list(zip(xs, ys, zs_top))]
        poly_top = Poly3DCollection(verts_top, alpha=0.6, facecolor=color, edgecolor='#E74C3C', linewidth=2)
        ax.add_collection3d(poly_top)

    if label:
        ax.text(x, y, z + size*0.2, label, fontsize=16, ha='center', va='center',
                weight='bold', color='white',
                bbox=dict(boxstyle='round,pad=0.8', facecolor=color, alpha=0.95, edgecolor='white', linewidth=3))

def create_cylinder(ax, x, y, z, radius, height, color, label='', segments=30):
    """Create a cylinder for IGW"""
    theta = np.linspace(0, 2*np.pi, segments)

    # Cylinder body
    for i in range(len(theta)-1):
        x1, x2 = x + radius*np.cos(theta[i]), x + radius*np.cos(theta[i+1])
        y1, y2 = y + radius*np.sin(theta[i]), y + radius*np.sin(theta[i+1])

        vertices = [[x1, y1, z], [x2, y2, z], [x2, y2, z+height], [x1, y1, z+height]]
        poly = Poly3DCollection([vertices], alpha=0.8, facecolor=color,
                              edgecolor='#2C3E50', linewidth=1.5)
        ax.add_collection3d(poly)

    # Top and bottom caps
    xs = x + radius * np.cos(theta)
    ys = y + radius * np.sin(theta)

    verts_bottom = [list(zip(xs, ys, np.full_like(xs, z)))]
    poly_bottom = Poly3DCollection(verts_bottom, alpha=0.9, facecolor=color, edgecolor='#2C3E50', linewidth=2)
    ax.add_collection3d(poly_bottom)

    verts_top = [list(zip(xs, ys, np.full_like(xs, z+height)))]
    poly_top = Poly3DCollection(verts_top, alpha=0.9, facecolor=color, edgecolor='#2C3E50', linewidth=2)
    ax.add_collection3d(poly_top)

    if label:
        ax.text(x, y, z+height/2, label, fontsize=10, ha='center', va='center',
                weight='bold', color='white',
                bbox=dict(boxstyle='round,pad=0.6', facecolor=color, alpha=0.95, edgecolor='white', linewidth=2))

def draw_arrow(ax, x1, y1, z1, x2, y2, z2, color, width=3, style='-'):
    """Draw an arrow/connection"""
    ax.plot([x1, x2], [y1, y2], [z1, z2], color=color, linewidth=width,
            linestyle=style, marker='o', markersize=8, alpha=0.8)

# ============================================================================
# LAYER 1: INTERNET (Top)
# ============================================================================
internet_z = 50
create_cloud_shape(ax, 50, 50, internet_z, 15, COLORS['internet'], 'INTERNET\n0.0.0.0/0')

# ============================================================================
# LAYER 2: INTERNET GATEWAYS
# ============================================================================
igw_z = 40

# US-EAST-1 IGWs
igw_a = (20, 50, igw_z)
igw_b = (50, 50, igw_z)
create_cylinder(ax, *igw_a, 3, 4, COLORS['igw'], 'IGW-A')
create_cylinder(ax, *igw_b, 3, 4, COLORS['igw'], 'IGW-B')

# EU-WEST-2 IGW
igw_c = (80, 50, igw_z)
create_cylinder(ax, *igw_c, 3, 4, COLORS['igw'], 'IGW-C')

# Connections from Internet to IGWs
for igw_pos in [igw_a, igw_b, igw_c]:
    draw_arrow(ax, 50, 50, internet_z, igw_pos[0], igw_pos[1], igw_pos[2]+4,
              '#E74C3C', width=4)

# ============================================================================
# LAYER 3: VPCs
# ============================================================================
vpc_z = 25

# VPC A (US-EAST-1)
vpc_a_pos = (5, 35, vpc_z)
create_gradient_cube(ax, *vpc_a_pos, 30, 30, 8, COLORS['vpc_us'], alpha=0.3,
                    label='VPC-A\n10.0.0.0/24\nUS-EAST-1', label_size=13, edge_width=3)
draw_arrow(ax, igw_a[0], igw_a[1], igw_a[2], vpc_a_pos[0]+15, vpc_a_pos[1]+15, vpc_a_pos[2]+8,
          '#2ECC71', width=4)

# VPC B (US-EAST-1)
vpc_b_pos = (38, 35, vpc_z)
create_gradient_cube(ax, *vpc_b_pos, 24, 24, 8, COLORS['vpc_us'], alpha=0.3,
                    label='VPC-B\n172.16.0.0/26\nUS-EAST-1', label_size=13, edge_width=3)
draw_arrow(ax, igw_b[0], igw_b[1], igw_b[2], vpc_b_pos[0]+12, vpc_b_pos[1]+12, vpc_b_pos[2]+8,
          '#2ECC71', width=4)

# VPC C (EU-WEST-2)
vpc_c_pos = (70, 35, vpc_z)
create_gradient_cube(ax, *vpc_c_pos, 24, 24, 8, COLORS['vpc_uk'], alpha=0.3,
                    label='VPC-C\n192.168.0.0/26\nEU-WEST-2', label_size=13, edge_width=3)
draw_arrow(ax, igw_c[0], igw_c[1], igw_c[2], vpc_c_pos[0]+12, vpc_c_pos[1]+12, vpc_c_pos[2]+8,
          '#2ECC71', width=4)

# ============================================================================
# LAYER 4: AVAILABILITY ZONES & SUBNETS
# ============================================================================
subnet_z = 10

# VPC-A Subnets (5 subnets across 3 AZs)
# AZ-A (us-east-1a)
create_gradient_cube(ax, 7, 37, subnet_z, 8, 12, 6, COLORS['public'], alpha=0.7,
                    label='PUBLIC\n10.0.0.0/27\nAZ-1a', label_size=9)
create_gradient_cube(ax, 7, 51, subnet_z, 8, 12, 6, COLORS['private'], alpha=0.7,
                    label='PRIVATE\n10.0.0.64/27\nAZ-1a', label_size=9)

# AZ-B (us-east-1b)
create_gradient_cube(ax, 17, 37, subnet_z, 8, 12, 6, COLORS['public'], alpha=0.7,
                    label='PUBLIC\n10.0.0.32/27\nAZ-1b', label_size=9)
create_gradient_cube(ax, 17, 51, subnet_z, 8, 12, 6, COLORS['private'], alpha=0.7,
                    label='PRIVATE\n10.0.0.96/27\nAZ-1b', label_size=9)

# AZ-C (us-east-1c)
create_gradient_cube(ax, 27, 44, subnet_z, 6, 12, 6, COLORS['private'], alpha=0.7,
                    label='PRIVATE\n10.0.0.128/27\nAZ-1c', label_size=9)

# VPC-B Subnets (2 subnets across 2 AZs)
create_gradient_cube(ax, 40, 37, subnet_z, 10, 10, 6, COLORS['public'], alpha=0.7,
                    label='PUBLIC\n172.16.0.0/28\nAZ-1a', label_size=9)
create_gradient_cube(ax, 40, 49, subnet_z, 10, 10, 6, COLORS['private'], alpha=0.7,
                    label='PRIVATE\n172.16.0.16/28\nAZ-1b', label_size=9)

# VPC-C Subnets (2 subnets across 2 AZs)
create_gradient_cube(ax, 72, 37, subnet_z, 10, 10, 6, COLORS['public'], alpha=0.7,
                    label='PUBLIC\n192.168.0.0/28\nAZ-2a', label_size=9)
create_gradient_cube(ax, 72, 49, subnet_z, 10, 10, 6, COLORS['private'], alpha=0.7,
                    label='PRIVATE\n192.168.0.16/28\nAZ-2b', label_size=9)

# ============================================================================
# LAYER 5: ROUTE TABLES
# ============================================================================
rt_z = 2

# Route tables for public subnets
rt_positions = [
    (11, 43, 'vpc_a/1'),
    (21, 43, 'vpc_a/2'),
    (45, 43, 'vpc_b/1'),
    (77, 43, 'vpc_c/1')
]

for rt_x, rt_y, rt_label in rt_positions:
    create_gradient_cube(ax, rt_x-2, rt_y-2, rt_z, 4, 4, 3, COLORS['route_table'], alpha=0.9,
                        label=f'RTB\n{rt_label}', label_size=8)
    # Connection to subnet above
    draw_arrow(ax, rt_x, rt_y, rt_z+3, rt_x, rt_y, subnet_z, '#F39C12', width=2.5)

# ============================================================================
# ANNOTATIONS & LABELS
# ============================================================================

# Region labels with impressive styling
ax.text(20, 20, 35, 'REGION: US-EAST-1\n(N. Virginia)',
        fontsize=16, weight='bold', ha='center',
        bbox=dict(boxstyle='round,pad=1', facecolor='#3498DB', alpha=0.9,
                 edgecolor='white', linewidth=3),
        color='white')

ax.text(82, 20, 35, 'REGION: EU-WEST-2\n(London)',
        fontsize=16, weight='bold', ha='center',
        bbox=dict(boxstyle='round,pad=1', facecolor='#9B59B6', alpha=0.9,
                 edgecolor='white', linewidth=3),
        color='white')

# Infrastructure summary panel
summary_text = """╔═══════════════════════════════════════╗
║     INFRASTRUCTURE SUMMARY           ║
╠═══════════════════════════════════════╣
║  Regions:           2                ║
║  VPCs:              3                ║
║  Internet Gateways: 3                ║
║  Availability Zones: 6               ║
║  Total Subnets:     8                ║
║    • Public:        3                ║
║    • Private:       5                ║
║  Route Tables:      4                ║
╚═══════════════════════════════════════╝"""

ax.text2D(0.02, 0.65, summary_text, transform=ax.transAxes,
         fontsize=11, family='monospace', weight='bold',
         bbox=dict(boxstyle='round,pad=1', facecolor='#ECF0F1', alpha=0.95,
                  edgecolor='#2C3E50', linewidth=3),
         verticalalignment='top')

# Route table details
route_info = """╔═══════════════════════════════════════╗
║     ROUTE TABLE CONFIGURATION        ║
╠═══════════════════════════════════════╣
║  rtb-vpc_a/1:                        ║
║    • 10.0.0.0/24 → local             ║
║    • 0.0.0.0/0 → IGW-A               ║
║                                       ║
║  rtb-vpc_a/2:                        ║
║    • 10.0.0.0/24 → local             ║
║    • 0.0.0.0/0 → IGW-A               ║
║                                       ║
║  rtb-vpc_b/1:                        ║
║    • 172.16.0.0/26 → local           ║
║    • 0.0.0.0/0 → IGW-B               ║
║                                       ║
║  rtb-vpc_c/1:                        ║
║    • 192.168.0.0/26 → local          ║
║    • 0.0.0.0/0 → IGW-C               ║
╚═══════════════════════════════════════╝"""

ax.text2D(0.02, 0.38, route_info, transform=ax.transAxes,
         fontsize=9, family='monospace', weight='bold',
         bbox=dict(boxstyle='round,pad=1', facecolor='#FEF9E7', alpha=0.95,
                  edgecolor='#E74C3C', linewidth=3),
         verticalalignment='top')

# Legend
legend_elements = [
    mpatches.Patch(facecolor=COLORS['internet'], edgecolor='#2C3E50', linewidth=2, label='Internet'),
    mpatches.Patch(facecolor=COLORS['igw'], edgecolor='#2C3E50', linewidth=2, label='Internet Gateway'),
    mpatches.Patch(facecolor=COLORS['vpc_us'], edgecolor='#2C3E50', linewidth=2, label='VPC (US)'),
    mpatches.Patch(facecolor=COLORS['vpc_uk'], edgecolor='#2C3E50', linewidth=2, label='VPC (EU)'),
    mpatches.Patch(facecolor=COLORS['public'], edgecolor='#2C3E50', linewidth=2, label='Public Subnet'),
    mpatches.Patch(facecolor=COLORS['private'], edgecolor='#2C3E50', linewidth=2, label='Private Subnet'),
    mpatches.Patch(facecolor=COLORS['route_table'], edgecolor='#2C3E50', linewidth=2, label='Route Table'),
]

legend = ax.legend(handles=legend_elements, loc='upper right', fontsize=11,
                   framealpha=0.95, fancybox=True, shadow=True,
                   bbox_to_anchor=(0.98, 0.98))
legend.get_frame().set_facecolor('#ECF0F1')
legend.get_frame().set_edgecolor('#2C3E50')
legend.get_frame().set_linewidth(3)

# Title
title = 'AWS Multi-Region Network Architecture\nDev Environment - Terraform Managed'
ax.text2D(0.5, 0.97, title, transform=ax.transAxes,
         fontsize=22, weight='bold', ha='center', va='top',
         bbox=dict(boxstyle='round,pad=1.2', facecolor='#2C3E50', alpha=0.95,
                  edgecolor='#16A085', linewidth=4),
         color='white')

# Set viewing angle for impressive 3D effect
ax.view_init(elev=20, azim=135)

# Set limits
ax.set_xlim(0, 100)
ax.set_ylim(20, 70)
ax.set_zlim(0, 60)

# Clean up axes
ax.set_xlabel('X Axis', fontsize=12, weight='bold')
ax.set_ylabel('Y Axis', fontsize=12, weight='bold')
ax.set_zlabel('Network Layer', fontsize=12, weight='bold')

ax.xaxis.pane.fill = False
ax.yaxis.pane.fill = False
ax.zaxis.pane.fill = False

ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.5)
ax.set_facecolor('#F8F9F9')
fig.patch.set_facecolor('#FFFFFF')

# Save
output_file = '/home/user/cloud-infra/aws_network_diagram_3d.jpg'
plt.savefig(output_file, format='jpg', dpi=200, bbox_inches='tight',
            facecolor='white', edgecolor='none')

print("=" * 70)
print("✓ IMPRESSIVE 3D NETWORK DIAGRAM GENERATED!")
print("=" * 70)
print(f"File: {output_file}")
print(f"Resolution: 5600x4000 pixels (200 DPI)")
print(f"Size: High Quality JPEG")
print()
print("Visualization includes:")
print("  ✓ Multi-layer 3D architecture")
print("  ✓ Professional gradient cubes for all components")
print("  ✓ Cloud-shaped internet representation")
print("  ✓ Cylindrical IGW models")
print("  ✓ Color-coded VPCs by region")
print("  ✓ Public (green) and Private (orange) subnets")
print("  ✓ Route table visualization")
print("  ✓ All network connections with arrows")
print("  ✓ Comprehensive legend and summaries")
print("  ✓ Professional styling and annotations")
print("=" * 70)

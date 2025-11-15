#!/usr/bin/env python3
"""
Generate AWS Network Diagram with CloudCraft-style Isometric 3D Components
Uses AWS official component representations
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Rectangle, Polygon, Circle, Wedge
from matplotlib.collections import PatchCollection
import numpy as np

# Create large figure
fig, ax = plt.subplots(1, 1, figsize=(32, 24), dpi=200)
ax.set_aspect('equal')

# AWS Official Color Palette
AWS_COLORS = {
    'aws_orange': '#FF9900',
    'aws_dark': '#232F3E',
    'vpc_blue': '#3F8624',
    'subnet_public': '#7AA116',
    'subnet_private': '#147EBA',
    'igw_purple': '#B53389',
    'route_table': '#D86613',
    'internet': '#E7157B',
    'region_bg': '#F4F4F4',
    'connection': '#545B64'
}

def iso_transform(x, y, z):
    """Convert 3D coordinates to isometric 2D projection"""
    # Isometric projection matrix
    iso_x = x - z
    iso_y = y + (x + z) * 0.5
    return iso_x, iso_y

def draw_iso_box(ax, x, y, z, width, depth, height, face_color, edge_color='#232F3E',
                 alpha=0.9, label='', label_size=11, label_color='white'):
    """Draw an isometric box (AWS component style)"""

    # Calculate 8 corners in isometric projection
    corners = [
        iso_transform(x, y, z),                           # 0: bottom-front-left
        iso_transform(x + width, y, z),                   # 1: bottom-front-right
        iso_transform(x + width, y + depth, z),           # 2: bottom-back-right
        iso_transform(x, y + depth, z),                   # 3: bottom-back-left
        iso_transform(x, y, z + height),                  # 4: top-front-left
        iso_transform(x + width, y, z + height),          # 5: top-front-right
        iso_transform(x + width, y + depth, z + height),  # 6: top-back-right
        iso_transform(x, y + depth, z + height),          # 7: top-back-left
    ]

    # Top face (lighter)
    top_color = lighten_color(face_color, 1.2)
    top = Polygon([corners[4], corners[5], corners[6], corners[7]],
                  facecolor=top_color, edgecolor=edge_color, linewidth=2.5, alpha=alpha)
    ax.add_patch(top)

    # Right face (medium)
    right_color = lighten_color(face_color, 0.9)
    right = Polygon([corners[1], corners[2], corners[6], corners[5]],
                    facecolor=right_color, edgecolor=edge_color, linewidth=2.5, alpha=alpha)
    ax.add_patch(right)

    # Left face (darker)
    left_color = lighten_color(face_color, 0.7)
    left = Polygon([corners[0], corners[3], corners[7], corners[4]],
                   facecolor=left_color, edgecolor=edge_color, linewidth=2.5, alpha=alpha)
    ax.add_patch(left)

    # Add label on top face
    if label:
        center_x = (corners[4][0] + corners[6][0]) / 2
        center_y = (corners[4][1] + corners[6][1]) / 2
        ax.text(center_x, center_y, label, fontsize=label_size, ha='center', va='center',
                weight='bold', color=label_color,
                bbox=dict(boxstyle='round,pad=0.5', facecolor=face_color,
                         alpha=0.85, edgecolor='white', linewidth=2))

def draw_iso_cylinder(ax, x, y, z, radius, height, color, label='', segments=30):
    """Draw an isometric cylinder for IGW (AWS style)"""

    # Top ellipse
    theta = np.linspace(0, 2*np.pi, segments)

    # Top circle points in 3D, then isometric projection
    top_points = [iso_transform(x + radius*np.cos(t), y + radius*np.sin(t), z + height)
                  for t in theta]

    # Bottom circle points
    bottom_points = [iso_transform(x + radius*np.cos(t), y + radius*np.sin(t), z)
                     for t in theta]

    # Draw cylinder body (visible faces)
    for i in range(len(theta)//2):
        body = Polygon([bottom_points[i], bottom_points[i+1],
                       top_points[i+1], top_points[i]],
                      facecolor=lighten_color(color, 0.8),
                      edgecolor='#232F3E', linewidth=1.5, alpha=0.9)
        ax.add_patch(body)

    # Draw top ellipse
    top_ellipse = Polygon(top_points, facecolor=lighten_color(color, 1.1),
                         edgecolor='#232F3E', linewidth=2.5, alpha=0.95)
    ax.add_patch(top_ellipse)

    if label:
        center_iso = iso_transform(x, y, z + height)
        ax.text(center_iso[0], center_iso[1], label, fontsize=12, ha='center', va='center',
                weight='bold', color='white',
                bbox=dict(boxstyle='round,pad=0.6', facecolor=color,
                         alpha=0.9, edgecolor='white', linewidth=2.5))

def draw_cloud_icon(ax, x, y, size, color):
    """Draw internet cloud icon (AWS style)"""

    # Cloud using multiple circles
    circle1 = Circle((x - size*0.3, y), size*0.4, facecolor=color,
                    edgecolor='#232F3E', linewidth=3, alpha=0.9)
    circle2 = Circle((x + size*0.3, y), size*0.4, facecolor=color,
                    edgecolor='#232F3E', linewidth=3, alpha=0.9)
    circle3 = Circle((x, y + size*0.2), size*0.5, facecolor=color,
                    edgecolor='#232F3E', linewidth=3, alpha=0.9)
    circle4 = Circle((x - size*0.15, y - size*0.1), size*0.35, facecolor=color,
                    edgecolor='#232F3E', linewidth=3, alpha=0.9)
    circle5 = Circle((x + size*0.15, y - size*0.1), size*0.35, facecolor=color,
                    edgecolor='#232F3E', linewidth=3, alpha=0.9)

    ax.add_patch(circle1)
    ax.add_patch(circle2)
    ax.add_patch(circle3)
    ax.add_patch(circle4)
    ax.add_patch(circle5)

    ax.text(x, y, 'Internet\n0.0.0.0/0', fontsize=14, ha='center', va='center',
            weight='bold', color='white')

def draw_route_table_icon(ax, x, y, z, size, color, label):
    """Draw route table icon (AWS style)"""

    iso_pos = iso_transform(x, y, z)

    # Draw as a flat table/grid icon
    rect = Rectangle((iso_pos[0] - size/2, iso_pos[1] - size/2), size, size,
                     facecolor=color, edgecolor='#232F3E', linewidth=2.5, alpha=0.95)
    ax.add_patch(rect)

    # Add grid lines
    for i in range(1, 3):
        offset = size * i / 3
        ax.plot([iso_pos[0] - size/2, iso_pos[0] + size/2],
               [iso_pos[1] - size/2 + offset, iso_pos[1] - size/2 + offset],
               color='white', linewidth=1.5, alpha=0.7)
        ax.plot([iso_pos[0] - size/2 + offset, iso_pos[0] - size/2 + offset],
               [iso_pos[1] - size/2, iso_pos[1] + size/2],
               color='white', linewidth=1.5, alpha=0.7)

    ax.text(iso_pos[0], iso_pos[1] + size*0.7, label, fontsize=9, ha='center', va='bottom',
            weight='bold', bbox=dict(boxstyle='round,pad=0.4', facecolor=color,
                                    alpha=0.9, edgecolor='white', linewidth=1.5))

def draw_connection_line(ax, x1, y1, z1, x2, y2, z2, color='#545B64', style='-', width=2.5):
    """Draw connection line in isometric view"""

    p1 = iso_transform(x1, y1, z1)
    p2 = iso_transform(x2, y2, z2)

    ax.plot([p1[0], p2[0]], [p1[1], p2[1]], color=color,
           linestyle=style, linewidth=width, alpha=0.8, zorder=1)

    # Add arrowhead
    dx, dy = p2[0] - p1[0], p2[1] - p1[1]
    ax.annotate('', xy=p2, xytext=(p2[0] - dx*0.1, p2[1] - dy*0.1),
                arrowprops=dict(arrowstyle='->', color=color, lw=width, alpha=0.8))

def lighten_color(hex_color, factor):
    """Lighten or darken a hex color"""

    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

    new_rgb = tuple(min(255, int(c * factor)) for c in rgb)

    return '#{:02x}{:02x}{:02x}'.format(*new_rgb)

def draw_region_boundary(ax, x, y, z, width, depth, label, color):
    """Draw region boundary box"""

    corners = [
        iso_transform(x, y, z),
        iso_transform(x + width, y, z),
        iso_transform(x + width, y + depth, z),
        iso_transform(x, y + depth, z)
    ]

    # Draw floor
    floor = Polygon(corners, facecolor=color, edgecolor='#232F3E',
                   linewidth=4, alpha=0.15, linestyle='--')
    ax.add_patch(floor)

    # Add label
    center_x = (corners[0][0] + corners[2][0]) / 2
    center_y = (corners[0][1] + corners[2][1]) / 2
    ax.text(center_x, center_y - 8, label, fontsize=16, ha='center', va='center',
            weight='bold', color='#232F3E',
            bbox=dict(boxstyle='round,pad=0.8', facecolor=color,
                     alpha=0.7, edgecolor='#232F3E', linewidth=3))

# ============================================================================
# DRAW DIAGRAM
# ============================================================================

# Background
ax.set_facecolor('#FFFFFF')
fig.patch.set_facecolor('#FAFAFA')

# Internet Cloud (top center)
draw_cloud_icon(ax, 0, 65, 8, AWS_COLORS['internet'])

# ============================================================================
# US-EAST-1 REGION
# ============================================================================

draw_region_boundary(ax, -50, -20, 0, 70, 45, 'AWS Region: US-EAST-1 (N. Virginia)', '#3F8624')

# IGW A
igw_a_pos = (-35, 5, 35)
draw_iso_cylinder(ax, *igw_a_pos, 4, 6, AWS_COLORS['igw_purple'], 'IGW-A')
draw_connection_line(ax, 0, 0, 60, igw_a_pos[0], igw_a_pos[1], igw_a_pos[2] + 6,
                    AWS_COLORS['aws_orange'], width=3)

# IGW B
igw_b_pos = (0, 5, 35)
draw_iso_cylinder(ax, *igw_b_pos, 4, 6, AWS_COLORS['igw_purple'], 'IGW-B')
draw_connection_line(ax, 0, 0, 60, igw_b_pos[0], igw_b_pos[1], igw_b_pos[2] + 6,
                    AWS_COLORS['aws_orange'], width=3)

# --- VPC A ---
vpc_a_x, vpc_a_y, vpc_a_z = -50, -20, 15
draw_iso_box(ax, vpc_a_x, vpc_a_y, vpc_a_z, 35, 40, 8, AWS_COLORS['vpc_blue'],
            alpha=0.25, label='VPC-A\n10.0.0.0/24', label_size=13)
draw_connection_line(ax, igw_a_pos[0], igw_a_pos[1], igw_a_pos[2],
                    vpc_a_x + 17, vpc_a_y + 20, vpc_a_z + 8, '#147EBA', width=3)

# VPC A Subnets
# Public subnet 1 (AZ-1a)
draw_iso_box(ax, -48, -15, 5, 14, 12, 5, AWS_COLORS['subnet_public'],
            label='PUBLIC\n10.0.0.0/27\nAZ: us-east-1a', label_size=9)

# Public subnet 2 (AZ-1b)
draw_iso_box(ax, -32, -15, 5, 14, 12, 5, AWS_COLORS['subnet_public'],
            label='PUBLIC\n10.0.0.32/27\nAZ: us-east-1b', label_size=9)

# Private subnet 3 (AZ-1a)
draw_iso_box(ax, -48, 0, 5, 14, 12, 5, AWS_COLORS['subnet_private'],
            label='PRIVATE\n10.0.0.64/27\nAZ: us-east-1a', label_size=9)

# Private subnet 4 (AZ-1b)
draw_iso_box(ax, -32, 0, 5, 14, 12, 5, AWS_COLORS['subnet_private'],
            label='PRIVATE\n10.0.0.96/27\nAZ: us-east-1b', label_size=9)

# Private subnet 5 (AZ-1c)
draw_iso_box(ax, -16, -8, 5, 12, 12, 5, AWS_COLORS['subnet_private'],
            label='PRIVATE\n10.0.0.128/27\nAZ: us-east-1c', label_size=9)

# Route Tables for VPC A
draw_route_table_icon(ax, -41, -8, 0, 4, AWS_COLORS['route_table'], 'RTB: vpc_a/1')
draw_connection_line(ax, -41, -8, 0, -41, -8, 5, AWS_COLORS['route_table'], width=2)

draw_route_table_icon(ax, -25, -8, 0, 4, AWS_COLORS['route_table'], 'RTB: vpc_a/2')
draw_connection_line(ax, -25, -8, 0, -25, -8, 5, AWS_COLORS['route_table'], width=2)

# --- VPC B ---
vpc_b_x, vpc_b_y, vpc_b_z = -8, -10, 15
draw_iso_box(ax, vpc_b_x, vpc_b_y, vpc_b_z, 28, 30, 8, AWS_COLORS['vpc_blue'],
            alpha=0.25, label='VPC-B\n172.16.0.0/26', label_size=13)
draw_connection_line(ax, igw_b_pos[0], igw_b_pos[1], igw_b_pos[2],
                    vpc_b_x + 14, vpc_b_y + 15, vpc_b_z + 8, '#147EBA', width=3)

# VPC B Subnets
# Public subnet 1 (AZ-1a)
draw_iso_box(ax, -6, -8, 5, 12, 12, 5, AWS_COLORS['subnet_public'],
            label='PUBLIC\n172.16.0.0/28\nAZ: us-east-1a', label_size=9)

# Private subnet 2 (AZ-1b)
draw_iso_box(ax, -6, 6, 5, 12, 12, 5, AWS_COLORS['subnet_private'],
            label='PRIVATE\n172.16.0.16/28\nAZ: us-east-1b', label_size=9)

# Route Table for VPC B
draw_route_table_icon(ax, 0, 0, 0, 4, AWS_COLORS['route_table'], 'RTB: vpc_b/1')
draw_connection_line(ax, 0, 0, 0, 0, 0, 5, AWS_COLORS['route_table'], width=2)

# ============================================================================
# EU-WEST-2 REGION
# ============================================================================

draw_region_boundary(ax, 25, -10, 0, 35, 30, 'AWS Region: EU-WEST-2 (London)', '#9B59B6')

# IGW C
igw_c_pos = (35, 5, 35)
draw_iso_cylinder(ax, *igw_c_pos, 4, 6, AWS_COLORS['igw_purple'], 'IGW-C')
draw_connection_line(ax, 0, 0, 60, igw_c_pos[0], igw_c_pos[1], igw_c_pos[2] + 6,
                    AWS_COLORS['aws_orange'], width=3)

# --- VPC C ---
vpc_c_x, vpc_c_y, vpc_c_z = 25, -10, 15
draw_iso_box(ax, vpc_c_x, vpc_c_y, vpc_c_z, 35, 28, 8, AWS_COLORS['vpc_blue'],
            alpha=0.25, label='VPC-C\n192.168.0.0/26', label_size=13)
draw_connection_line(ax, igw_c_pos[0], igw_c_pos[1], igw_c_pos[2],
                    vpc_c_x + 17, vpc_c_y + 14, vpc_c_z + 8, '#147EBA', width=3)

# VPC C Subnets
# Public subnet 1 (AZ-2a)
draw_iso_box(ax, 27, -8, 5, 14, 10, 5, AWS_COLORS['subnet_public'],
            label='PUBLIC\n192.168.0.0/28\nAZ: eu-west-2a', label_size=9)

# Private subnet 2 (AZ-2b)
draw_iso_box(ax, 27, 4, 5, 14, 10, 5, AWS_COLORS['subnet_private'],
            label='PRIVATE\n192.168.0.16/28\nAZ: eu-west-2b', label_size=9)

# Route Table for VPC C
draw_route_table_icon(ax, 34, 0, 0, 4, AWS_COLORS['route_table'], 'RTB: vpc_c/1')
draw_connection_line(ax, 34, 0, 0, 34, 0, 5, AWS_COLORS['route_table'], width=2)

# ============================================================================
# ANNOTATIONS
# ============================================================================

# Title
title_text = 'AWS Multi-Region Network Architecture\nDev Environment - Terraform Managed'
ax.text(0, 80, title_text, fontsize=24, ha='center', va='center',
        weight='bold', color='white',
        bbox=dict(boxstyle='round,pad=1.2', facecolor=AWS_COLORS['aws_dark'],
                 alpha=0.95, edgecolor=AWS_COLORS['aws_orange'], linewidth=4))

# Infrastructure Summary
summary = """╔══════════════════════════════════════╗
║    INFRASTRUCTURE SUMMARY           ║
╠══════════════════════════════════════╣
║  Regions:              2            ║
║  VPCs:                 3            ║
║  Internet Gateways:    3            ║
║  Availability Zones:   6            ║
║  Total Subnets:        8            ║
║    • Public Subnets:   3            ║
║    • Private Subnets:  5            ║
║  Route Tables:         4            ║
╚══════════════════════════════════════╝"""

ax.text(-75, 55, summary, fontsize=11, ha='left', va='top',
        family='monospace', weight='bold',
        bbox=dict(boxstyle='round,pad=1', facecolor='white',
                 alpha=0.95, edgecolor=AWS_COLORS['aws_dark'], linewidth=3))

# Route Table Details
routes = """╔══════════════════════════════════════╗
║   ROUTE TABLE CONFIGURATION         ║
╠══════════════════════════════════════╣
║  RTB vpc_a/1:                       ║
║    • 10.0.0.0/24 → local            ║
║    • 0.0.0.0/0 → IGW-A              ║
║                                      ║
║  RTB vpc_a/2:                       ║
║    • 10.0.0.0/24 → local            ║
║    • 0.0.0.0/0 → IGW-A              ║
║                                      ║
║  RTB vpc_b/1:                       ║
║    • 172.16.0.0/26 → local          ║
║    • 0.0.0.0/0 → IGW-B              ║
║                                      ║
║  RTB vpc_c/1:                       ║
║    • 192.168.0.0/26 → local         ║
║    • 0.0.0.0/0 → IGW-C              ║
╚══════════════════════════════════════╝"""

ax.text(-75, 15, routes, fontsize=10, ha='left', va='top',
        family='monospace', weight='bold',
        bbox=dict(boxstyle='round,pad=1', facecolor='#FEF9E7',
                 alpha=0.95, edgecolor=AWS_COLORS['route_table'], linewidth=3))

# Legend
legend_elements = [
    mpatches.Patch(facecolor=AWS_COLORS['internet'], edgecolor='#232F3E', linewidth=2, label='Internet'),
    mpatches.Patch(facecolor=AWS_COLORS['igw_purple'], edgecolor='#232F3E', linewidth=2, label='Internet Gateway'),
    mpatches.Patch(facecolor=AWS_COLORS['vpc_blue'], edgecolor='#232F3E', linewidth=2, label='VPC'),
    mpatches.Patch(facecolor=AWS_COLORS['subnet_public'], edgecolor='#232F3E', linewidth=2, label='Public Subnet'),
    mpatches.Patch(facecolor=AWS_COLORS['subnet_private'], edgecolor='#232F3E', linewidth=2, label='Private Subnet'),
    mpatches.Patch(facecolor=AWS_COLORS['route_table'], edgecolor='#232F3E', linewidth=2, label='Route Table'),
]

legend = ax.legend(handles=legend_elements, loc='upper right', fontsize=13,
                  framealpha=0.95, fancybox=True, shadow=True,
                  bbox_to_anchor=(1.15, 0.95), ncol=1)
legend.get_frame().set_facecolor('white')
legend.get_frame().set_edgecolor(AWS_COLORS['aws_dark'])
legend.get_frame().set_linewidth(3)

# AWS Logo placeholder
ax.text(60, 65, 'AWS', fontsize=28, ha='center', va='center',
        weight='bold', color='white',
        bbox=dict(boxstyle='round,pad=0.8', facecolor=AWS_COLORS['aws_dark'],
                 alpha=0.95, edgecolor=AWS_COLORS['aws_orange'], linewidth=4))

# Set limits and remove axes
ax.set_xlim(-90, 75)
ax.set_ylim(-45, 85)
ax.axis('off')

# Save
output_file = '/home/user/cloud-infra/aws_network_diagram_3d.jpg'
plt.savefig(output_file, format='jpg', dpi=200, bbox_inches='tight',
            facecolor='#FAFAFA', edgecolor='none', pad_inches=0.5)

print("=" * 80)
print("✓ AWS CLOUDCRAFT-STYLE ISOMETRIC DIAGRAM GENERATED!")
print("=" * 80)
print(f"File: {output_file}")
print(f"Resolution: 6400x4800 pixels (200 DPI)")
print(f"Style: CloudCraft-style isometric 3D with AWS official colors")
print()
print("Features:")
print("  ✓ Isometric projection (CloudCraft style)")
print("  ✓ AWS official color palette")
print("  ✓ 3D boxes for VPCs and subnets")
print("  ✓ Cylindrical IGW components")
print("  ✓ Cloud icon for internet")
print("  ✓ Route table icons with grid pattern")
print("  ✓ Region boundaries with labels")
print("  ✓ Connection arrows showing data flow")
print("  ✓ Comprehensive infrastructure summary")
print("  ✓ Detailed route table configuration")
print("  ✓ Professional AWS-style legend")
print("=" * 80)

import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from matplotlib import animation

# Define nodes and their positions (left-to-right, two rows for clarity)
NODES = {
    "ECR":         {"pos": (0, 2), "label": "ECR"},
    "S3":          {"pos": (0, 1), "label": "S3"},
    "AWS Batch":   {"pos": (1.5, 2), "label": "AWS Batch"},
    "Spot":        {"pos": (3, 2), "label": "Spot"},
    "Train":       {"pos": (4.5, 2), "label": "Train"},
    "Model S3":    {"pos": (6, 2), "label": "Model S3"},
    "ECS Fargate": {"pos": (1.5, 1), "label": "ECS Fargate"},
    "Flask API":   {"pos": (3, 1), "label": "Flask API"},
    "API Gateway": {"pos": (4.5, 1), "label": "API Gateway"},
    "User":        {"pos": (6, 1), "label": "User"},
}

# Main AWS deployment and inference flows
FLOWS = [
    [("ECR", "AWS Batch"), ("S3", "AWS Batch"), ("AWS Batch", "Spot"), ("Spot", "Train"), ("Train", "Model S3")],
    [("ECR", "ECS Fargate"), ("ECS Fargate", "Flask API"), ("Model S3", "Flask API"), ("Flask API", "API Gateway"), ("API Gateway", "User")],
]

STEP_LABELS = [
    "Training: ECR/S3 → Batch → Spot → Train → Model S3",
    "Serving: ECR/Model S3 → ECS Fargate → API → User"
]

STATIC_EDGES = [
    ("ECR", "AWS Batch"), ("S3", "AWS Batch"), ("AWS Batch", "Spot"), ("Spot", "Train"), ("Train", "Model S3"),
    ("ECR", "ECS Fargate"), ("ECS Fargate", "Flask API"), ("Model S3", "Flask API"), ("Flask API", "API Gateway"), ("API Gateway", "User"),
]

def draw_architecture(ax, highlight_edges=None, step_label=""):
    ax.clear()
    ax.set_xlim(-0.7, 6.7)
    ax.set_ylim(0.5, 2.7)
    ax.axis('off')
    # Draw static edges (faded, straight lines)
    for src, dst in STATIC_EDGES:
        x0, y0 = NODES[src]["pos"]
        x1, y1 = NODES[dst]["pos"]
        ax.annotate("",
            xy=(x1, y1), xytext=(x0, y0),
            arrowprops=dict(arrowstyle="->", color="#BBBBBB", lw=1.1, alpha=0.25, shrinkA=6, shrinkB=6),
            annotation_clip=False
        )
    # Draw highlighted edges (straight lines)
    if highlight_edges:
        for src, dst in highlight_edges:
            x0, y0 = NODES[src]["pos"]
            x1, y1 = NODES[dst]["pos"]
            ax.annotate("",
                xy=(x1, y1), xytext=(x0, y0),
                arrowprops=dict(arrowstyle="->", color="#FF3333", lw=2.2, alpha=0.9, shrinkA=6, shrinkB=6),
                annotation_clip=False
            )
    # Draw nodes (small white boxes, black border)
    for node, props in NODES.items():
        x, y = props["pos"]
        box = Rectangle((x-0.13, y-0.09), 0.26, 0.18, linewidth=1.1, edgecolor='black', facecolor='white', zorder=2)
        ax.add_patch(box)
        ax.text(x, y, props["label"], ha='center', va='center', fontsize=8, weight='bold', color='black', zorder=3)
    # Step label
    ax.text(3, 2.55, step_label, ha='center', va='center', fontsize=10, weight='bold', color='#FF3333', bbox=dict(boxstyle="round,pad=0.2", facecolor='white', alpha=0.8))

def animate_architecture():
    fig, ax = plt.subplots(figsize=(8, 2.8), facecolor='white')
    plt.tight_layout()
    def animate(i):
        draw_architecture(ax, highlight_edges=FLOWS[i], step_label=STEP_LABELS[i])
    ani = animation.FuncAnimation(fig, animate, frames=len(FLOWS), interval=2200, repeat=True)
    ani.save("aws_core_flow.gif", writer='pillow', fps=1)
    print("Animated AWS core deployment flow saved as aws_core_flow.gif")
    plt.show()

if __name__ == "__main__":
    animate_architecture()
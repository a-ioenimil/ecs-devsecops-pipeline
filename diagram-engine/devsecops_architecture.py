import os
from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import Jenkins
from diagrams.aws.compute import EC2, ECS, ECR
from diagrams.aws.devtools import Codebuild, Codedeploy, Codepipeline
from diagrams.aws.network import VPC, ALB, PrivateSubnet
from diagrams.aws.security import IAMRole
from diagrams.custom import Custom
from diagrams.onprem.container import Docker

# Graph Attributes for professional presentation
graph_attr = {
    "layout": "dot",
    "compound": "true",
    "splines": "ortho", # Straight right-angled
    "nodesep": "0.8",
    "ranksep": "1.0",
    "fontname": "Helvetica",
    "fontsize": "24",
    "pagedir": "TB"
}

node_attr = {
    "fontname": "Helvetica",
    "fontsize": "14",
}

with Diagram("AWS DevSecOps CI/CD Pipeline (Blue/Green ECS)", 
             show=False, 
             direction="LR", 
             graph_attr=graph_attr, 
             node_attr=node_attr,
             filename="aws_devsecops_architecture"):

    # IAM Roles outside or inside? The prompt says within Production Infrastructure, but usually they are standalone or connected. We will put them in the Production Infra cluster.

    with Cluster("1. Source & CI Environment"):
        source = Github("Source Code\n(Push)")
        jenkins_controller = Jenkins("Jenkins Controller")
        with Cluster("Dynamic Build Agents"):
            jenkins_agents = [EC2("Spot Agent 1"), EC2("Spot Agent 2")]
        
        source >> Edge(color="darkgreen", style="bold") >> jenkins_controller
        jenkins_controller - Edge(style="dashed") - jenkins_agents[0]
        jenkins_controller - Edge(style="dashed") - jenkins_agents[1]

    with Cluster("2. DevSecOps Quality Gauntlet (Jenkins Pipeline)"):
        # We can use generic DevTools/Custom icons for missing ones
        # For simplicity without needing local downloaded images, we will use Codebuild for tools if Custom requires local files, 
        # But wait, the prompt says: "Note: You can use existing generic devtools nodes or Custom nodes with downloaded icons for tools like Trivy, Syft, and Gitleaks."
        # If I don't have downloaded icons, I can use generic nodes like 'Codebuild' or text.
        # But 'diagrams.custom' needs a local file. To avoid needing to download and place image files, I will use some generic icons.
        # E.g., from diagrams.aws.devtools import Codebuild
        # I'll use Docker for Docker, and some Server/Generic for others.
        
        gitleaks = Docker("Secret Scan\n(Gitleaks)")
        sonarcloud = Docker("SAST\n(SonarCloud)")
        trivy_fs = Docker("SCA (Filesystem)\n(Trivy)")
        docker_build = Docker("Image Build\n(Docker)")
        trivy_img = Docker("Image Scan\n(Trivy)")
        syft = Docker("SBOM\n(Syft)")

        pipeline_flow = [gitleaks, sonarcloud, trivy_fs, docker_build, trivy_img, syft]
        
        jenkins_agents[0] >> Edge(label="Executes", color="black", style="bold") >> gitleaks
        
        # Link sequentially
        for i in range(len(pipeline_flow)-1):
            pipeline_flow[i] >> Edge(color="orange", style="bold") >> pipeline_flow[i+1]
            
    with Cluster("3. Artifact Storage"):
        ecr = ECR("Container Registry\n(ECR)")
        manifest_repo = Github("Manifest Repo\n(deploy-manifests)")
        
        syft >> Edge(label="Push Image", color="blue", style="bold") >> ecr
        syft >> Edge(label="Update Manifests", color="blue", style="bold") >> manifest_repo

    with Cluster("4. AWS Continuous Deployment"):
        codepipeline = Codepipeline("CodePipeline")
        codedeploy = Codedeploy("CodeDeploy\n(Blue/Green)")
        
        manifest_repo >> Edge(label="Trigger", color="darkgreen", style="bold") >> codepipeline
        codepipeline >> Edge(color="darkgreen", style="bold") >> codedeploy

    with Cluster("5. Production Infrastructure (AWS VPC)"):
        vpc = VPC("Production VPC")
        
        iam_roles = [IAMRole("ECS Task Exec Role"), IAMRole("CodeDeploy Role")]
        
        with Cluster("Availability Zones / Private Subnets"):
            alb = ALB("Application Load Balancer")
            
            with Cluster("Target Groups"):
                tg_blue = PrivateSubnet("Blue TG (Active)")
                tg_green = PrivateSubnet("Green TG (Test)")
            
            ecs_cluster = ECS("Amazon ECS Cluster")
            
            # Relationships
            alb >> Edge(label="Live Traffic", color="darkgreen", style="bold") >> tg_blue
            alb >> Edge(label="Test Traffic", color="purple", style="dashed") >> tg_green
            
            tg_blue >> Edge(color="darkgreen") >> ecs_cluster
            tg_green >> Edge(color="purple", style="dashed") >> ecs_cluster

        # Deploy Controller to Target Groups / ECS
        codedeploy >> Edge(label="Deploys & Shifts Traffic", color="red", style="bold") >> ecs_cluster
        codedeploy >> Edge(style="dashed", color="red") >> alb
        codedeploy >> Edge(style="dashed", color="red") >> tg_blue
        codedeploy >> Edge(style="dashed", color="red") >> tg_green
        
        ecr >> Edge(label="Pull Image", color="brown", style="dashed") >> ecs_cluster

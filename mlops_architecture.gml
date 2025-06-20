graph [
  directed 1
  node [
    id 0
    label "GitHub"
    layer "cicd"
    type "source"
    icon "&#128193;"
  ]
  node [
    id 1
    label "GitHub_Actions"
    layer "cicd"
    type "automation"
    icon "&#128260;"
  ]
  node [
    id 2
    label "Terraform"
    layer "cicd"
    type "infrastructure"
    icon "&#127959;&#65039;"
  ]
  node [
    id 3
    label "Docker"
    layer "cicd"
    type "container"
    icon "&#128051;"
  ]
  node [
    id 4
    label "ECR"
    layer "storage"
    type "registry"
    icon "&#128230;"
  ]
  node [
    id 5
    label "S3_Data"
    layer "storage"
    type "storage"
    icon "&#129699;"
  ]
  node [
    id 6
    label "DVC"
    layer "storage"
    type "versioning"
    icon "&#128202;"
  ]
  node [
    id 7
    label "AWS_Batch"
    layer "compute"
    type "orchestrator"
    icon "&#9881;&#65039;"
  ]
  node [
    id 8
    label "Spot_Instances"
    layer "compute"
    type "compute"
    icon "&#128176;"
  ]
  node [
    id 9
    label "ECS_Fargate"
    layer "compute"
    type "serverless"
    icon "&#128640;"
  ]
  node [
    id 10
    label "Flask_API"
    layer "application"
    type "api"
    icon "&#127760;"
  ]
  node [
    id 11
    label "ML_Training"
    layer "application"
    type "training"
    icon "&#129504;"
  ]
  node [
    id 12
    label "Model_Storage"
    layer "application"
    type "model"
    icon "&#127919;"
  ]
  node [
    id 13
    label "API_Gateway"
    layer "client"
    type "gateway"
    icon "&#128279;"
  ]
  node [
    id 14
    label "End_Users"
    layer "client"
    type "user"
    icon "&#128100;"
  ]
  edge [
    source 0
    target 1
    flow "trigger"
    weight 3
  ]
  edge [
    source 1
    target 2
    flow "deploy"
    weight 3
  ]
  edge [
    source 1
    target 3
    flow "build"
    weight 3
  ]
  edge [
    source 2
    target 7
    flow "provision"
    weight 2
  ]
  edge [
    source 2
    target 9
    flow "provision"
    weight 2
  ]
  edge [
    source 2
    target 5
    flow "provision"
    weight 2
  ]
  edge [
    source 3
    target 4
    flow "push"
    weight 3
  ]
  edge [
    source 4
    target 8
    flow "pull"
    weight 3
  ]
  edge [
    source 4
    target 9
    flow "deploy"
    weight 3
  ]
  edge [
    source 5
    target 11
    flow "data"
    weight 4
  ]
  edge [
    source 5
    target 10
    flow "load_model"
    weight 4
  ]
  edge [
    source 6
    target 5
    flow "sync"
    weight 4
  ]
  edge [
    source 7
    target 8
    flow "schedule"
    weight 5
  ]
  edge [
    source 8
    target 11
    flow "execute"
    weight 5
  ]
  edge [
    source 9
    target 10
    flow "host"
    weight 3
  ]
  edge [
    source 10
    target 7
    flow "submit"
    weight 5
  ]
  edge [
    source 10
    target 13
    flow "expose"
    weight 3
  ]
  edge [
    source 11
    target 12
    flow "save"
    weight 4
  ]
  edge [
    source 12
    target 5
    flow "store"
    weight 4
  ]
  edge [
    source 13
    target 14
    flow "serve"
    weight 3
  ]
]

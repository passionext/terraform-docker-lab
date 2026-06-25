terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "lab_network" {
  name = "default_network"
}

# --- IMAGES ---
resource "docker_image" "nginx_lb" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_image" "api_image" {
  name = "my-api-image:latest"
  build {
    context    = "${path.module}/api"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "frontend_image" {
  name = "my-frontend-image:latest"
  build {
    context    = "${path.module}/frontend"
    dockerfile = "Dockerfile"
  }
}

# --- CONTAINERS ---
# 1. Hidden API Server (No external ports)
resource "docker_container" "api" {
  name  = "api_server"
  image = docker_image.api_image.name
  networks_advanced { name = docker_network.lab_network.name }
}

# 2. Two Web Servers (No external ports, they talk to the API internally)
resource "docker_container" "frontend" {
  count = 2
  name  = "frontend_server_${count.index}"
  image = docker_image.frontend_image.name
  networks_advanced { name = docker_network.lab_network.name }
}

# 3. Load Balancer (Exposed to you on Port 8000)
resource "docker_container" "load_balancer" {
  name  = "lb_server"
  image = docker_image.nginx_lb.image_id
  ports {
    internal = 80
    external = 8000
  }
  volumes {
    host_path      = "${abspath(path.module)}/lb.conf"
    container_path = "/etc/nginx/nginx.conf"
  }
  networks_advanced { name = docker_network.lab_network.name }
}

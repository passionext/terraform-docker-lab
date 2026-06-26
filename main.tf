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

resource "docker_image" "grafana_image" {
  name         = "grafana/grafana:latest"
  keep_locally = false
}

resource "docker_image" "prometheus_image" {
  name         = "prom/prometheus:latest"
  keep_locally = false
}

# --- CONTAINERS ---

# 1. Hidden API Server
resource "docker_container" "api" {
  name  = "api_server"
  image = docker_image.api_image.name
  networks_advanced { name = docker_network.lab_network.name }
}

# 2. Two Web Servers
resource "docker_container" "frontend" {
  count = 2
  name  = "frontend_server_${count.index}"
  image = docker_image.frontend_image.name
  networks_advanced { name = docker_network.lab_network.name }
}

# 3. Grafana Server (Hidden behind LB)
resource "docker_container" "grafana" {
  name  = "grafana_server"
  image = docker_image.grafana_image.name
  networks_advanced { name = docker_network.lab_network.name }
  
  # This tells Grafana it lives at /grafana/ so it loads assets correctly
  env = [
    "GF_SERVER_ROOT_URL=http://localhost:8000/grafana/",
    "GF_SERVER_SERVE_FROM_SUB_PATH=true"
  ]
}

# 4. Prometheus Server (Hidden behind LB)
resource "docker_container" "prometheus" {
  name  = "prometheus_server"
  image = docker_image.prometheus_image.name
  networks_advanced { name = docker_network.lab_network.name }

  # This tells Prometheus to expect traffic at /prometheus/
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--web.external-url=http://localhost:8000/prometheus/"
  ]
  
  volumes {
    host_path      = "${abspath(path.module)}/conf/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# 5. Load Balancer (The ONLY container exposed to your machine)
resource "docker_container" "load_balancer" {
  name  = "lb_server"
  image = docker_image.nginx_lb.image_id
  ports {
    internal = 80
    external = 8000
  }
  volumes {
    # Updated to look inside the conf folder!
    host_path      = "${abspath(path.module)}/conf/lb.conf"
    container_path = "/etc/nginx/nginx.conf"
  }
  networks_advanced { name = docker_network.lab_network.name }
}

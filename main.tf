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

resource "docker_image" "webServer_image" {
  name = "my-webserver-image:latest"
  build {
    context    = "${path.module}/webServer"
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

# 2. Two Web Servers
resource "docker_container" "webServer" {
  count = 2
  name  = "web_server_${count.index}"
  image = docker_image.webServer_image.name
  networks_advanced { name = docker_network.lab_network.name }
}

# 3. Grafana Server (Hidden behind LB)
resource "docker_container" "grafana" {
  name  = "grafana_server"
  image = docker_image.grafana_image.name
  networks_advanced { name = docker_network.lab_network.name }

  # FIX 1: Give Grafana permission to write to the data volume so it doesn't crash
  user = "root"

  # This tells Grafana it lives at /grafana/ so it loads assets correctly
  env = [
    "GF_SERVER_ROOT_URL=http://localhost:8000/grafana/",
    "GF_SERVER_SERVE_FROM_SUB_PATH=true"
  ]

  # FIX 2: Save your dashboards permanently
  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }
}

# 4. Prometheus Server (Hidden behind LB)
resource "docker_container" "prometheus" {
  name  = "prometheus_server"
  image = docker_image.prometheus_image.name
  networks_advanced { name = docker_network.lab_network.name }

  # FIX 1: Give Prometheus permission to write to the data volume
  user = "root"

  # This tells Prometheus to expect traffic at /prometheus/
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--web.external-url=http://localhost:8000/prometheus/"
  ]

  # Config file mount
  volumes {
    host_path      = "${abspath(path.module)}/conf/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
  
  # FIX 2: Save your historical metrics permanently
  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
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

# 1. Create a Named Volume for persistence
resource "docker_volume" "db_data" {
  name = "postgres_data_volume"
}

# 2. Add the Database Image
resource "docker_image" "postgres_image" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  name  = "postgres_db"
  image = docker_image.postgres_image.name

  env = [
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=secretpassword",
    "POSTGRES_DB=app_db"
  ]

  # 1. Mount the persistent data storage
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }

  # 2. Mount your conf folder so Postgres can find init.sql and all_relics.csv
  volumes {
    host_path      = "${abspath(path.module)}/conf"
    container_path = "/docker-entrypoint-initdb.d"
  }

  networks_advanced { name = docker_network.lab_network.name }
}

# Create the volume for Grafana Dashboards
resource "docker_volume" "grafana_data" {
  name = "grafana_data_volume"
}

# Create the volume for Prometheus Metrics
resource "docker_volume" "prometheus_data" {
  name = "prometheus_data_volume"
}

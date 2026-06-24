terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

# Leaving it empty so that Terraform just talks with the local Docker application.
provider "docker" {}

resource "docker_network" "lab_network" {
  name = "default_network"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_image" "database" {
  name         = "postgres:latest"
  keep_locally = false
}

resource "docker_container" "frontend" {
  image = docker_image.nginx.image_id
  name  = "frontend_server"

  ports {
    internal = 80
    external = 8000
  }

  # Added so it can talk to the database
  networks_advanced {
    name = docker_network.lab_network.name
  }
} # <-- Added the missing closing brace here

resource "docker_container" "postgresdb" {
  image = docker_image.database.image_id # <-- Fixed the reference name
  name  = "database_server"

  ports {
    internal = 5432
    external = 5432
  }

  # Added mandatory environment variable for the Postgres image to run
  env = [
    "POSTGRES_PASSWORD=mysecretpassword"
  ]

  networks_advanced {
    name = docker_network.lab_network.name
  }
}

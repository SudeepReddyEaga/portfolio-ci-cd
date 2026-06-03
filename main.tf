provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "portfolio_server" {
  ami           = "ami-0440d3b780d96b29d"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  user_data = <<-EOF
              #!/bin/bash

              yum update -y

              # Install Docker
              yum install -y docker

              systemctl start docker
              systemctl enable docker

              usermod -aG docker ec2-user

              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
              -o /usr/local/bin/docker-compose

              chmod +x /usr/local/bin/docker-compose

              mkdir -p /home/ec2-user/monitoring

              cd /home/ec2-user/monitoring

              # Create Prometheus config
              cat > prometheus.yml <<EOT
              global:
                scrape_interval: 5s

              scrape_configs:
                - job_name: 'cadvisor'
                  static_configs:
                    - targets: ['cadvisor:8080']
              EOT

              # Create Docker Compose file
              cat > docker-compose.yml <<EOT
              version: '3'

              services:
                portfolio:
                  image: sudeepkumarreddyeaga/sudeep-portfolio:latest
                  container_name: portfolio
                  ports:
                    - "80:80"

                prometheus:
                  image: prom/prometheus
                  container_name: prometheus
                  ports:
                    - "9091:9090"
                  volumes:
                    - ./prometheus.yml:/etc/prometheus/prometheus.yml

                grafana:
                  image: grafana/grafana
                  container_name: grafana
                  ports:
                    - "4000:3000"

                cadvisor:
                  image: gcr.io/cadvisor/cadvisor:latest
                  container_name: cadvisor
                  privileged: true
                  ports:
                    - "8082:8080"
                  volumes:
                    - /:/rootfs:ro
                    - /var/run:/var/run:rw
                    - /sys:/sys:ro
                    - /var/lib/docker/:/var/lib/docker:ro
              EOT

              # Start everything
              cd /home/ec2-user/monitoring

              /usr/local/bin/docker-compose up -d

              EOF

  tags = {
    Name = "Sudeep-Portfolio-Server"
  }
}

resource "aws_security_group" "monitoring_sg" {
  name = "portfolio-monitoring-sg"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "cAdvisor"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

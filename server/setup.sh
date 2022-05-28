#! /bin/sh

# Install unzip
apt-get install unzip

# Defines variables
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OPT_DIR="/opt/monitoring-tools"

mkdir -p $OPT_DIR
cd $OPT_DIR

# Install Prometheus

# Create Prometheus user & directory
useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Download Prometheus binary
echo "Installing Prometheus..."
wget https://github.com/prometheus/prometheus/releases/download/v2.35.0/prometheus-2.35.0.linux-amd64.tar.gz
tar -xvf prometheus-2.35.0.linux-amd64.tar.gz
mv prometheus-2.35.0.linux-amd64/prometheus /usr/local/bin/prometheus
mv prometheus-2.35.0.linux-amd64/promtool /usr/local/bin/promtool
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Copy Prometheus configuration file
cp $DIR/config/prometheus.yaml /etc/prometheus/prometheus.yaml
chown prometheus:prometheus /etc/prometheus/prometheus.yaml

cp -r prometheus-2.35.0.linux-amd64/consoles /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles

cp -r prometheus-2.35.0.linux-amd64/console_libraries /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Create Prometheus systemd unit
cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yaml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Install Grafana
echo "Installing Grafana..."
apt-get install -y adduser libfontconfig1
wget https://dl.grafana.com/oss/release/grafana_8.5.2_amd64.deb
dpkg -i grafana_8.5.2_amd64.deb

# Copy Grafana datasource
cp $DIR/config/grafana/datasource.yaml /etc/grafana/provisioning/datasources/datasource.yaml

systemctl daemon-reload
systemctl enable grafana-server.service
systemctl start grafana-server

# Install Jaeger
echo "Installing Jaeger..."
wget https://github.com/jaegertracing/jaeger/releases/download/v1.34.0/jaeger-1.34.0-linux-amd64.tar.gz
tar -xvf jaeger-1.34.0-linux-amd64.tar.gz
mv jaeger-1.34.0-linux-amd64/jaeger-all-in-one /usr/local/bin/jaeger-all-in-one

# Create jaeger user
useradd --no-create-home --shell /bin/false jaeger
chown jaeger:jaeger /usr/local/bin/jaeger-all-in-one

# Create Jaeger systemd unit
cat <<EOF > /etc/systemd/system/jaeger.service
[Unit]
Description=Jaeger
Wants=network-online.target
After=network-online.target
[Service]
User=jaeger
Group=jaeger
Type=simple
ExecStart=/usr/local/bin/jaeger-all-in-one \
    --collector.zipkin.host-port=:9411
[Install]
WantedBy=multi-user.target
EOF

# Start Jaeger
systemctl daemon-reload
systemctl enable jaeger
systemctl start jaeger

# Install Loki
echo "Installing Loki..."
wget https://github.com/grafana/loki/releases/download/v2.5.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki

# Create loki user
useradd --no-create-home --shell /bin/false loki
chown loki:loki /usr/local/bin/loki

# Download Loki configuration
wget wget https://raw.githubusercontent.com/grafana/loki/master/cmd/loki/loki-local-config.yaml
mkdir /etc/loki
mv loki-local-config.yaml /etc/loki/loki-local-config.yaml
chown loki:loki /etc/loki/loki-local-config.yaml

# Create Loki systemd unit
cat <<EOF > /etc/systemd/system/loki.service
[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target
[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki \
    --config.file /etc/loki/loki-local-config.yaml \
    --log.level=debug
[Install]
WantedBy=multi-user.target
EOF

# Start Loki
echo "Starting Loki..."
systemctl daemon-reload
systemctl enable loki
systemctl start loki

# Clean up downloaded files
echo "Cleaning up..."
rm -rf $OPT_DIR

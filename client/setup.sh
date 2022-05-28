# Install unzip
apt-get install unzip

# Defines variables
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OPT_DIR="/opt/monitoring-tools"

mkdir -p $OPT_DIR
cd $OPT_DIR

# Install otelcol-contrib
echo "Installing otelcol-contrib..."
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.43.0/otelcol-contrib_0.43.0_linux_amd64.deb
dpkg -i otelcol-contrib_0.43.0_linux_amd64.deb

# Copy otelcol-contrib configuration file
cp $DIR/config/otelcol-contrib-config.yaml /etc/otelcol-contrib/config.yaml

# Restart otelcol-contrib
systemctl restart otelcol-contrib

# Install promtail
echo "Installing promtail..."
wget https://github.com/grafana/loki/releases/download/v2.5.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
mv promtail-linux-amd64 /usr/local/bin/promtail

# Create promtail user
useradd --no-create-home --shell /bin/false promtail
chown promtail:promtail /usr/local/bin/promtail

# Copy promtail configuration file
mkdir /etc/promtail
cp $DIR/config/promtail-local.yaml /etc/promtail/promtail-local.yaml
chown -R promtail:promtail /etc/promtail

# Create promtail systemd unit
cat <<EOF > /etc/systemd/system/promtail.service
[Unit]
Description=Promtail
Wants=network-online.target
After=network-online.target
[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail \
    -config.file=/etc/promtail/promtail-local.yaml
[Install]
WantedBy=multi-user.target
EOF

# Start promtail
systemctl daemon-reload
systemctl enable promtail
systemctl start promtail

# Clean up downloaded files
rm -rf $OPT_DIR

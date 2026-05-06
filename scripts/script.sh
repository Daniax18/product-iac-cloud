sudo apt update
sudo apt install -y tmux
tmux new -s install
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.17.0/buildx-v0.17.0.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
git clone https://github.com/Daniax18/devops-iac-starter.git
cd devops-iac-starter
git checkout develop

cat <<'EOF' > .env
AUTH_DB_USER=postgres
AUTH_DB_PASSWORD=postgres
AUTH_DB_NAME=authentication_db

PRODUCT_DB_USER=postgres
PRODUCT_DB_PASSWORD=postgres
PRODUCT_DB_NAME=product_db

JWT_SECRET=5367566B59703373367639792F423F4528482B4D6251655468576D5A71347431
JWT_ISSUER=AuthAPI
JWT_AUDIENCE=AuthAPIUsers
JWT_EXPIRY_MINUTES=60
EOF

docker compose up --build
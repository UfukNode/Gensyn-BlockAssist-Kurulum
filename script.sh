#!/bin/bash

set -e

echo "======================================================"
echo "   Bu Script Ufuk Degen Tarafından Hazırlanmıştır!    "
echo "======================================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[BİLGİ]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[BAŞARILI]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[UYARI]${NC} $1"
}

print_error() {
    echo -e "${RED}[HATA]${NC} $1"
}

handle_error() {
    print_error "Kurulum sırasında hata oluştu. Satır: $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

print_status "Adım 1: Sistem paketleri güncelleniyor ve gerekli bağımlılıklar kuruluyor..."
sudo apt update > /dev/null 2>&1
sudo apt install -y \
  make build-essential gcc \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
  curl git unzip \
  libxi6 libxrender1 libxtst6 libxrandr2 libglu1-mesa libopenal1 > /dev/null 2>&1
print_success "Sistem bağımlılıkları kuruldu"

print_status "Adım 2: BlockAssist repository klonlanıyor..."
if [ -d "blockassist" ]; then
    print_warning "blockassist dizini zaten mevcut, siliniyor..."
    rm -rf blockassist
fi
git clone https://github.com/gensyn-ai/blockassist.git > /dev/null 2>&1
cd blockassist
print_success "Repository klonlandı"

print_status "Adım 3: Node.js kurulumu kontrol ediliyor..."
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" = "20" ]; then
        print_success "Node.js 20 zaten kurulu"
    else
        print_status "Mevcut Node.js kaldırılıyor ve v20 kuruluyor..."
        sudo apt remove -y nodejs npm > /dev/null 2>&1 || true
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
        sudo apt install -y nodejs > /dev/null 2>&1
        print_success "Node.js 20 kuruldu"
    fi
else
    print_status "Node.js kuruluyor..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
    sudo apt install -y nodejs > /dev/null 2>&1
    print_success "Node.js 20 kuruldu"
fi

print_status "Adım 4: Yarn kuruluyor..."
if ! command -v yarn > /dev/null 2>&1; then
    curl -o- -L https://yarnpkg.com/install.sh | bash > /dev/null 2>&1
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    print_success "Yarn kuruldu"
else
    print_success "Yarn zaten kurulu"
fi

print_status "Adım 5: Java kuruluyor..."
chmod +x setup.sh
./setup.sh > /dev/null 2>&1
print_success "Java kuruldu"

print_status "Adım 6: pyenv kuruluyor..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash > /dev/null 2>&1
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)" > /dev/null 2>&1
    eval "$(pyenv init -)" > /dev/null 2>&1
    print_success "pyenv kuruldu"
else
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)" > /dev/null 2>&1
    eval "$(pyenv init -)" > /dev/null 2>&1
    print_success "pyenv zaten kurulu"
fi

print_status "Adım 7: Python 3.10 kuruluyor..."
if ! pyenv versions | grep -q "3.10"; then
    print_status "Python 3.10.12 indiriliyor ve kuruluyor... (Bu biraz zaman alabilir)"
    pyenv install 3.10.12
fi
pyenv global 3.10.12
pyenv rehash
print_success "Python 3.10.12 kuruldu ve aktifleştirildi"

print_status "Adım 8: Python paketleri kuruluyor..."
python -m pip install --upgrade pip

print_status "readchar sistem paketi kuruluyor..."
sudo apt install -y python3-readchar python3-pip python3-dev

print_status "Python paketleri pip ile kuruluyor..."
python -m pip install psutil --force-reinstall --no-cache-dir
python -m pip install readchar --force-reinstall --no-cache-dir
python -m pip install keyboard --no-cache-dir

print_status "BlockAssist paketleri kuruluyor..."
python -m pip install -e . --no-cache-dir
python -m pip install "mbag-gensyn[malmo]" --no-cache-dir

print_status "Python kurulumunu test ediliyor..."
python -c "import readchar; print('readchar OK')" || {
    print_warning "readchar sorunu devam ediyor, alternative yüklenecek"
    python -m pip install pynput --no-cache-dir
}

print_success "Python paketleri kuruldu"

print_status "Ortam değişkenleri ayarlanıyor..."
{
    echo ""
    echo "BlockAssist için gerekli ortam değişkenleri"
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init --path)"'
    echo 'eval "$(pyenv init -)"'
    echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"'
} >> ~/.bashrc

print_success "Ortam değişkenleri ~/.bashrc dosyasına eklendi"

echo ""
echo "=================================================="
echo "         KURULUM BAŞARIYLA TAMAMLANDI!           "
echo "=================================================="
echo ""
print_success "BlockAssist başarıyla kuruldu!"
echo ""
echo -e "${YELLOW}ÇALIŞTIRMAK İÇİN:${NC}"
echo "Aşağıdaki komutları çalıştırın:"
echo ""
echo -e "${BLUE}cd blockassist${NC}"
echo -e "${BLUE}source ~/.bashrc${NC}"
echo -e "${BLUE}python run.py${NC}"
echo ""
echo -e "${YELLOW}UYARI:${NC}"
echo "• Program size Hugging Face token'ı soracak"
echo "• Token girdikten sonra tarayıcınızı açın"
echo "• http://localhost:3000 adresine gidin ve mail adresinizle giriş yapın"
echo "• Minecraft pencerelerinin açılmasını bekleyin"
echo "• Terminal'de ENTER'a basın ve oyunu oynayın"
echo ""

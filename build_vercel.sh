#!/bin/bash
echo "Iniciando build na Vercel..."

# Baixar o SDK do Flutter (se ainda não existir no cache)
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK..."
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable
fi

# Adicionar flutter ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Habilitar suporte web no SDK (garantia)
flutter config --enable-web

# Instalar dependências e buildar
echo "Resolvendo dependências..."
flutter clean
flutter pub get

echo "Gerando build otimizada..."
flutter build web --release --no-pub

#!/bin/bash
echo "Iniciando build na Vercel..."

# Baixar o SDK do Flutter (se ainda não existir no cache)
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Adicionar flutter ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Instalar dependências e buildar
echo "Resolvendo dependências e gerando build..."
flutter clean
flutter pub get
flutter build web --release

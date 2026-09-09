#!/bin/zsh

flutter pub get

if [ $? -ne 0 ]; then
    echo "Fehler bei flutter pub get. Führe flutter clean aus..."
    flutter clean
    flutter pub get
fi

flutter run --no-enable-impeller
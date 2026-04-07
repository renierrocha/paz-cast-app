@echo off
echo 🧪 Testando conexão com Google Sheets...
echo.

cd /d %~dp0

if not exist "pubspec.yaml" (
    echo ❌ Erro: Execute este script dentro da pasta do projeto Flutter
    pause
    exit /b 1
)

echo 📦 Verificando dependências...
flutter pub get >nul 2>&1

echo 🚀 Executando teste...
dart run teste_planilha.dart

echo.
echo 🏁 Teste concluído. Pressione qualquer tecla para continuar...
pause >nul
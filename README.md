# Cadastro de Fotos (Flutter + Supabase + Vercel)

Pastas:
- supabase/schema.sql  -> tabela e bucket de fotos
- web/                 -> painel web (JS puro) para a Vercel
- app_src/             -> código do app Flutter
- setup_app.bat / .sh  -> cria o projeto Flutter e gera o APK
- modelo_importacao.xlsx -> modelo do Excel (MATRICULA, NOME, LOCAL)

## Passo a passo

### 1) Supabase
1. Crie um projeto em https://supabase.com
2. SQL Editor > cole o conteúdo de supabase/schema.sql > Run
3. Authentication > Users > Add user (e-mail e senha; marque "Auto Confirm")
4. Settings > API: copie a "Project URL" e a "anon public key"

### 2) Configurar as chaves (2 lugares)
- web/config.js
- app_src/lib/config.dart

### 3) Painel web na Vercel
Opção A (terminal):  cd web  &&  npx vercel --prod
Opção B: suba a pasta web em um repositório GitHub e importe na Vercel
(Framework Preset: Other; sem build command).

### 4) APK
Requer Flutter instalado (https://docs.flutter.dev/get-started/install) e Android SDK.
- Windows: dê dois cliques em setup_app.bat
- Linux/Mac: ./setup_app.sh
APK final: app/build/app/outputs/flutter-apk/app-release.apk
Copie para o celular e instale (permita "fontes desconhecidas").

### 5) Uso
- No site: faça login > Importar Excel.
- No app: faça login > toque na pessoa > tire a foto (long press = ver a foto).
- No site: Baixar fotos (ZIP) -> arquivos MATRICULA.jpg; filtro por local disponível.

## Observações
- A anon key pode ficar no código; a proteção é o login + RLS do schema.sql.
- Nunca use a service_role key no app/site.
- Sem modo offline: precisa de internet para enviar a foto.

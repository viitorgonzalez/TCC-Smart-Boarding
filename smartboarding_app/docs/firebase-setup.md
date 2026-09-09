# Ativação do Firebase / Push (FCM)

Status: **código do app pronto para receber; Firebase ainda NÃO ativado.**

> ℹ️ **Nada aqui é obrigatório para desenvolver.** O app e a API funcionam com o push
> desligado — os avisos são **persistidos** e aparecem no mural do aluno de qualquer jeito.
> Verificado em 09/09/2026: sem `FIREBASE_CREDENTIALS_PATH`, a API sobe, o
> `FirebaseConfig` loga um WARN (`Notificações FCM desabilitadas`) e publicar aviso
> continua devolvendo `200` com o registro gravado.

Este guia liga o push quando você estiver pronto.

## Passo a passo

1. Garantir as plataformas: `flutter create . --platforms=android,ios`
   (as pastas `android/` e `ios/` já existem — este comando é idempotente).
2. Criar o projeto no [Firebase Console](https://console.firebase.google.com).
3. `dart pub global activate flutterfire_cli` e depois `flutterfire configure`.
   Isso registra os apps Android/iOS, baixa `google-services.json` /
   `GoogleService-Info.plist` e gera `lib/firebase_options.dart`.
4. Ativar a **Cloud Messaging API** no projeto Firebase.
5. Adicionar as dependências no `pubspec.yaml` e rodar `flutter pub get`:
   ```yaml
   firebase_core: ^3.6.0
   firebase_messaging: ^15.1.3
   flutter_local_notifications: ^18.0.1
   ```
6. Em `lib/main.dart`, inicializar antes do `runApp`:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
7. Após login, registrar o token (ver TODO em `auth_provider.dart`):
   ```dart
   final messaging = FirebaseMessaging.instance;
   await messaging.requestPermission();
   final token = await messaging.getToken();
   if (token != null) {
     await NotificationService().registerToken(token, Platform.isIOS ? 'ios' : 'android');
   }
   ```
8. No logout, remover o token: `await NotificationService().removeToken();`
   (ver TODO em `auth_provider.dart`).
9. Foreground: `FirebaseMessaging.onMessage.listen(...)` exibindo via
   `flutter_local_notifications`. Background: `FirebaseMessaging.onBackgroundMessage(...)`.
10. Validar com um envio de teste pelo Firebase Console antes de integrar
    com o backend.

## Backend
- Gerar a Service Account JSON (Firebase Console → Configurações → Contas de
  serviço) e apontar `FIREBASE_CREDENTIALS_PATH` no `.env` do `smartboarding-api`.
- **Nunca versione a credencial.** O `.gitignore` da raiz cobre
  `**/firebase-service-account*.json` e `**/GoogleService-Info.plist`; o
  `google-services.json` é coberto pelo `.gitignore` do app. Há um
  `android/app/google-services.json.example` mostrando o formato esperado.
- O repo tem hook anti-segredo local (`.githooks/pre-commit`) e GitGuardian no CI —
  os dois barram credencial em texto, e com razão.

## Contrato já usado pelo app (não muda)
- `POST /api/devices/token { token, platform }` — `NotificationService.registerToken`
- `DELETE /api/devices/token` — `NotificationService.removeToken`

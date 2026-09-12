/// Client ID **Web** do Google. É ele que o app informa como serverClientId pra
/// receber um ID token destinado à nossa API — o backend compara este mesmo
/// valor no campo "aud" do token.
///
/// Usar o client ID do Android aqui faria o "aud" não bater e o login falhar
/// sempre, com uma mensagem que não aponta a causa.
///
/// Não é segredo: vai embutido no APK de qualquer forma, e o que protege a
/// conta é o par pacote + SHA-1 registrado no Google Cloud.
const googleWebClientId =
    '913892767280-uu0n9ah3lmql96s8ob4turmcm9q4olae.apps.googleusercontent.com';

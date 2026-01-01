Flutter Desktop App (Windows .exe)

Visão geral
- Projeto Flutter mínimo focado em gerar um executável Windows (.exe).

Pré-requisitos
- Flutter SDK instalado (Windows).
- Habilitar suporte a desktop: `flutter config --enable-windows-desktop`.
- Verifique com `flutter doctor -v` que o suporte a Windows está OK.

Como usar
1. Abra um terminal na pasta do projeto (`flutter_desktop_app`).
2. Caso ainda não tenha os arquivos de plataforma, rode:

```
flutter create .
```

3. Para executar no desktop durante desenvolvimento:

```
flutter run -d windows
```

4. Para gerar o executável final (.exe) em Release:

```
flutter build windows --release
```

Local do executável gerado
- O `.exe` ficará em: `build/windows/runner/Release/` (nome do executável conforme o `name` no `pubspec.yaml`).

Notas
- A pasta `windows/` é gerada pelo `flutter create` e contém os artefatos do runner (Visual Studio project files). 
- Para distribuir um .exe, você pode empacotar os arquivos gerados em `build/windows/runner/Release/`.

Quer que eu rode `flutter create` ou adicione arquivos de runner do Windows aqui? Se sim, preciso que você execute os comandos localmente (tenha o Flutter e Visual Studio instalados).
FLUTTER = flutter

run-windows:
	$(FLUTTER) run -d windows --enable-flutter-gpu --enable-impeller

run-linux:
	$(FLUTTER) run -d linux --enable-flutter-gpu --enable-impeller

run-macos:
	$(FLUTTER) run -d macos --enable-flutter-gpu --enable-impeller


build-windows:
	$(FLUTTER) build windows --release --enable-flutter-gpu --enable-impeller

build-linux:
	$(FLUTTER) build linux --release --enable-flutter-gpu --enable-impeller

build-macos:
	$(FLUTTER) build macos --release --enable-flutter-gpu --enable-impeller

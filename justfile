set shell := ["zsh", "-cu"]

generate:
    xcodegen generate

build: generate
    xcodebuild -project MonsterDeleter.xcodeproj -scheme MonsterDeleter -configuration Debug -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

test: generate
    xcodebuild -project MonsterDeleter.xcodeproj -scheme MonsterDeleter -configuration Debug -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test

check: test

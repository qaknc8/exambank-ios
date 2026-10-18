# Windows + 무료 Apple ID로 아이폰에 설치

Mac과 유료 개발자 계정 없이 Swift 앱을 아이폰에 설치하는 방법입니다. 빌드는 GitHub의 macOS 러너에서 하고, 서명·설치는 Windows에서 Sideloadly(또는 AltStore)로 합니다. 무료 Apple ID 서명은 **7일 후 만료**되므로 같은 방법으로 다시 설치해야 합니다.

## 1. GitHub에 ios 폴더 올리기

`ios` 폴더 자체를 저장소 루트로 사용합니다. (`.github/workflows/build-ipa.yml`이 이미 들어 있습니다.)

```powershell
cd C:\ai\exam\ios
git init
git add .
git commit -m "ExamBank iOS app"
git branch -M main
git remote add origin https://github.com/<본인계정>/exambank-ios.git
git push -u origin main
```

공개 저장소는 macOS 러너 사용이 무료입니다. 비공개 저장소도 GitHub Free의 월 2,000분( macOS는 10배 가중이라 약 200분) 안에서 빌드할 수 있어 이 앱(1회 5~10분)에는 충분합니다.

## 2. GitHub Actions에서 IPA 받기

1. 저장소 → **Actions** → `Build unsigned IPA` → **Run workflow**
2. 5~10분 후 실행 결과 하단 **Artifacts**에서 `ExamBank-unsigned-ipa` 다운로드
3. 압축을 풀면 `ExamBank-unsigned.ipa`

## 3. Windows 준비

1. Microsoft Store에서 **Apple Devices** 설치 (iTunes 대체, 드라이버 포함)
2. [Sideloadly](https://sideloadly.io/) 설치
3. 아이폰을 USB로 연결하고 "이 컴퓨터를 신뢰" 선택

## 4. 서명 및 설치

1. Sideloadly 실행 → IPA에 `ExamBank-unsigned.ipa` 선택
2. Apple ID에 무료 Apple ID 입력 (2단계 인증 계정이면 앱 암호 사용)
3. **Start** → 로그인/2FA 진행
4. 완료되면 아이폰에 앱이 설치됩니다.

Sideloadly가 서명하면서 번들 ID를 자동으로 바꾸므로 충돌 없이 설치됩니다.

## 5. 아이폰 설정

1. 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 → 재부팅 (iOS 16+)
2. 설정 → 일반 → VPN 및 기기 관리 → 개발자 앱 → 본인 Apple ID → **신뢰**
3. 홈 화면에서 `PSAT 기출` 실행

## 6. 7일마다 갱신

무료 서명은 7일 후 앱이 열리지 않습니다. 다음 중 하나를 사용합니다.

- Sideloadly로 같은 IPA를 다시 설치
- AltStore(Windows용 AltServer) 설치 후 같은 Apple ID로 등록하면 Wi-Fi에서 자동 갱신

무료 계정 제약: 앱 3개, App ID 10개/7일, 푸시 알림·TestFlight·App Store 배포 불가.

## 문제가 생기면

- 빌드 실패: GitHub Actions 로그의 `xcodebuild` 오류 확인
- 설치 실패: Apple Devices 앱 설치 여부, 케이블, 아이폰 잠금 해제 상태 확인
- 실행 즉시 종료: 개발자 모드와 인증서 신뢰 설정 확인
- `manifest.json` 오류: `python tools/sync_ios_assets.py` 재실행 후 다시 push

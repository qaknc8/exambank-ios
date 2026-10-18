# ExamBank · 5급 PSAT 기출 풀이 (개인용 iOS 앱)

`questions/`의 문제은행(과목/연도별 JSON + 문제 이미지)을 아이폰에서 과목·연도·풀이 여부·북마크로 필터링하고, 한 문제씩 넘기며 푸는 SwiftUI 앱입니다. 정답·해설은 선택 사항이며 나중에 추가할 수 있습니다.

## 구성

```
ios/
  ExamBank.xcodeproj          # Xcode 프로젝트 (iOS 17+, iPhone/iPad)
  ExamBank/
    ExamBankApp.swift         # 앱 진입점, 스토어 주입
    RootView.swift            # 탭 구성, 로딩 오류 화면
    HomeView.swift            # 진행률, 이어풀기/안 푼 문제, 과목 진입
    QuestionBrowserView.swift # 검색 + 필터 목록, 문제 상세
    SessionView.swift         # 한 문제씩 풀이, 선택/완료/북마크
    ZoomableQuestionImage.swift # 핀치 줌 + 더블탭 확대 이미지 뷰어
    Models.swift              # Question, Manifest, BankFilter, StudySession
    BankStore.swift           # 번들 manifest/이미지 로딩
    ProgressStore.swift       # 완료/북마크/선택답/최근 문제 (UserDefaults)
    ImageLoader.swift         # 이미지 캐시
    Theme.swift               # 색/카드 스타일
    Assets.xcassets           # AppIcon, AccentColor
    Questions/                # sync_ios_assets.py가 생성 (manifest.json + images/)
tools/
  sync_ios_assets.py          # 문제은행 → iOS 번들 자산 변환
  make_app_icon.py            # 1024px 앱 아이콘 생성
answers/
  answers.example.json        # 정답·해설 형식 예시
```

`Questions/`는 생성물입니다. 문제은행이 바뀌면 아래 두 줄을 다시 실행한 뒤 Xcode에서 빌드하세요.

```powershell
python tools/build_question_bank.py
python tools/sync_ios_assets.py
```

## 빌드 (Mac + Xcode 필요)

Mac이 없다면 [INSTALL-WINDOWS.md](INSTALL-WINDOWS.md)의 GitHub Actions + Sideloadly 방법으로 무료 Apple ID에 설치할 수 있습니다.

1. `ios/ExamBank.xcodeproj`를 Xcode로 엽니다.
2. 대상 `ExamBank` → Signing & Capabilities에서 본인 Apple ID의 Personal Team을 선택합니다.
3. `PRODUCT_BUNDLE_IDENTIFIER`(현재 `com.example.ExamBank`)를 본인만의 값으로 바꿉니다.
4. 아이폰을 연결하고 Run(⌘R). 무료 계정 서명은 7일마다 다시 설치해야 합니다.
5. 시뮬레이터에서도 동작합니다.

## 기능

- 홈: 전체 진행률, 이어서 풀기, 안 푼 문제부터 풀기, 최근 본 문제, 과목별 진행률
- 문제 탭: 과목/연도 칩, 안 푼 문제·북마크 토글, 내용 검색(과목·연도·본문·보기), 목록에서 바로 풀이 시작
- 풀이 화면: 문제 이미지 핀치 줌/더블탭 확대, ①~⑤ 선택, 완료 표시, 북마크, 이전/다음, 좌우 스와이프 없이 버튼 이동
- 설정: 학습 기록 초기화, 문제은행 통계

모든 기록은 기기 로컬(`UserDefaults`)에만 저장됩니다. 네트워크나 서버는 사용하지 않습니다.

## 정답·해설 추가

`answers/answers.json`을 만들고 문제 id를 키로 사용합니다. 값은 1~5(①~⑤) 또는 객체입니다.

```json
{
  "2005-5급-언어논리-2책형-01": 3,
  "2005-5급-언어논리-2책형-02": {
    "answer": 5,
    "explanation": "정답 해설..."
  }
}
```

그다음 `python tools/sync_ios_assets.py`를 실행하면 manifest에 반영되고, 풀이 화면에 정답/해설 버튼이 나타납니다. 문제 id는 `questions/index.json`의 `id`와 같습니다. 존재하지 않는 id는 경고만 출력합니다.

## 문제은행 참고

- 원본 PDF: `pdf/<과목>/*.pdf` (110개)
- 생성 결과: `questions/<과목>/<연도>/<연도>_<급수>_<책형>_NN.webp` + `index.json`
- 현재 3,680문항(110개 시험, 2006–2025), 총 이미지 약 318MB (WebP)
- 스크립트는 각자 파일 위치를 기준으로 `pdf/`, `questions/`, `answers/`를 찾으므로 경로 수정 없이 실행할 수 있습니다.

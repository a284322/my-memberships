# 내 구독 · My Memberships

노랑·연두 테마의 iPhone / Android 구독·멤버십 관리 앱입니다. 현재 테스트 버전은 **1.0.1**입니다.

## Android에서 바로 사용하기

1. [최신 Releases](https://github.com/a284322/my-memberships/releases/latest)에서 `MyMemberships-Android-1.0.1.apk`를 받습니다.
2. 휴대폰에서 파일을 열어 설치합니다. Android가 요청하면 다운로드에 사용한 브라우저 또는 파일 앱에 대해 '이 출처에서 앱 설치'를 허용합니다.
3. `내 구독` 앱을 열고 본인의 서비스와 실제 결제 금액·다음 결제일을 등록합니다.
4. 결제 알림이 필요하면 앱의 종 아이콘에서 설정합니다.

Android **8.0 이상**을 대상으로 합니다. Android 13 삼성 실기기에서 핵심 테스트 11개를 통과했습니다. 모든 기종의 성능과 장시간 절전 알림을 보장하지는 않습니다. 무료 테스트 앱이며 은행·카드 연결과 자동 해지는 없습니다.

공개 테스트판은 별도 패키지 `com.example.mymemberships`를 사용합니다. 다른 개발판의 저장 기록을 자동으로 가져오지 않습니다. 설치 파일은 테스트 전용 서명이며 Google Play 게시용 배포가 아닙니다. Play Protect 등의 확인 화면은 내용을 읽고 사용자가 직접 판단해 주세요.

## 기능

- 서비스 97개 이름·분류 검색과 직접 등록
- 월·연 환산 비용, 이번 달 결제 예정액, 가까운 결제일 순 목록
- 구독 수정과 다음 결제일 바로 변경
- 무료체험·할인 종료일, 이후 금액과 적용일 기록
- 전체·구독별 결제 전 알림, 알림에서 해당 상세로 이동
- 공식 서비스 페이지·간결한 멤버십 혜택 확인과 비교
- 기기 내 사진·PDF 영수증 인식, 확인 후 등록
- 기기 내 저장. 계정 간·기기 간 자동 동기화 없음

## iPhone에서 사용하기

공개 소스만 내려받아 iPhone에 바로 설치할 수는 없습니다. macOS와 Xcode, 본인의 Apple 개발용 서명이 필요합니다.

1. `SubscriptionTracker/SubscriptionTracker.xcodeproj`를 Xcode에서 엽니다.
2. Signing & Capabilities에서 본인의 Team과 고유 Bundle Identifier를 선택합니다.
3. iOS 17 이상 시뮬레이터 또는 본인의 개발 기기로 빌드합니다.

다른 사람에게 일반 설치 방식으로 배포하려면 별도의 TestFlight/App Store 준비가 필요합니다.

## Android 소스 빌드

JDK 17, Android SDK 35를 준비하고 `ANDROID_HOME` 또는 로컬 `local.properties`로 SDK 경로를 지정합니다.

```sh
cd AndroidSubscriptionTracker
./gradlew testDebugUnitTest assembleDebug
# 연결된 테스트 기기에서 별도 테스트 저장소 사용
./gradlew connectedDebugAndroidTest
```

또는 Android Studio에서 `AndroidSubscriptionTracker` 폴더를 엽니다. Gradle wrapper 8.9가 포함되어 있습니다. 빌드 결과는 `app/build/outputs/apk/debug/app-debug.apk`입니다. 직접 빌드한 APK는 서명이 다를 수 있어 배포 APK 위에 업데이트 설치되지 않을 수 있습니다.

## iPhone 모델 검사

```sh
python3 SubscriptionTracker/Tools/run_checks.py
```

## 데이터와 알려진 제한

[데이터 처리 안내](PRIVACY.md)를 확인해 주세요. 가격과 혜택은 카탈로그의 출처·확인일 기준 참고 자료이며 실제 가입 조건과 다를 수 있습니다. 저장한 금액은 카탈로그 변경으로 자동 수정하지 않습니다. 환산 비용과 결제 예정액은 실제 카드 지출 내역이 아닙니다.

알림은 운영체제 절전·강제 종료 정책의 영향을 받습니다. iPhone은 반복이 안전한 일정에 반복 알림을 사용하며 월말·체험·요금 변경 등은 일회성 예약을 사용합니다. 예약이 부족하다는 안내가 있으면 앱을 열어 갱신해야 합니다.

영수증 인식 결과는 틀릴 수 있어 저장 전 확인해야 합니다. PDF 앞 5쪽, 최대 25MB를 지원합니다. 같은 영수증을 여러 번 등록하면 기록이 중복될 수 있습니다.

서비스 이름·로고와 공식 안내의 권리는 각 권리자에게 있습니다. [제3자 자산 출처](THIRD_PARTY_ASSETS.md)를 참고하세요. 서비스 제공업체와 제휴된 앱이 아닙니다.

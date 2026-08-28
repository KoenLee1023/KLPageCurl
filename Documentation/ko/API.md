# API

## 공개 타입

`KLPageCurlSurface<ID>`는 논리 항목의 앞면 또는 뒷면을 나타냅니다. `KLPageCurlSequence`는 초기 항목과 인접 항목을 제공하고 `KLFinitePageCurlSequence`는 유한한 순서 컬렉션을 연결합니다. 순서와 끝 처리는 sequence가 담당합니다.

`KLPageCurlStateMachine`이 전환 상태를 관리합니다. 시작에는 `beginTransition(to:)`, 화면이 안정된 뒤에는 `finishTransition`, 논리 중심을 바꿀 때는 `recenter`를 호출합니다. `KLPageCurlTransitionOutcome`으로 진행 중인 전환과 확정된 surface를 구분합니다.

`KLPageCurlConfiguration`은 모션과 캐시 정책을 묶습니다. `KLPageCurlPresentation.resolve(for:)`는 동작 줄이기 설정을 반영해 `staticPager` 같은 표시 방식을 선택합니다. `KLPageCurlPager`는 SwiftUI와 UIKit을 연결하며 콘텐츠 생성은 앱이 담당합니다.

`KLPageCurlCacheConfiguration.logicalRadius`는 유지할 이웃 범위를 제한합니다. `plan(around:sequence:cachedSurfaces:)`는 유지, 미리 로드, 제거 대상을 반환합니다. `KLPageCurlRevisionIndex`의 `record(_:for:)`와 `decision(for:currentRevision:)`을 사용하면 바뀌지 않은 surface를 다시 만들지 않을 수 있습니다. 제거 후에는 `applyEvictions(from:)`을 호출합니다.

`KLPageCurlAccessibility`에는 항목별 레이블, 값, 동작 이름과 확정 안내 문구를 전달합니다. 제품별 문구는 호스트가 제공합니다.

`KLPageCurl`은 앞면과 뒷면을 가진 논리 페이지 순서를 모델링하고 iOS에서 SwiftUI와 UIKit으로 표시합니다.

`KLPageCurlSurface`는 페이지의 `front` 또는 `back`을 식별합니다. `KLPageCurlSequence`가 초기 면과 인접 면을 제공하고 `KLFinitePageCurlSequence`가 유한한 순서를 구현합니다. `KLPageCurlStateMachine`은 `beginTransition(to:)`, `finishTransition`, `recenter`로 선택과 전환을 관리합니다.

`KLPageCurlConfiguration`은 `KLPageCurlMotionPolicy`와 캐시 동작을 묶습니다. `KLPageCurlPresentation.resolve(for:)`는 reduced motion을 `staticPager`로 해석합니다. `KLPageCurlPager`는 `KLPageCurlViewController`를 연결하는 SwiftUI 계층입니다.

`KLPageCurlRevisionIndex`는 `KLPageCurlRefreshDecision`을 반환해 변경된 면만 갱신할 수 있게 합니다. 콘텐츠, 영속화, 리비전 생성, 이미지 로딩은 호스트가 담당합니다.

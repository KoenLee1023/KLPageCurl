# ``KLPageCurl``

> [English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)

KLPageCurl은 양면 페이지 순서를 모델링하고 iOS에서 페이지 컬 보기를 제공합니다.

각 논리 항목은 `front(id)`, `back(id)` 순서로 표시됩니다. 뒷면에서 다음으로
이동하면 `front(nextID)`에 도달하며 반대 방향은 이 순서를 거꾸로 따릅니다. 유한
시퀀스는 첫 앞면의 이전과 마지막 뒷면의 다음에서 `nil`을 반환합니다. 선택 값은
앞면에 완전히 정착했을 때만 바뀝니다. 뒷면 정착도 `onSettled`를 호출하지만 새
선택 값을 쓰지는 않습니다.

프로그래밍 방식으로 선택을 바꾸면 대기 중인 페이저는 `initialSurface(for:)`로
초기 표면을 선택합니다. 보통은 선택한 항목의 앞면이지만, 이는 시퀀스 정책이
정하며 상태 머신은 그 표면을 한 번에 받아들입니다. 전환 중인 요청은 무시됩니다.
캐시 반경은 논리 항목 수로 계산하고 범위 안의 앞뒷면을 모두 유지합니다.
기본 반경은 1입니다. 리비전은 표면별로 구분됩니다. 내용이 바뀐 표면만 대기
상태에서 다시 불러오며 전환 중에는 새로 고침을 미룹니다.

대화형 뒤로 가기 인식기와 가장자리 정책은 내비게이션 호스트가 소유합니다. 페이지
제스처는 전달받은 뒤로 가기 인식기가 실패할 때까지 기다릴 뿐입니다. 동작 줄이기가
필요하면 `reducedMotion`을 전달해 선택한 항목의 초기 표면을 정적으로 표시합니다.
`KLPageCurlAccessibility` 문구를 제공하면 VoiceOver와 스위치 제어에서 조절
동작과 이름이 있는 이전, 다음 동작을 사용할 수 있습니다. 페이지 안의 컨트롤도
계속 접근할 수 있습니다.

`BookPreviewDemo`는 유한한 책을 보여 줍니다. `PhotoAlbumDemo`는 편집 가능한
콘텐츠와 앞뒷면별 리비전을 보여 줍니다. 컬 보기는 iOS 17 이상이 필요합니다.
시퀀스, 상태 머신, 캐시, 리비전, 모션, 손쉬운 사용 모델은 macOS 14 이상에서
사용할 수 있지만 macOS에는 컬 보기가 없습니다.

## 주제

- ``KLPageCurlSurface``
- ``KLPageCurlSequence``
- ``KLPageCurlStateMachine``
- ``KLPageCurlCacheConfiguration``
- ``KLPageCurlRevisionIndex``
- ``KLPageCurlAccessibility``
- ``KLPageCurlDirection``
- ``KLFinitePageCurlSequence``
- ``KLPageCurlTransitionState``
- ``KLPageCurlTransitionOutcome``
- ``KLPageCurlCachePlan``
- ``KLPageCurlRefreshDecision``
- ``KLPageCurlConfiguration``
- ``KLPageCurlMotionPolicy``
- ``KLPageCurlPresentation``

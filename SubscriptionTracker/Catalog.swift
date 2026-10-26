import Foundation

struct CatalogPlan: Identifiable, Decodable {
    var id: String { name + channel + currency + String(yearly) }
    let name: String
    let amount: Double
    let channel: String
    let currency: String
    let yearly: Bool
    let sourceURL: String?
    let checkedAt: String?
    let conditions: String?
}

struct CatalogService: Identifiable, Decodable {
    let id: String
    let name: String
    let displayName: String
    let category: String
    let aliases: [String]
    let source: String
    let note: String
    let plans: [CatalogPlan]
    let membership: CatalogMembership?

    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || ([name, displayName, category] + aliases).contains { $0.localizedStandardContains(query) }
    }

    static let all: [CatalogService] = {
        // Generated from Research/subscription-services-v3.json. Invalid bundled data is an implementation error.
        let json = #"""
[
  {
    "id": "service-001",
    "name": "YouTube Premium",
    "displayName": "YouTube Premium (유튜브)",
    "category": "영상·OTT",
    "aliases": [
      "유튜브",
      "유튜브 프리미엄"
    ],
    "source": "https://www.youtube.com/premium",
    "note": "음악 혜택이 포함된 플랜이라면 YouTube Music을 별도 결제하는지 확인해 주세요.",
    "plans": [
      {
        "name": "Premium",
        "amount": 14900,
        "channel": "웹·Android",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "Premium",
        "amount": 19500,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "Premium Lite",
        "amount": 8500,
        "channel": "웹·Android",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "Premium Lite",
        "amount": 10900,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "service-001-feature-1",
          "title": "광고 없이 동영상 시청",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-001-feature-2",
          "title": "오프라인 저장",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-001-feature-3",
          "title": "백그라운드 재생",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-001-feature-4",
          "title": "YouTube Music 포함",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://support.google.com/youtube/answer/6308116?hl=ko",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      },
      "managementPage": {
        "url": "https://www.youtube.com/paid_memberships",
        "directions": "로그인 → 멤버십 관리에서 다음 청구일·무료체험 종료일을 확인하세요.",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-002",
    "name": "Netflix",
    "displayName": "Netflix (넷플릭스)",
    "category": "영상·OTT",
    "aliases": [
      "넷플릭스"
    ],
    "source": "https://help.netflix.com/ko/node/24926",
    "note": "",
    "plans": [
      {
        "name": "광고형 스탠다드",
        "amount": 7000,
        "channel": "공식 요금",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "스탠다드",
        "amount": 13500,
        "channel": "공식 요금",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "프리미엄",
        "amount": 17000,
        "channel": "공식 요금",
        "currency": "KRW",
        "yearly": false
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "service-002-feature-1",
          "title": "영화·시리즈 스트리밍",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://help.netflix.com/ko/node/24926",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-002-feature-2",
          "title": "콘텐츠 다운로드",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://help.netflix.com/ko/node/24926",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://help.netflix.com/ko/node/24926",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      },
      "managementPage": {
        "url": "https://www.netflix.com/BillingActivity",
        "directions": "로그인 후 결제 내역 상단에서 청구일을 확인하세요.",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-003",
    "name": "쿠팡플레이",
    "displayName": "쿠팡플레이 (Coupang Play)",
    "category": "영상·OTT",
    "aliases": [
      "Coupang Play"
    ],
    "source": "https://www.coupangplay.com/",
    "note": "와우 멤버십과 별도 패스를 구분해 실제 결제 금액을 입력해 주세요.",
    "plans": [],
    "membership": null
  },
  {
    "id": "service-004",
    "name": "TVING",
    "displayName": "TVING (티빙)",
    "category": "영상·OTT",
    "aliases": [
      "티빙"
    ],
    "source": "https://www.tving.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-004-feature-1",
          "title": "드라마·예능·영화",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://www.tving.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-004-feature-2",
          "title": "라이브 스포츠",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.tving.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.tving.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-005",
    "name": "Wavve",
    "displayName": "Wavve (웨이브)",
    "category": "영상·OTT",
    "aliases": [
      "웨이브"
    ],
    "source": "https://www.wavve.com/",
    "note": "",
    "plans": [],
    "membership": null
  },
  {
    "id": "service-006",
    "name": "Disney+",
    "displayName": "Disney+ (디즈니플러스)",
    "category": "영상·OTT",
    "aliases": [
      "디즈니플러스"
    ],
    "source": "https://www.disneyplus.com/ko-kr",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-006-feature-1",
          "title": "디즈니·픽사·마블 콘텐츠",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://www.disneyplus.com/ko-kr",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-006-feature-2",
          "title": "독점 오리지널",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.disneyplus.com/ko-kr",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.disneyplus.com/ko-kr",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-007",
    "name": "Apple TV",
    "displayName": "Apple TV (애플티비)",
    "category": "영상·OTT",
    "aliases": [
      "애플티비",
      "Apple TV+"
    ],
    "source": "https://www.apple.com/kr/apple-tv/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-007-feature-1",
          "title": "Apple Original 콘텐츠",
          "category": "video",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-tv/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-007-feature-2",
          "title": "광고 없는 시청",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.apple.com/kr/apple-tv/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.apple.com/kr/apple-tv/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-008",
    "name": "WATCHA",
    "displayName": "WATCHA (왓챠)",
    "category": "영상·OTT",
    "aliases": [
      "왓챠"
    ],
    "source": "https://watcha.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-008-feature-1",
          "title": "영화·드라마 감상",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://watcha.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://watcha.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-009",
    "name": "라프텔",
    "displayName": "라프텔 (Laftel)",
    "category": "영상·OTT",
    "aliases": [
      "Laftel"
    ],
    "source": "https://laftel.net/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-009-feature-1",
          "title": "애니메이션 스트리밍",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://laftel.net/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://laftel.net/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-010",
    "name": "SPOTV NOW",
    "displayName": "SPOTV NOW (스포티비 나우)",
    "category": "영상·OTT",
    "aliases": [
      "스포티비 나우"
    ],
    "source": "https://www.spotvnow.co.kr/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-010-feature-1",
          "title": "스포츠 생중계",
          "category": "video",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.spotvnow.co.kr/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.spotvnow.co.kr/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-011",
    "name": "YouTube Music",
    "displayName": "YouTube Music (유튜브 뮤직)",
    "category": "음악 감상",
    "aliases": [
      "유튜브 뮤직"
    ],
    "source": "https://music.youtube.com/",
    "note": "YouTube Premium에 포함된 혜택이라면 중복 등록하지 않아도 돼요.",
    "plans": [
      {
        "name": "Music Premium",
        "amount": 11990,
        "channel": "웹·Android",
        "currency": "KRW",
        "yearly": false
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "service-011-feature-1",
          "title": "광고 없는 음악",
          "category": "music",
          "conditions": "",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-011-feature-2",
          "title": "오프라인 저장",
          "category": "music",
          "conditions": "",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-011-feature-3",
          "title": "백그라운드 재생",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://support.google.com/youtube/answer/6308116?hl=ko",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://support.google.com/youtube/answer/6308116?hl=ko",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      },
      "managementPage": {
        "url": "https://www.youtube.com/paid_memberships",
        "directions": "로그인 → 멤버십 관리에서 다음 청구일을 확인하세요.",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-012",
    "name": "멜론",
    "displayName": "멜론 (Melon)",
    "category": "음악 감상",
    "aliases": [
      "Melon"
    ],
    "source": "https://www.melon.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-012-feature-1",
          "title": "음악 감상·맞춤 추천",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.melon.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.melon.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-013",
    "name": "Spotify",
    "displayName": "Spotify (스포티파이)",
    "category": "음악 감상",
    "aliases": [
      "스포티파이"
    ],
    "source": "https://www.spotify.com/kr-ko/premium/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-013-feature-1",
          "title": "광고 없는 음악",
          "category": "music",
          "conditions": "",
          "sourceURL": "https://www.spotify.com/kr-ko/premium/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-013-feature-2",
          "title": "원하는 순서로 재생",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.spotify.com/kr-ko/premium/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.spotify.com/kr-ko/premium/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-014",
    "name": "지니뮤직",
    "displayName": "지니뮤직 (Genie)",
    "category": "음악 감상",
    "aliases": [
      "Genie"
    ],
    "source": "https://www.genie.co.kr/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-014-feature-1",
          "title": "음악 감상·AI 추천",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.genie.co.kr/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.genie.co.kr/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-015",
    "name": "FLO",
    "displayName": "FLO (플로)",
    "category": "음악 감상",
    "aliases": [
      "플로"
    ],
    "source": "https://www.music-flo.com/",
    "note": "",
    "plans": [],
    "membership": null
  },
  {
    "id": "service-016",
    "name": "Apple Music",
    "displayName": "Apple Music (애플뮤직)",
    "category": "음악 감상",
    "aliases": [
      "애플뮤직"
    ],
    "source": "https://www.apple.com/kr/apple-music/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-016-feature-1",
          "title": "광고 없는 음악",
          "category": "music",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-music/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-016-feature-2",
          "title": "오프라인 감상",
          "category": "music",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-music/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-016-feature-3",
          "title": "공간 음향",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.apple.com/kr/apple-music/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.apple.com/kr/apple-music/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-017",
    "name": "VIBE",
    "displayName": "VIBE (바이브)",
    "category": "음악 감상",
    "aliases": [
      "바이브"
    ],
    "source": "https://vibe.naver.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-017-feature-1",
          "title": "취향 맞춤 음악 추천",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://vibe.naver.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://vibe.naver.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-018",
    "name": "벅스",
    "displayName": "벅스 (Bugs)",
    "category": "음악 감상",
    "aliases": [
      "Bugs"
    ],
    "source": "https://music.bugs.co.kr/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-018-feature-1",
          "title": "음악·플레이리스트 추천",
          "category": "music",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://music.bugs.co.kr/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://music.bugs.co.kr/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-019",
    "name": "ChatGPT",
    "displayName": "ChatGPT (챗지피티)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "챗지피티",
      "챗GPT"
    ],
    "source": "https://apps.apple.com/kr/app/chatgpt/id6448311069",
    "note": "",
    "plans": [
      {
        "name": "Go",
        "amount": 13000,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "Plus",
        "amount": 29000,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "service-019-feature-1",
          "title": "AI 대화·파일 분석",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://chatgpt.com/pricing/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-019-feature-2",
          "title": "이미지 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://chatgpt.com/pricing/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://chatgpt.com/pricing/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      },
      "managementPage": {
        "url": "https://chatgpt.com/",
        "directions": "로그인 → 설정 → Billing에서 구독 정보를 확인하세요.",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-020",
    "name": "Gemini",
    "displayName": "Gemini (제미나이)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "제미나이",
      "Google AI"
    ],
    "source": "https://one.google.com/intl/ko_kr/about/google-ai-plans/",
    "note": "Google One 저장 공간이 포함된 플랜인지 확인해 주세요.",
    "plans": [
      {
        "name": "Google AI Plus",
        "amount": 7500,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      },
      {
        "name": "Google AI Pro",
        "amount": 29000,
        "channel": "App Store",
        "currency": "KRW",
        "yearly": false
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "service-020-feature-1",
          "title": "Gemini AI 도구",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://one.google.com/intl/ko_kr/about/google-ai-plans/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-020-feature-2",
          "title": "클라우드 저장 공간",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://one.google.com/intl/ko_kr/about/google-ai-plans/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://one.google.com/intl/ko_kr/about/google-ai-plans/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-021",
    "name": "Claude",
    "displayName": "Claude (클로드)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "클로드"
    ],
    "source": "https://claude.com/pricing",
    "note": "Claude Code 이용료가 현재 요금제에 포함되는지 확인해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-021-feature-1",
          "title": "Claude AI 대화",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://claude.com/pricing",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-021-feature-2",
          "title": "코딩·프로젝트 도구",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://claude.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://claude.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-022",
    "name": "Perplexity",
    "displayName": "Perplexity (퍼플렉시티)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "퍼플렉시티"
    ],
    "source": "https://www.perplexity.ai/pro",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-022-feature-1",
          "title": "AI 검색·심층 리서치",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.perplexity.ai/pro",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-022-feature-2",
          "title": "파일 업로드",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.perplexity.ai/pro",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.perplexity.ai/pro",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-062",
    "name": "Genspark",
    "displayName": "젠스파크 (Genspark)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "젠스파크"
    ],
    "source": "https://www.genspark.ai/helpcenter/membership-plans",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-062-feature-0",
          "title": "AI 문서·슬라이드·시트",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.genspark.ai/helpcenter/membership-plans",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-062-feature-1",
          "title": "AI 작업 도구",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.genspark.ai/helpcenter/membership-plans",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.genspark.ai/helpcenter/membership-plans",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-063",
    "name": "Manus",
    "displayName": "마누스 (Manus)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "마누스"
    ],
    "source": "https://manus.im/tools",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-063-feature-1",
          "title": "AI 작업 자동화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://manus.im/tools",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://manus.im/tools",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-023",
    "name": "Grok",
    "displayName": "Grok (그록)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "그록"
    ],
    "source": "https://x.ai/grok",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-023-feature-0",
          "title": "AI 대화·실시간 검색",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://x.ai/grok",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-023-feature-1",
          "title": "이미지·영상 생성",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://x.ai/grok",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://x.ai/grok",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-024",
    "name": "Microsoft Copilot",
    "displayName": "Microsoft Copilot (코파일럿)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "코파일럿"
    ],
    "source": "https://www.microsoft.com/ko-kr/microsoft-365/buy/compare-all-microsoft-365-products",
    "note": "Microsoft 365 구독에 포함된 혜택인지 확인해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-024-feature-0",
          "title": "Copilot AI 지원",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.microsoft.com/ko-kr/microsoft-365",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-024-feature-1",
          "title": "문서·데이터 분석",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.microsoft.com/ko-kr/microsoft-365",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.microsoft.com/ko-kr/microsoft-365",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-025",
    "name": "Poe",
    "displayName": "Poe (포)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "포"
    ],
    "source": "https://poe.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-025-feature-0",
          "title": "다양한 AI 모델 대화",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://poe.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://poe.com/",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-077",
    "name": "Monica",
    "displayName": "Monica (모니카)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "모니카"
    ],
    "source": "https://monica.im/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-077-feature-1",
          "title": "AI 대화 도구",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://monica.im/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://monica.im/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-078",
    "name": "Felo",
    "displayName": "Felo (펠로)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "펠로"
    ],
    "source": "https://felo.ai/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-078-feature-1",
          "title": "다국어 AI 검색",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://felo.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-078-feature-2",
          "title": "슬라이드·문서 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://felo.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://felo.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-079",
    "name": "Kimi",
    "displayName": "Kimi (키미)",
    "category": "AI 대화·검색·에이전트",
    "aliases": [
      "키미"
    ],
    "source": "https://www.kimi.com/membership/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-079-feature-1",
          "title": "AI 코딩·심층 리서치",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.kimi.com/membership/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.kimi.com/membership/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-026",
    "name": "Canva",
    "displayName": "Canva (캔바)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "캔바"
    ],
    "source": "https://www.canva.com/pricing/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-026-feature-1",
          "title": "디자인·발표 자료 제작",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.canva.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-026-feature-2",
          "title": "사진·영상 편집",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.canva.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.canva.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-027",
    "name": "Midjourney",
    "displayName": "Midjourney (미드저니)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "미드저니"
    ],
    "source": "https://www.midjourney.com/plans",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-027-feature-1",
          "title": "AI 이미지·영상 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.midjourney.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.midjourney.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-028",
    "name": "Adobe Firefly",
    "displayName": "Adobe Firefly (어도비 파이어플라이)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "어도비 파이어플라이"
    ],
    "source": "https://www.adobe.com/kr/products/firefly/plans.html",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-028-feature-0",
          "title": "AI 이미지·영상 생성",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.adobe.com/kr/products/firefly.html",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-028-feature-1",
          "title": "사진 편집·배경 제거",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.adobe.com/kr/products/firefly.html",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.adobe.com/kr/products/firefly.html",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-029",
    "name": "Leonardo.Ai",
    "displayName": "Leonardo.Ai (레오나르도)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "레오나르도"
    ],
    "source": "https://leonardo.ai/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-029-feature-1",
          "title": "AI 이미지 생성·편집",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://leonardo.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-029-feature-2",
          "title": "이미지 영상화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://leonardo.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://leonardo.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-030",
    "name": "Ideogram",
    "displayName": "Ideogram (이디오그램)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "이디오그램"
    ],
    "source": "https://ideogram.ai/pricing/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-030-feature-0",
          "title": "AI 이미지 생성·편집",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://ideogram.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://ideogram.ai/",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-031",
    "name": "Krea",
    "displayName": "Krea (크레아)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "크레아"
    ],
    "source": "https://www.krea.ai/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-031-feature-1",
          "title": "AI 창작 도구·크레딧",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.krea.ai/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.krea.ai/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-032",
    "name": "Magnific",
    "displayName": "Magnific (Freepik)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "Freepik",
      "프리픽",
      "매그니픽"
    ],
    "source": "https://www.magnific.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-032-feature-1",
          "title": "AI 디자인 도구",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.magnific.com/pricing",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-032-feature-2",
          "title": "프리미엄 콘텐츠",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.magnific.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.magnific.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-033",
    "name": "Photoroom",
    "displayName": "Photoroom (포토룸)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "포토룸"
    ],
    "source": "https://www.photoroom.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-033-feature-1",
          "title": "배경 제거·교체",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.photoroom.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-033-feature-2",
          "title": "상품 사진 편집",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.photoroom.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.photoroom.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-034",
    "name": "Picsart",
    "displayName": "Picsart (픽스아트)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "픽스아트"
    ],
    "source": "https://picsart.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-034-feature-1",
          "title": "AI 디자인·템플릿",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://picsart.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://picsart.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-083",
    "name": "Figma",
    "displayName": "Figma (피그마)",
    "category": "AI 이미지·디자인",
    "aliases": [
      "피그마"
    ],
    "source": "https://www.figma.com/pricing/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-083-feature-1",
          "title": "디자인·프로토타입",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.figma.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-083-feature-2",
          "title": "팀 협업",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.figma.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.figma.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-035",
    "name": "CapCut",
    "displayName": "CapCut (캡컷)",
    "category": "AI 영상·편집",
    "aliases": [
      "캡컷"
    ],
    "source": "https://www.capcut.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-035-feature-1",
          "title": "영상 편집·효과",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.capcut.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-035-feature-2",
          "title": "AI 편집 도구",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.capcut.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.capcut.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-036",
    "name": "Runway",
    "displayName": "Runway (런웨이)",
    "category": "AI 영상·편집",
    "aliases": [
      "런웨이"
    ],
    "source": "https://runway.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-036-feature-1",
          "title": "AI 영상 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://runway.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://runway.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-037",
    "name": "Kling AI",
    "displayName": "Kling AI (클링)",
    "category": "AI 영상·편집",
    "aliases": [
      "클링"
    ],
    "source": "https://klingai.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-037-feature-1",
          "title": "AI 영상·이미지 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://klingai.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://klingai.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-038",
    "name": "HeyGen",
    "displayName": "HeyGen (헤이젠)",
    "category": "AI 영상·편집",
    "aliases": [
      "헤이젠"
    ],
    "source": "https://www.heygen.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-038-feature-1",
          "title": "AI 영상 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.heygen.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.heygen.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-039",
    "name": "Pika",
    "displayName": "Pika (피카)",
    "category": "AI 영상·편집",
    "aliases": [
      "피카"
    ],
    "source": "https://pika.art/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-039-feature-1",
          "title": "영상·이미지·오디오 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://pika.art/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://pika.art/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-040",
    "name": "Luma",
    "displayName": "Luma (루마)",
    "category": "AI 영상·편집",
    "aliases": [
      "루마",
      "Dream Machine"
    ],
    "source": "https://lumalabs.ai/pricing",
    "note": "",
    "plans": [],
    "membership": null
  },
  {
    "id": "service-041",
    "name": "Vrew",
    "displayName": "Vrew (브루)",
    "category": "AI 영상·편집",
    "aliases": [
      "브루"
    ],
    "source": "https://vrew.ai/ko/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-041-feature-1",
          "title": "자동 자막",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://vrew.ai/ko/pricing",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-041-feature-2",
          "title": "AI 영상 편집",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://vrew.ai/ko/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://vrew.ai/ko/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-042",
    "name": "Synthesia",
    "displayName": "Synthesia (신시아)",
    "category": "AI 영상·편집",
    "aliases": [
      "신시아",
      "신세시아"
    ],
    "source": "https://www.synthesia.io/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-042-feature-1",
          "title": "AI 아바타 영상",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.synthesia.io/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-042-feature-2",
          "title": "영상 번역·더빙",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.synthesia.io/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.synthesia.io/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-043",
    "name": "Descript",
    "displayName": "Descript (디스크립트)",
    "category": "AI 영상·편집",
    "aliases": [
      "디스크립트"
    ],
    "source": "https://www.descript.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-043-feature-1",
          "title": "영상·팟캐스트 편집",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.descript.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.descript.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-044",
    "name": "Higgsfield",
    "displayName": "Higgsfield (힉스필드)",
    "category": "AI 영상·편집",
    "aliases": [
      "힉스필드"
    ],
    "source": "https://higgsfield.ai/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-044-feature-1",
          "title": "AI 이미지·영상·음성",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://higgsfield.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-044-feature-2",
          "title": "미디어 편집·업스케일",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://higgsfield.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://higgsfield.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-045",
    "name": "Suno",
    "displayName": "Suno (수노)",
    "category": "AI 음악 제작",
    "aliases": [
      "수노"
    ],
    "source": "https://suno.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-045-feature-1",
          "title": "AI 음악 생성",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://suno.com/pricing",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-045-feature-2",
          "title": "상업적 이용 권한",
          "category": "other",
          "conditions": "유료 구독 중 생성한 곡·약관 적용",
          "sourceURL": "https://suno.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://suno.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-047",
    "name": "Udio",
    "displayName": "Udio (유디오)",
    "category": "AI 음악 제작",
    "aliases": [
      "유디오"
    ],
    "source": "https://www.udio.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-047-feature-1",
          "title": "AI 음악 생성",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.udio.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.udio.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-049",
    "name": "Moises",
    "displayName": "Moises (모이세스)",
    "category": "AI 음악 제작",
    "aliases": [
      "모이세스"
    ],
    "source": "https://moises.ai/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-049-feature-1",
          "title": "보컬·악기 분리",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://moises.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-049-feature-2",
          "title": "AI 마스터링",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://moises.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://moises.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-085",
    "name": "AIVA",
    "displayName": "AIVA (아이바)",
    "category": "AI 음악 제작",
    "aliases": [
      "아이바"
    ],
    "source": "https://www.aiva.ai/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-085-feature-1",
          "title": "AI 작곡",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.aiva.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.aiva.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-086",
    "name": "SOUNDRAW",
    "displayName": "SOUNDRAW (사운드로우)",
    "category": "AI 음악 제작",
    "aliases": [
      "사운드로우"
    ],
    "source": "https://soundraw.io/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-086-feature-1",
          "title": "AI 음악 생성·편집",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://soundraw.io/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://soundraw.io/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-046",
    "name": "ElevenLabs",
    "displayName": "일레븐랩스 (ElevenLabs)",
    "category": "AI 음성·더빙·낭독",
    "aliases": [
      "일레븐랩스"
    ],
    "source": "https://elevenlabs.io/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-046-feature-1",
          "title": "AI 음성 생성",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://elevenlabs.io/pricing",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-046-feature-2",
          "title": "음성 복제·더빙",
          "category": "other",
          "conditions": "플랜별 제공 기능 상이",
          "sourceURL": "https://elevenlabs.io/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://elevenlabs.io/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-048",
    "name": "Speechify",
    "displayName": "Speechify (스피치파이)",
    "category": "AI 음성·더빙·낭독",
    "aliases": [
      "스피치파이"
    ],
    "source": "https://speechify.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-048-feature-1",
          "title": "문서·웹페이지 읽어주기",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://speechify.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://speechify.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-087",
    "name": "Typecast",
    "displayName": "Typecast (타입캐스트)",
    "category": "AI 음성·더빙·낭독",
    "aliases": [
      "타입캐스트"
    ],
    "source": "https://typecast.ai/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-087-feature-1",
          "title": "AI 보이스·더빙",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://typecast.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://typecast.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-050",
    "name": "GitHub Copilot",
    "displayName": "GitHub Copilot (깃허브 코파일럿)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "깃허브 코파일럿"
    ],
    "source": "https://github.com/features/copilot/plans",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-050-feature-1",
          "title": "AI 코딩 에이전트",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://github.com/features/copilot/plans",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://github.com/features/copilot/plans",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-051",
    "name": "Cursor",
    "displayName": "Cursor (커서)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "커서"
    ],
    "source": "https://cursor.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-051-feature-1",
          "title": "AI 코딩 지원",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://cursor.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://cursor.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-052",
    "name": "Replit",
    "displayName": "Replit (레플릿)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "레플릿"
    ],
    "source": "https://replit.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-052-feature-1",
          "title": "AI 앱 제작·협업",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://replit.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://replit.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-053",
    "name": "Lovable",
    "displayName": "Lovable (러버블)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "러버블"
    ],
    "source": "https://lovable.dev/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-053-feature-1",
          "title": "앱·프로토타입 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://lovable.dev/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://lovable.dev/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-054",
    "name": "Bolt",
    "displayName": "Bolt (볼트)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "볼트",
      "bolt.new"
    ],
    "source": "https://bolt.new/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-054-feature-1",
          "title": "웹·앱 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://bolt.new/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://bolt.new/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-055",
    "name": "Windsurf",
    "displayName": "Windsurf (윈드서프)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "윈드서프"
    ],
    "source": "https://windsurf.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-055-feature-1",
          "title": "코딩 에이전트 관리",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://windsurf.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://windsurf.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-080",
    "name": "Z.ai GLM Coding Plan",
    "displayName": "Z.ai GLM Coding Plan (지에이아이,GLM)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "지에이아이",
      "GLM"
    ],
    "source": "https://z.ai/subscribe",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-080-feature-1",
          "title": "GLM 기반 AI 코딩",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://z.ai/subscribe",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://z.ai/subscribe",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-084",
    "name": "v0",
    "displayName": "v0 (브이제로)",
    "category": "AI 개발·앱 제작",
    "aliases": [
      "브이제로"
    ],
    "source": "https://v0.app/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-084-feature-1",
          "title": "AI 웹 앱 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://v0.app/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://v0.app/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-056",
    "name": "Notion",
    "displayName": "Notion (노션)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "노션",
      "Notion AI"
    ],
    "source": "https://www.notion.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-056-feature-1",
          "title": "문서·자료 관리",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.notion.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-056-feature-2",
          "title": "AI 검색·작업 자동화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.notion.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.notion.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-057",
    "name": "Gamma",
    "displayName": "Gamma (감마)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "감마"
    ],
    "source": "https://gamma.app/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-057-feature-1",
          "title": "AI 발표 자료·문서 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://gamma.app/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://gamma.app/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-058",
    "name": "Grammarly",
    "displayName": "Grammarly (그래머리)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "그래머리",
      "Superhuman"
    ],
    "source": "https://www.grammarly.com/plans",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-058-feature-1",
          "title": "문법 교정·글쓰기 지원",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.grammarly.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.grammarly.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-059",
    "name": "DeepL",
    "displayName": "DeepL (딥엘)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "딥엘"
    ],
    "source": "https://www.deepl.com/en/pro",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-059-feature-1",
          "title": "텍스트 번역",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.deepl.com/en/pro",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.deepl.com/en/pro",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-081",
    "name": "Napkin AI",
    "displayName": "Napkin AI (냅킨)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "냅킨"
    ],
    "source": "https://www.napkin.ai/pricing/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-081-feature-1",
          "title": "시각 자료 제작",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.napkin.ai/pricing/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.napkin.ai/pricing/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-082",
    "name": "Beautiful.ai",
    "displayName": "Beautiful.ai (뷰티풀에이아이)",
    "category": "AI 문서·글쓰기·번역",
    "aliases": [
      "뷰티풀에이아이"
    ],
    "source": "https://www.beautiful.ai/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-082-feature-1",
          "title": "AI 발표 자료 제작",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.beautiful.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-082-feature-2",
          "title": "슬라이드 자동 정렬",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.beautiful.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.beautiful.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-060",
    "name": "Otter.ai",
    "displayName": "Otter.ai (오터)",
    "category": "AI 회의·녹음·기록",
    "aliases": [
      "오터"
    ],
    "source": "https://otter.ai/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-060-feature-1",
          "title": "회의 음성 전사",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://otter.ai/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-060-feature-2",
          "title": "회의 내용 검색",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://otter.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://otter.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-061",
    "name": "Fireflies.ai",
    "displayName": "Fireflies.ai (파이어플라이즈)",
    "category": "AI 회의·녹음·기록",
    "aliases": [
      "파이어플라이즈"
    ],
    "source": "https://fireflies.ai/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-061-feature-1",
          "title": "회의 기록·정리",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://fireflies.ai/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://fireflies.ai/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-088",
    "name": "PLAUD",
    "displayName": "PLAUD (플라우드)",
    "category": "AI 회의·녹음·기록",
    "aliases": [
      "플라우드"
    ],
    "source": "https://www.plaud.ai/",
    "note": "녹음 기기 구매비를 제외하고 멤버십 이용료만 입력해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-088-feature-1",
          "title": "대면·통화·회의 기록",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.plaud.ai/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.plaud.ai/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-089",
    "name": "클로바노트",
    "displayName": "클로바노트 (CLOVA Note)",
    "category": "AI 회의·녹음·기록",
    "aliases": [
      "CLOVA Note"
    ],
    "source": "https://clovanote.naver.com/",
    "note": "별도로 정기 결제하는 이용권이 있을 때 등록해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-089-feature-1",
          "title": "음성 기록",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://clovanote.naver.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://clovanote.naver.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-090",
    "name": "n8n Cloud",
    "displayName": "n8n Cloud (엔에잇엔)",
    "category": "자동화·AI 워크플로",
    "aliases": [
      "엔에잇엔"
    ],
    "source": "https://n8n.io/pricing/",
    "note": "자가 호스팅 비용과 Cloud 구독료를 구분해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-090-feature-1",
          "title": "워크플로 자동화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://n8n.io/pricing/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://n8n.io/pricing/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-091",
    "name": "Make",
    "displayName": "Make (메이크)",
    "category": "자동화·AI 워크플로",
    "aliases": [
      "메이크"
    ],
    "source": "https://www.make.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-091-feature-1",
          "title": "업무 자동화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.make.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.make.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-092",
    "name": "Zapier",
    "displayName": "Zapier (재피어)",
    "category": "자동화·AI 워크플로",
    "aliases": [
      "재피어"
    ],
    "source": "https://zapier.com/pricing",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-092-feature-1",
          "title": "앱 연결·업무 자동화",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://zapier.com/pricing",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://zapier.com/pricing",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-064",
    "name": "iCloud+",
    "displayName": "iCloud+ (아이클라우드)",
    "category": "저장공간·오피스",
    "aliases": [
      "아이클라우드"
    ],
    "source": "https://www.apple.com/kr/icloud/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-064-feature-1",
          "title": "클라우드 저장 공간",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/icloud/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-064-feature-2",
          "title": "개인정보 보호 기능",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.apple.com/kr/icloud/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.apple.com/kr/icloud/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-065",
    "name": "Google One",
    "displayName": "Google One (구글 원)",
    "category": "저장공간·오피스",
    "aliases": [
      "구글 원"
    ],
    "source": "https://one.google.com/about/plans",
    "note": "Google AI 요금제로 이미 결제 중이라면 별도 결제 여부를 확인해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-065-feature-1",
          "title": "클라우드 저장 공간",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://one.google.com/about/plans",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://one.google.com/about/plans",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-066",
    "name": "Microsoft 365",
    "displayName": "Microsoft 365 (마이크로소프트365)",
    "category": "저장공간·오피스",
    "aliases": [
      "마이크로소프트365",
      "OneDrive"
    ],
    "source": "https://www.microsoft.com/ko-kr/microsoft-365/buy/compare-all-microsoft-365-products",
    "note": "OneDrive와 Copilot 등 포함 혜택을 확인해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-066-feature-0",
          "title": "Office 앱",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.microsoft.com/ko-kr/microsoft-365",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-066-feature-1",
          "title": "클라우드 저장 공간",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.microsoft.com/ko-kr/microsoft-365",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-066-feature-2",
          "title": "Copilot AI 지원",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.microsoft.com/ko-kr/microsoft-365",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.microsoft.com/ko-kr/microsoft-365",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-067",
    "name": "Dropbox",
    "displayName": "Dropbox (드롭박스)",
    "category": "저장공간·오피스",
    "aliases": [
      "드롭박스"
    ],
    "source": "https://www.dropbox.com/plans",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-067-feature-1",
          "title": "파일 저장·공유",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.dropbox.com/plans",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-067-feature-2",
          "title": "팀 협업",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.dropbox.com/plans",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.dropbox.com/plans",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-068",
    "name": "Apple One",
    "displayName": "Apple One (애플원)",
    "category": "저장공간·오피스",
    "aliases": [
      "애플원"
    ],
    "source": "https://www.apple.com/kr/apple-one/",
    "note": "Apple Music, Apple TV, iCloud+ 등 포함 혜택을 개별 구독과 중복 계산하지 않도록 확인해 주세요.",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-068-feature-1",
          "title": "Apple Music",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-one/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-068-feature-2",
          "title": "Apple TV",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-one/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-068-feature-3",
          "title": "Apple Arcade",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-one/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-068-feature-4",
          "title": "iCloud+",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.apple.com/kr/apple-one/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.apple.com/kr/apple-one/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-069",
    "name": "밀리의 서재",
    "displayName": "밀리의 서재 (Millie)",
    "category": "독서·오디오북",
    "aliases": [
      "Millie"
    ],
    "source": "https://www.millie.co.kr/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-069-feature-1",
          "title": "전자책·오디오북",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.millie.co.kr/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-069-feature-2",
          "title": "웹툰·웹소설",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.millie.co.kr/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.millie.co.kr/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-070",
    "name": "리디셀렉트",
    "displayName": "리디셀렉트 (RIDI Select)",
    "category": "독서·오디오북",
    "aliases": [
      "RIDI Select"
    ],
    "source": "https://ridibooks.com/selection",
    "note": "",
    "plans": [],
    "membership": null
  },
  {
    "id": "service-074",
    "name": "윌라",
    "displayName": "윌라 (Welaaa)",
    "category": "독서·오디오북",
    "aliases": [
      "Welaaa"
    ],
    "source": "https://www.welaaa.com/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-074-feature-1",
          "title": "오디오북·전자책",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.welaaa.com/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-074-feature-2",
          "title": "오디오 웹소설·클래스",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.welaaa.com/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.welaaa.com/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-075",
    "name": "크레마클럽",
    "displayName": "크레마클럽 (예스24,YES24 북클럽)",
    "category": "독서·오디오북",
    "aliases": [
      "예스24",
      "YES24 북클럽"
    ],
    "source": "https://cremaclub.yes24.com/BookClub/guide",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-075-feature-1",
          "title": "전자책 독서",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://cremaclub.yes24.com/BookClub/guide",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://cremaclub.yes24.com/BookClub/guide",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-076",
    "name": "교보문고 sam",
    "displayName": "교보문고 sam (샘)",
    "category": "독서·오디오북",
    "aliases": [
      "샘"
    ],
    "source": "https://ebook.kyobobook.co.kr/dig/sam/pssbuy",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-076-feature-1",
          "title": "전자책 구독",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://ebook.kyobobook.co.kr/dig/sam/pssbuy",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://ebook.kyobobook.co.kr/dig/sam/pssbuy",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-071",
    "name": "Apple Arcade",
    "displayName": "Apple Arcade (애플아케이드)",
    "category": "게임",
    "aliases": [
      "애플아케이드"
    ],
    "source": "https://www.apple.com/kr/apple-arcade/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-071-feature-1",
          "title": "광고·추가 결제 없는 게임",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.apple.com/kr/apple-arcade/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-071-feature-2",
          "title": "가족 공유",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.apple.com/kr/apple-arcade/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.apple.com/kr/apple-arcade/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-072",
    "name": "PlayStation Plus",
    "displayName": "PlayStation Plus (PS Plus)",
    "category": "게임",
    "aliases": [
      "PS Plus",
      "플스플러스"
    ],
    "source": "https://www.playstation.com/ko-kr/ps-plus/",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-072-feature-1",
          "title": "온라인 멀티플레이",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.playstation.com/ko-kr/ps-plus/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-072-feature-2",
          "title": "게임 카탈로그·할인",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.playstation.com/ko-kr/ps-plus/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.playstation.com/ko-kr/ps-plus/",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-073",
    "name": "Xbox Game Pass",
    "displayName": "Xbox Game Pass (엑스박스 게임패스)",
    "category": "게임",
    "aliases": [
      "엑스박스 게임패스"
    ],
    "source": "https://www.xbox.com/ko-KR/xbox-game-pass",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-073-feature-1",
          "title": "PC·콘솔 게임 카탈로그",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.xbox.com/ko-KR/xbox-game-pass",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.xbox.com/ko-KR/xbox-game-pass",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-095",
    "name": "Nintendo Switch Online",
    "displayName": "Nintendo Switch Online (닌텐도 스위치 온라인)",
    "category": "게임",
    "aliases": [
      "닌텐도 스위치 온라인"
    ],
    "source": "https://www.nintendo.co.kr/support/switch/nintendo_switch_online/services/index.html",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-095-feature-0",
          "title": "온라인 플레이",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://support.nintendo.com/kr/switch/nintendo_switch_online/services/index.html",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-095-feature-1",
          "title": "저장 데이터 백업",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://support.nintendo.com/kr/switch/nintendo_switch_online/services/index.html",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-095-feature-2",
          "title": "클래식 게임",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://support.nintendo.com/kr/switch/nintendo_switch_online/services/index.html",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://support.nintendo.com/kr/switch/nintendo_switch_online/services/index.html",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-093",
    "name": "Speak",
    "displayName": "Speak (스픽)",
    "category": "학습·언어",
    "aliases": [
      "스픽"
    ],
    "source": "https://www.speak.com/ko",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-093-feature-1",
          "title": "AI 영어 회화",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://www.speak.com/ko",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-093-feature-2",
          "title": "맞춤 수업·프리토킹",
          "category": "other",
          "conditions": "플랜·지역에 따라 제공 범위가 달라요.",
          "sourceURL": "https://www.speak.com/ko",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://www.speak.com/ko",
        "directions": "공식 혜택·플랜 확인",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-094",
    "name": "Duolingo",
    "displayName": "Duolingo (듀오링고)",
    "category": "학습·언어",
    "aliases": [
      "듀오링고"
    ],
    "source": "https://www.duolingo.com/super",
    "note": "",
    "plans": [],
    "membership": {
      "benefits": [
        {
          "id": "service-094-feature-0",
          "title": "광고 없는 학습",
          "category": "other",
          "conditions": "",
          "sourceURL": "https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/",
          "checkedAt": "2026-10-26"
        },
        {
          "id": "service-094-feature-1",
          "title": "맞춤 복습",
          "category": "other",
          "conditions": "플랜·기기에 따라 제공 범위가 달라요.",
          "sourceURL": "https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/",
          "checkedAt": "2026-10-26"
        }
      ],
      "benefitsPage": {
        "url": "https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/",
        "directions": "공식 혜택 안내",
        "checkedAt": "2026-10-26"
      }
    }
  },
  {
    "id": "service-096",
    "name": "쿠팡 와우 멤버십",
    "displayName": "쿠팡 와우 멤버십",
    "category": "쇼핑·생활",
    "aliases": [
      "쿠팡와우",
      "로켓와우",
      "Coupang WOW"
    ],
    "source": "https://news.coupang.com/archives/64216/",
    "note": "",
    "plans": [
      {
        "name": "와우 월간",
        "amount": 7890,
        "channel": "웹·쿠팡 앱",
        "currency": "KRW",
        "yearly": false,
        "sourceURL": "https://news.coupang.com/archives/44584/",
        "checkedAt": "2026-10-25",
        "conditions": "공식 요금 공지 및 2026.10.25 로그인 후 공식 멤버십 관리·해지 전 안내에서 7,890원을 대조 확인했어요. 무료체험·할인·개별 계약에 따른 실제 청구액은 본인 계정에서 확인해 주세요."
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "wow-rocket",
          "title": "로켓배송 상품 무료배송",
          "category": "delivery",
          "conditions": "대상 로켓배송 상품",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "wow-fresh",
          "title": "로켓프레시 배송",
          "category": "delivery",
          "conditions": "최소 주문금액·지역 조건 적용",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "wow-play",
          "title": "쿠팡플레이 특별 혜택",
          "category": "video",
          "conditions": "일부 콘텐츠·패스 별도 요금",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "wow-deals",
          "title": "와우회원 전용 특가",
          "category": "shopping",
          "conditions": "대상 상품·기간 한정",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "wow-eats",
          "title": "쿠팡이츠 무료배달",
          "category": "delivery",
          "conditions": "대상 매장·지역 한정",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "wow-returns",
          "title": "로켓배송 상품 무료반품",
          "category": "other",
          "conditions": "30일 내 미사용 상품·일부 제외",
          "sourceURL": "https://news.coupang.com/archives/64216/",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        }
      ],
      "benefitsPage": {
        "url": "https://news.coupang.com/archives/64216/",
        "directions": "",
        "checkedAt": "2026-10-25"
      },
      "managementPage": {
        "url": "https://loyalty.coupang.com/loyalty/management/home",
        "directions": "가입한 쿠팡 계정으로 로그인하면 와우 멤버십 관리가 열려요. 다음 결제일과 결제수단 관리 항목을 확인하세요.",
        "checkedAt": "2026-10-25"
      },
      "cancellationPage": {
        "url": "https://news.coupang.com/archives/64216/",
        "directions": "로그인 → 와우 멤버십 관리 → 해지하기 → 혜택·환불·종료 시점 검토. 최종 “해지 신청 완료하기”는 실제 해지 동작이에요. 앱의 기록 변경과 구분해 직접 결정해 주세요.",
        "checkedAt": "2026-10-25"
      }
    }
  },
  {
    "id": "service-097",
    "name": "네이버플러스 멤버십",
    "displayName": "네이버플러스 멤버십",
    "category": "쇼핑·생활",
    "aliases": [
      "네이버 플러스",
      "Naver Plus",
      "네이버멤버십"
    ],
    "source": "https://nid.naver.com/membership/join",
    "note": "",
    "plans": [
      {
        "name": "월간 이용권",
        "amount": 4900,
        "channel": "웹",
        "currency": "KRW",
        "yearly": false,
        "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
        "checkedAt": "2026-10-25",
        "conditions": "VAT 포함. 할인·무료 이용권·제휴 조건에 따라 실제 금액이 다를 수 있어요."
      },
      {
        "name": "연간 이용권",
        "amount": 46800,
        "channel": "웹",
        "currency": "KRW",
        "yearly": true,
        "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
        "checkedAt": "2026-10-25",
        "conditions": "연 46,800원 전체 청구액. 월 환산액과 구분해요. VAT 포함."
      }
    ],
    "membership": {
      "benefits": [
        {
          "id": "naver-points",
          "title": "네이버 쇼핑·예약·여행 적립",
          "category": "points",
          "conditions": "대상 상품·적립 한도 적용",
          "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "naver-delivery",
          "title": "N배송 무료배송·반품",
          "category": "delivery",
          "conditions": "대상 주문·최소 금액 조건 적용",
          "sourceURL": "https://nid.naver.com/membership/join",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        },
        {
          "id": "naver-netflix",
          "title": "넷플릭스 광고형 스탠다드 선택",
          "category": "video",
          "conditions": "월 1개 선택·계정 연결 필요",
          "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
          "checkedAt": "2026-10-25",
          "selectionGroup": "naver-digital-one"
        },
        {
          "id": "naver-spotify",
          "title": "스포티파이 프리미엄 베이직 선택",
          "category": "music",
          "conditions": "월 1개 선택·계정 연결 필요",
          "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
          "checkedAt": "2026-10-25",
          "selectionGroup": "naver-digital-one"
        },
        {
          "id": "naver-gamepass",
          "title": "PC Game Pass 선택",
          "category": "other",
          "conditions": "월 1개 선택·이용 조건 적용",
          "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
          "checkedAt": "2026-10-25",
          "selectionGroup": "naver-digital-one"
        },
        {
          "id": "naver-mybox",
          "title": "MYBOX 저장 공간",
          "category": "other",
          "conditions": "80GB·대표 회원 등 조건 적용",
          "sourceURL": "https://help.naver.com/service/23168/contents/11764?lang=ko&osType=COMMONOS",
          "checkedAt": "2026-10-25",
          "selectionGroup": null
        }
      ],
      "benefitsPage": {
        "url": "https://nid.naver.com/membership/join",
        "directions": "",
        "checkedAt": "2026-10-25"
      },
      "managementPage": {
        "url": "https://nid.naver.com/membership/my",
        "directions": "가입한 네이버 계정으로 로그인 → MY 멤버십. 설정에서 결제·멤버십 관리 항목을 확인하세요.",
        "checkedAt": "2026-10-25"
      },
      "cancellationPage": {
        "url": "https://help.naver.com/service/23168/bookmark/20281",
        "directions": "공식 고객센터의 “네이버플러스 멤버십 해지 및 환불 요청” 안내를 확인하세요. 로그인·이용 혜택에 따라 해지·환불 조건이 달라요.",
        "checkedAt": "2026-10-25"
      }
    }
  }
]
"""#
        return try! JSONDecoder().decode([CatalogService].self, from: Data(json.utf8))
    }()
    static var categories: [String] { all.reduce(into: []) { if !$0.contains($1.category) { $0.append($1.category) } } }
}

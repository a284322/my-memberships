import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'Research/subscription-services-v3.json').read_text())
# Only previously verified representative monthly prices; all other services remain available for custom plans.
plans={
'YouTube Premium': [('Premium',14900,'웹·Android'),('Premium',19500,'App Store'),('Premium Lite',8500,'웹·Android'),('Premium Lite',10900,'App Store')],
'YouTube Music':[('Music Premium',11990,'웹·Android')],
'Netflix':[('광고형 스탠다드',7000,'공식 요금'),('스탠다드',13500,'공식 요금'),('프리미엄',17000,'공식 요금')],
'ChatGPT':[('Go',13000,'App Store'),('Plus',29000,'App Store')],
'Gemini':[('Google AI Plus',7500,'App Store'),('Google AI Pro',29000,'App Store')]
}
user_notes = {
 'YouTube Premium': '음악 혜택이 포함된 플랜이라면 YouTube Music을 별도 결제하는지 확인해 주세요.',
 'YouTube Music': 'YouTube Premium에 포함된 혜택이라면 중복 등록하지 않아도 돼요.',
 'Apple One': 'Apple Music, Apple TV, iCloud+ 등 포함 혜택을 개별 구독과 중복 계산하지 않도록 확인해 주세요.',
 'Gemini': 'Google One 저장 공간이 포함된 플랜인지 확인해 주세요.',
 'Google One': 'Google AI 요금제로 이미 결제 중이라면 별도 결제 여부를 확인해 주세요.',
 'Claude': 'Claude Code 이용료가 현재 요금제에 포함되는지 확인해 주세요.',
 'Microsoft 365': 'OneDrive와 Copilot 등 포함 혜택을 확인해 주세요.',
 'Microsoft Copilot': 'Microsoft 365 구독에 포함된 혜택인지 확인해 주세요.',
 '쿠팡플레이': '와우 멤버십과 별도 패스를 구분해 실제 결제 금액을 입력해 주세요.',
 'PLAUD': '녹음 기기 구매비를 제외하고 멤버십 이용료만 입력해 주세요.',
 'n8n Cloud': '자가 호스팅 비용과 Cloud 구독료를 구분해 주세요.',
 '클로바노트': '별도로 정기 결제하는 이용권이 있을 때 등록해 주세요.',
}
rows=[]
for s in data['services']:
 rows.append(dict(id=s['id'],name=s['name'],displayName=s['displayName'],category=s['category'],aliases=s['aliases'],source=s['officialURL'],note=user_notes.get(s['name'], ''),plans=s.get('plans', [dict(name=n,amount=a,channel=c,currency='KRW',yearly=False) for n,a,c in plans.get(s['name'],[])]),membership=s.get('membership')))
source='''import Foundation

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
'''+json.dumps(rows,ensure_ascii=False,indent=2)+'''
"""#
        return try! JSONDecoder().decode([CatalogService].self, from: Data(json.utf8))
    }()
    static var categories: [String] { all.reduce(into: []) { if !$0.contains($1.category) { $0.append($1.category) } } }
}
'''
(root/'Catalog.swift').write_text(source)

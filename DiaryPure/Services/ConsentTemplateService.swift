import Foundation

struct ConsentTemplateService {

    static func deviceLanguage() -> AgreementLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code.hasPrefix("zh") ? .zh : .en
    }

    static func render(
        creatorName: String,
        partnerName: String,
        date: Date,
        language: AgreementLanguage
    ) -> String {
        let formatted = date.formatted(date: .long, time: .omitted)
        switch language {
        case .en:
            return enTemplate(creator: creatorName, partner: partnerName, date: formatted)
        case .zh:
            return zhTemplate(creator: creatorName, partner: partnerName, date: formatted)
        }
    }

    // MARK: - English Template

    private static func enTemplate(creator: String, partner: String, date: String) -> String {
        """
        MUTUAL CONSENT AGREEMENT

        Date: \(date)
        Party A (Creator): \(creator)
        Party B (Partner): \(partner)

        Both parties voluntarily enter into this agreement and acknowledge the following terms:

        1. Voluntary Consent
        Both \(creator) and \(partner) confirm that participation in this session is entirely voluntary. Either party may withdraw consent at any time without consequence.

        2. Scope of Agreement
        This agreement covers the activities discussed and agreed upon by both parties prior to the session. Any activity outside the agreed scope requires separate, explicit consent.

        3. Right to Withdraw
        Either party has the unconditional right to pause or stop the session at any time. The word "stop" or any pre-agreed safe word shall immediately halt all activity.

        4. Boundaries
        Both parties have discussed and understand each other's boundaries. Neither party shall pressure the other to exceed stated boundaries.

        5. Sobriety
        Both parties confirm they are of sound mind and not under the influence of substances that would impair their ability to give informed consent.

        6. Privacy
        Both parties agree to maintain the privacy of this session. Personal details and the content of this agreement shall not be shared with third parties without mutual written consent.

        7. No Recording
        No audio, video, or photographic recording of the session shall be made without the explicit prior consent of both parties.

        8. Acknowledgment
        By signing below, both \(creator) and \(partner) acknowledge that they have read, understood, and agree to all terms of this agreement.
        """
    }

    // MARK: - Chinese Template

    private static func zhTemplate(creator: String, partner: String, date: String) -> String {
        """
        双方同意协议

        日期：\(date)
        甲方（创建者）：\(creator)
        乙方（伙伴）：\(partner)

        双方自愿签订本协议，并确认以下条款：

        1. 自愿同意
        \(creator) 和 \(partner) 确认参与本次活动完全出于自愿。任何一方均可随时撤回同意，且不承担任何后果。

        2. 协议范围
        本协议涵盖双方在活动前讨论并同意的内容。超出约定范围的任何活动需另行获得明确同意。

        3. 撤回权利
        任何一方均有无条件权利随时暂停或终止活动。"停止"一词或任何预先约定的安全词应立即中止所有活动。

        4. 边界
        双方已讨论并理解彼此的边界。任何一方不得施压另一方超越已声明的边界。

        5. 清醒状态
        双方确认处于清醒状态，未受任何影响判断能力的物质影响。

        6. 隐私保护
        双方同意对本次活动保密。未经双方书面同意，不得向第三方透露个人信息及本协议内容。

        7. 禁止录制
        未经双方明确事先同意，不得对活动进行任何音频、视频或摄影录制。

        8. 确认声明
        \(creator) 和 \(partner) 在下方签名，确认已阅读、理解并同意本协议的所有条款。
        """
    }
}

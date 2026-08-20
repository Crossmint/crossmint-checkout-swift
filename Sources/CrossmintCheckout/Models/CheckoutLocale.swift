//
//  CheckoutLocale.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// A locale that Crossmint's hosted pages accept.
///
/// The set is closed. The hosted page rejects a value outside this list.
public enum CheckoutLocale: String, Sendable, CaseIterable {
    case enUS = "en-US"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case itIT = "it-IT"
    case koKR = "ko-KR"
    case ptPT = "pt-PT"
    case jaJP = "ja-JP"
    case zhCN = "zh-CN"
    case zhTW = "zh-TW"
    case deDE = "de-DE"
    case ruRU = "ru-RU"
    case trTR = "tr-TR"
    case ukUA = "uk-UA"
    case thTH = "th-TH"
    case viVN = "vi-VN"
}

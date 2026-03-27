//
//  SummaryProfile.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct SummaryProfile: Decodable {
    let address1: String?
    let address2: String?
    let city: String?
    let zip: String?
    let country: String?
    let phone: String?
    let website: String?
    let industry: String?
    let industryKey: String?
    let industryDisp: String?
    let sector: String?
    let longBusinessSummary: String?
    let name: String?
    let description: String?
}

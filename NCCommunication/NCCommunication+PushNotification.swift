//
//  NCCommunication+PushNotification.swift
//  NCCommunication
//
//  Created by Marino Faggiana on 22/05/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import Alamofire
import SwiftyJSON

extension NCCommunication {

    @objc public func subscribingPushNotification(serverUrl: String, account: String, user: String, password: String, deviceIdentifier: String, devicePublicKey: String, appType: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ signature: String?, _ publicKey: String?, _ errorCode: Int, _ errorDescription: String) -> Void) {
        
        let endpoint = "ocs/v2.php/apps/notifications/api/v2/push?format=json"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            queue.async { completionHandler(account, nil, nil, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        
        let parameters = [
            "deviceIdentifier": deviceIdentifier,
            "devicePublicKey": devicePublicKey,
            "appType": appType,
        ]
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(user: user, password: password, appendHeaders: addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters:parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseJSON(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, nil, nil, error.errorCode, error.description ?? "") }
            case .success(let json):
                let json = JSON(json)
                let statusCode = json["ocs"]["meta"]["statuscode"].int ?? NCCommunicationError().getInternalError()
                if 200..<300 ~= statusCode  {
                    let signature = json["ocs"]["data"]["signature"].stringValue
                    let publicKey = json["ocs"]["data"]["publicKey"].stringValue
                    queue.async { completionHandler(account, signature, publicKey, 0, "") }
                } else {
                    let errorDescription = json["ocs"]["meta"]["errorDescription"].string ?? NSLocalizedString("_invalid_data_format_", value: "Invalid data format", comment: "")
                    queue.async { completionHandler(account, nil, nil, statusCode, errorDescription) }
                }
            }
        }
    }
    
    @objc public func unsubscribingPushNotification(serverUrl: String, account: String, user: String, password: String, customUserAgent: String? = nil, addCustomHeaders: [String: String]? = nil, queue: DispatchQueue = .main, completionHandler: @escaping (_ account: String, _ errorCode: Int, _ errorDescription: String) -> Void) {
                            
        let endpoint = "ocs/v2.php/apps/notifications/api/v2/push"
        
        guard let url = NCCommunicationCommon.shared.createStandardUrl(serverUrl: serverUrl, endpoint: endpoint) else {
            queue.async { completionHandler(account, NSURLErrorBadURL, NSLocalizedString("_invalid_url_", value: "Invalid server url", comment: "")) }
            return
        }
        
        let method = HTTPMethod(rawValue: "DELETE")
        
        let headers = NCCommunicationCommon.shared.getStandardHeaders(user: user, password: password, appendHeaders: addCustomHeaders, customUserAgent: customUserAgent)
        
        sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NCCommunicationCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NCCommunicationError().getError(error: error, httResponse: response.response)
                queue.async { completionHandler(account, error.errorCode, error.description ?? "") }
            case .success( _):
                queue.async { completionHandler(account, 0, "") }
            }
        }
    }    
}

